from fastapi import FastAPI, File, UploadFile, Form, HTTPException, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from typing import Optional, List
from ocr import process_image, extract_text_from_image
from parser import parse_nutrition, get_health_score
from database import (
    create_user, get_user_by_email, get_user_by_id,
    save_health_profile, get_health_profile,
    save_scan, get_user_scans, get_daily_totals,
    get_all_scans, get_alternatives_from_db, seed_products
)
from auth import hash_password, verify_password, create_access_token, decode_access_token
from products import identify_category
import json

app = FastAPI(title="Nutrition Scanner API")

# Seed database on startup
seed_products()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Logging middleware for mobile requests
@app.middleware("http")
async def log_requests(request: Request, call_next):
    client_ip = request.client.host
    user_agent = request.headers.get("user-agent", "")
    print(f"Request from {client_ip} (User-Agent: {user_agent}): {request.method} {request.url}")
    response = await call_next(request)
    return response

# Security
security = HTTPBearer(auto_error=False)


# ─── Request Models ──────────────────────────────────────
class SignUpRequest(BaseModel):
    email: str
    password: str


class LoginRequest(BaseModel):
    email: str
    password: str


class HealthProfileRequest(BaseModel):
    age: int
    gender: str
    weight_kg: float
    height_cm: float
    dietary_goal: str
    health_conditions: List[str]


# ─── Auth Helper ─────────────────────────────────────────
def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    """Gets current logged in user from JWT token"""
    if not credentials:
        return None
    token = credentials.credentials
    payload = decode_access_token(token)
    if not payload:
        return None
    user_id = payload.get("user_id")
    if not user_id:
        return None
    return get_user_by_id(user_id)


def require_auth(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    """Requires authentication — raises error if not logged in"""
    user = get_current_user(credentials)
    if not user:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return user


# ─── Basic Routes ────────────────────────────────────────
@app.get("/")
def root():
    return {"message": "Nutrition Scanner API is running"}

@app.get("/server-info")
def get_server_info(request: Request):
    """Returns server information for mobile app configuration"""
    import socket
    try:
        # Get local IP address
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
    except:
        local_ip = "127.0.0.1"
    
    return {
        "server_ip": local_ip,
        "server_port": 8000,  # Default port
        "client_ip": request.client.host
    }


# ─── Auth Routes ─────────────────────────────────────────
@app.post("/auth/signup")
def signup(request: SignUpRequest):
    """Creates a new user account"""
    # Check if email already exists
    existing = get_user_by_email(request.email)
    if existing:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )

    # Hash password and create user
    password_hash = hash_password(request.password)
    user = create_user(request.email, password_hash)

    # Create token
    token = create_access_token({"user_id": user.id})

    return {
        "success": True,
        "message": "Account created successfully",
        "token": token,
        "user_id": user.id,
        "email": user.email,
        "has_health_profile": False
    }


@app.post("/auth/login")
def login(request: LoginRequest):
    """Logs in a user"""
    user = get_user_by_email(request.email)
    if not user:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    if not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    # Create token
    token = create_access_token({"user_id": user.id})

    # Check if health profile exists
    profile = get_health_profile(user.id)

    return {
        "success": True,
        "message": "Logged in successfully",
        "token": token,
        "user_id": user.id,
        "email": user.email,
        "has_health_profile": profile is not None
    }


@app.get("/auth/me")
def get_me(user=Depends(require_auth)):
    """Gets current user info"""
    profile = get_health_profile(user.id)
    return {
        "user_id": user.id,
        "email": user.email,
        "has_health_profile": profile is not None,
        "health_profile": profile
    }


# ─── Health Profile Routes ───────────────────────────────
@app.post("/health-profile")
def create_health_profile(
    request: HealthProfileRequest,
    user=Depends(require_auth)
):
    """Saves user health profile"""
    profile = save_health_profile(
        user_id=user.id,
        age=request.age,
        gender=request.gender,
        weight_kg=request.weight_kg,
        height_cm=request.height_cm,
        dietary_goal=request.dietary_goal,
        health_conditions=request.health_conditions
    )
    return {
        "success": True,
        "message": "Health profile saved"
    }


@app.get("/health-profile")
def get_my_health_profile(user=Depends(require_auth)):
    """Gets user health profile"""
    profile = get_health_profile(user.id)
    if not profile:
        raise HTTPException(
            status_code=404,
            detail="Health profile not found"
        )
    return profile


# ─── Scan Routes ─────────────────────────────────────────
@app.post("/scan")
async def scan_label(
    image: UploadFile = File(...),
    conditions: str = Form(default="[]"),
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    """Scans a nutrition label"""
    try:
        # Get current user if logged in
        current_user = get_current_user(credentials)
        user_id = current_user.id if current_user else None

        # Get health conditions — from request or user profile
        health_conditions = json.loads(conditions)
        if not health_conditions and current_user:
            profile = get_health_profile(current_user.id)
            if profile:
                health_conditions = profile.get('health_conditions', [])

        # Step 1: Read the image
        contents = await image.read()

        # Step 2: Process image with YOLO
        processed = process_image(contents)
        if not processed["success"]:
            return {"error": processed["error"]}

        # Step 3: Extract text with GPT-4 Vision
        extracted = extract_text_from_image(
            processed["image"],
            health_conditions
        )
        if not extracted["success"]:
            return {"error": extracted["error"]}

        # Step 4: Parse nutrition data
        parsed = parse_nutrition(extracted["nutrition"])
        if not parsed["success"]:
            return {"error": parsed["error"]}

        # Step 5: Calculate health score
        raw_nutrition = {
            'calories': parsed["data"].get('calories'),
            'total_fat': parsed["data"].get('total_fat'),
            'saturated_fat': parsed["data"].get('saturated_fat'),
            'trans_fat': parsed["data"].get('trans_fat'),
            'cholesterol': parsed["data"].get('cholesterol'),
            'sodium': parsed["data"].get('sodium'),
            'carbohydrates': parsed["data"].get('carbohydrates'),
            'fiber': parsed["data"].get('fiber'),
            'sugar': parsed["data"].get('sugar'),
            'protein': parsed["data"].get('protein'),
        }
        health_score = get_health_score(raw_nutrition)

        # Step 6: Get real Jamaican alternatives from database
        category = extracted.get("product_category", "sugary_drinks")
        alternatives = get_alternatives_from_db(category, health_conditions)

        # Step 7: Save to database
        scan_id = save_scan(
            nutrition_data=parsed["data"],
            health_score=health_score,
            raw_text=extracted["text"],
            warnings=extracted.get("warnings", []),
            product_name=extracted.get("product_name", "Unknown"),
            user_id=user_id
        )

        # Step 8: Return everything to Flutter
        return {
            "success": True,
            "scan_id": scan_id,
            "product_name": extracted.get("product_name", "Unknown"),
            "nutrition": parsed["data"],
            "health_score": health_score,
            "warnings": extracted.get("warnings", []),
            "alternatives": alternatives,
            "raw_text": extracted["text"],
            "debug_raw": extracted["text"]
        }

    except Exception as e:
        return {"error": str(e)}


@app.get("/history")
def get_history(user=Depends(require_auth)):
    """Gets scan history for logged in user"""
    scans = get_user_scans(user.id)
    return {"scans": scans}


@app.get("/daily-totals")
def get_my_daily_totals(user=Depends(require_auth)):
    """Gets today's total nutrient intake for logged in user"""
    totals = get_daily_totals(user.id)

    # Add daily value percentages
    daily_values = {
        'calories': 2000,
        'sugar': 50,
        'sodium': 2300,
        'total_fat': 78,
        'saturated_fat': 20,
        'carbohydrates': 275,
        'protein': 50,
        'fiber': 28,
    }

    percentages = {}
    for nutrient, dv in daily_values.items():
        value = totals.get(nutrient, 0)
        percentages[f'{nutrient}_percent'] = round((value / dv) * 100)

    return {**totals, **percentages}
