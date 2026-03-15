from sqlalchemy import (
    create_engine, Column, Integer, String,
    DateTime, Float, ForeignKey, Date
)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from dotenv import load_dotenv
from datetime import datetime, date
import os

load_dotenv()

# ─── Database Connection ─────────────────────────────────
DATABASE_URL = os.getenv('DATABASE_URL')
if DATABASE_URL and DATABASE_URL.startswith('postgres://'):
    DATABASE_URL = DATABASE_URL.replace('postgres://', 'postgresql://', 1)

engine = create_engine(DATABASE_URL)
Base = declarative_base()
SessionLocal = sessionmaker(bind=engine)


# ─── User Model ──────────────────────────────────────────
class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    health_profile = relationship(
        "HealthProfile", back_populates="user", uselist=False
    )
    scans = relationship("NutritionScan", back_populates="user")


# ─── Health Profile Model ────────────────────────────────
class HealthProfile(Base):
    __tablename__ = 'health_profiles'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), unique=True)
    age = Column(Integer, nullable=True)
    gender = Column(String, nullable=True)
    weight_kg = Column(Float, nullable=True)
    height_cm = Column(Float, nullable=True)
    dietary_goal = Column(String, nullable=True)
    health_conditions = Column(String, nullable=True)  # comma separated
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)

    # Relationship
    user = relationship("User", back_populates="health_profile")


# ─── Nutrition Scan Model ────────────────────────────────
class NutritionScan(Base):
    __tablename__ = 'nutrition_scans'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=True)
    scanned_at = Column(DateTime, default=datetime.utcnow)
    scan_date = Column(Date, default=date.today)
    product_name = Column(String, nullable=True)
    calories = Column(Integer, nullable=True)
    total_fat = Column(Float, nullable=True)
    saturated_fat = Column(Float, nullable=True)
    trans_fat = Column(Float, nullable=True)
    cholesterol = Column(Float, nullable=True)
    sodium = Column(Float, nullable=True)
    carbohydrates = Column(Float, nullable=True)
    fiber = Column(Float, nullable=True)
    sugar = Column(Float, nullable=True)
    protein = Column(Float, nullable=True)
    health_score = Column(Integer, nullable=True)
    warnings = Column(String, nullable=True)
    raw_text = Column(String, nullable=True)

    # Relationship
    user = relationship("User", back_populates="scans")


# ─── Jamaican Products Model ─────────────────────────────
class JamaicanProduct(Base):
    __tablename__ = 'jamaican_products'

    id = Column(Integer, primary_key=True, index=True)
    brand = Column(String, nullable=False)
    product = Column(String, nullable=False)
    category = Column(String, nullable=False)
    calories = Column(Integer, nullable=True)
    sugar = Column(Float, nullable=True)
    sodium = Column(Float, nullable=True)
    protein = Column(Float, nullable=True)
    total_fat = Column(Float, nullable=True)
    fiber = Column(Float, nullable=True)
    carbohydrates = Column(Float, nullable=True)
    why_healthy = Column(String, nullable=True)
    suitable_for = Column(String, nullable=True)


# Create all tables
Base.metadata.create_all(engine)


# ─── User Functions ──────────────────────────────────────
def create_user(email: str, password_hash: str):
    """Creates a new user account"""
    db = SessionLocal()
    try:
        user = User(email=email, password_hash=password_hash)
        db.add(user)
        db.commit()
        db.refresh(user)
        return user
    finally:
        db.close()


def get_user_by_email(email: str):
    """Gets a user by email"""
    db = SessionLocal()
    try:
        return db.query(User).filter(User.email == email).first()
    finally:
        db.close()


def get_user_by_id(user_id: int):
    """Gets a user by ID"""
    db = SessionLocal()
    try:
        return db.query(User).filter(User.id == user_id).first()
    finally:
        db.close()


# ─── Health Profile Functions ────────────────────────────
def save_health_profile(
    user_id: int,
    age: int,
    gender: str,
    weight_kg: float,
    height_cm: float,
    dietary_goal: str,
    health_conditions: list
):
    """Saves or updates a user's health profile"""
    db = SessionLocal()
    try:
        # Check if profile exists
        profile = db.query(HealthProfile).filter(
            HealthProfile.user_id == user_id
        ).first()

        conditions_str = ','.join(health_conditions)

        if profile:
            # Update existing
            profile.age = age
            profile.gender = gender
            profile.weight_kg = weight_kg
            profile.height_cm = height_cm
            profile.dietary_goal = dietary_goal
            profile.health_conditions = conditions_str
            profile.updated_at = datetime.utcnow()
        else:
            # Create new
            profile = HealthProfile(
                user_id=user_id,
                age=age,
                gender=gender,
                weight_kg=weight_kg,
                height_cm=height_cm,
                dietary_goal=dietary_goal,
                health_conditions=conditions_str
            )
            db.add(profile)

        db.commit()
        db.refresh(profile)
        return profile
    finally:
        db.close()


def get_health_profile(user_id: int):
    """Gets a user's health profile"""
    db = SessionLocal()
    try:
        profile = db.query(HealthProfile).filter(
            HealthProfile.user_id == user_id
        ).first()
        if profile:
            return {
                "age": profile.age,
                "gender": profile.gender,
                "weight_kg": profile.weight_kg,
                "height_cm": profile.height_cm,
                "dietary_goal": profile.dietary_goal,
                "health_conditions": profile.health_conditions.split(',')
                if profile.health_conditions else []
            }
        return None
    finally:
        db.close()


# ─── Scan Functions ──────────────────────────────────────
def save_scan(
    nutrition_data: dict,
    health_score: int,
    raw_text: str,
    warnings: list,
    product_name: str = None,
    user_id: int = None
):
    """Saves a scan result linked to a user"""
    db = SessionLocal()
    try:
        scan = NutritionScan(
            user_id=user_id,
            product_name=product_name,
            scan_date=date.today(),
            calories=nutrition_data.get('calories'),
            total_fat=nutrition_data.get('total_fat'),
            saturated_fat=nutrition_data.get('saturated_fat'),
            trans_fat=nutrition_data.get('trans_fat'),
            cholesterol=nutrition_data.get('cholesterol'),
            sodium=nutrition_data.get('sodium'),
            carbohydrates=nutrition_data.get('carbohydrates'),
            fiber=nutrition_data.get('fiber'),
            sugar=nutrition_data.get('sugar'),
            protein=nutrition_data.get('protein'),
            health_score=health_score,
            raw_text=raw_text,
            warnings=str(warnings)
        )
        db.add(scan)
        db.commit()
        db.refresh(scan)
        return scan.id
    finally:
        db.close()


def get_user_scans(user_id: int):
    """Gets all scans for a user"""
    db = SessionLocal()
    try:
        scans = db.query(NutritionScan).filter(
            NutritionScan.user_id == user_id
        ).order_by(NutritionScan.scanned_at.desc()).all()

        return [
            {
                "id": s.id,
                "product_name": s.product_name,
                "scanned_at": str(s.scanned_at),
                "calories": s.calories,
                "sugar": s.sugar,
                "sodium": s.sodium,
                "protein": s.protein,
                "health_score": s.health_score,
            }
            for s in scans
        ]
    finally:
        db.close()


def get_daily_totals(user_id: int, target_date: date = None):
    """
    Calculates total nutrients consumed today
    Groups all scans for the day and sums nutrients
    """
    db = SessionLocal()
    try:
        if target_date is None:
            target_date = date.today()

        # Get all scans for today
        scans = db.query(NutritionScan).filter(
            NutritionScan.user_id == user_id,
            NutritionScan.scan_date == target_date
        ).all()

        if not scans:
            return {
                "date": str(target_date),
                "total_scans": 0,
                "calories": 0,
                "sugar": 0,
                "sodium": 0,
                "total_fat": 0,
                "saturated_fat": 0,
                "carbohydrates": 0,
                "protein": 0,
                "fiber": 0,
            }

        # Sum all nutrients
        totals = {
            "date": str(target_date),
            "total_scans": len(scans),
            "calories": sum(s.calories or 0 for s in scans),
            "sugar": round(sum(s.sugar or 0 for s in scans), 1),
            "sodium": round(sum(s.sodium or 0 for s in scans), 1),
            "total_fat": round(sum(s.total_fat or 0 for s in scans), 1),
            "saturated_fat": round(sum(s.saturated_fat or 0 for s in scans), 1),
            "carbohydrates": round(sum(s.carbohydrates or 0 for s in scans), 1),
            "protein": round(sum(s.protein or 0 for s in scans), 1),
            "fiber": round(sum(s.fiber or 0 for s in scans), 1),
        }

        return totals
    finally:
        db.close()


def get_all_scans():
    """Gets all scans — for admin use"""
    db = SessionLocal()
    try:
        scans = db.query(NutritionScan).order_by(
            NutritionScan.scanned_at.desc()
        ).all()
        return [
            {
                "id": s.id,
                "scanned_at": str(s.scanned_at),
                "product_name": s.product_name,
                "calories": s.calories,
                "sodium": s.sodium,
                "sugar": s.sugar,
                "protein": s.protein,
                "health_score": s.health_score,
            }
            for s in scans
        ]
    finally:
        db.close()


# ─── Products Functions ──────────────────────────────────
def seed_products():
    """Seeds the database with real Jamaican products"""
    db = SessionLocal()
    try:
        count = db.query(JamaicanProduct).count()
        if count > 0:
            print(f"Products already seeded: {count} products found")
            return

        products = [
            JamaicanProduct(brand="Grace Foods", product="Grace Coconut Water",
                category="sugary_drinks", calories=45, sugar=11, sodium=25,
                protein=0, total_fat=0, fiber=0, carbohydrates=11,
                why_healthy="Natural hydration with significantly less sugar than sodas",
                suitable_for="Hypertension,Diabetes,Obesity,Heart Disease,PCOS"),
            JamaicanProduct(brand="Wisynco", product="Wata Still Water",
                category="sugary_drinks", calories=0, sugar=0, sodium=0,
                protein=0, total_fat=0, fiber=0, carbohydrates=0,
                why_healthy="Zero calories and sugar — best hydration option",
                suitable_for="Hypertension,Diabetes,Obesity,Heart Disease,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Wisynco", product="Bigga Diet",
                category="sugary_drinks", calories=5, sugar=0, sodium=20,
                protein=0, total_fat=0, fiber=0, carbohydrates=0,
                why_healthy="Zero sugar version of popular Jamaican drink",
                suitable_for="Diabetes,Obesity,PCOS"),
            JamaicanProduct(brand="Lasco", product="Lasco Soy Drink Unsweetened",
                category="sugary_drinks", calories=80, sugar=2, sodium=30,
                protein=7, total_fat=3, fiber=1, carbohydrates=6,
                why_healthy="High protein low sugar plant based alternative",
                suitable_for="Diabetes,Obesity,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Pure Country", product="Pure Country Pineapple Juice",
                category="sugary_drinks", calories=60, sugar=10, sodium=10,
                protein=0, total_fat=0, fiber=0, carbohydrates=14,
                why_healthy="No sugar added premium Jamaican fruit juice",
                suitable_for="Obesity,Heart Disease,PCOS"),
            JamaicanProduct(brand="Pure Country", product="Pure Country Cranberry Juice",
                category="sugary_drinks", calories=50, sugar=8, sodium=10,
                protein=0, total_fat=0, fiber=0, carbohydrates=12,
                why_healthy="No sugar added rich in antioxidants and vitamin C",
                suitable_for="Hypertension,Heart Disease,PCOS,Obesity"),
            JamaicanProduct(brand="Pure Country", product="Pure Country Coconut Water",
                category="sugary_drinks", calories=45, sugar=9, sodium=25,
                protein=0, total_fat=0, fiber=0, carbohydrates=11,
                why_healthy="Natural no sugar added coconut water packed with electrolytes",
                suitable_for="Hypertension,Diabetes,Obesity,Heart Disease,PCOS"),
            JamaicanProduct(brand="Caribbean Dreams", product="Caribbean Dreams Ginger Tea",
                category="sugary_drinks", calories=2, sugar=0, sodium=0,
                protein=0, total_fat=0, fiber=0, carbohydrates=0,
                why_healthy="100% natural caffeine free ginger aids digestion",
                suitable_for="Hypertension,Diabetes,Obesity,Heart Disease,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Caribbean Dreams", product="Caribbean Dreams Sorrel and Ginger Tea",
                category="sugary_drinks", calories=2, sugar=0, sodium=0,
                protein=0, total_fat=0, fiber=0, carbohydrates=0,
                why_healthy="Rich in antioxidants naturally lowers blood pressure",
                suitable_for="Hypertension,Diabetes,Obesity,Heart Disease,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Caribbean Dreams", product="Caribbean Dreams Cerasee Tea",
                category="sugary_drinks", calories=2, sugar=0, sodium=0,
                protein=0, total_fat=0, fiber=0, carbohydrates=0,
                why_healthy="Traditional Jamaican herb known to help with blood sugar",
                suitable_for="Hypertension,Diabetes,Obesity,Heart Disease,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Caribbean Dreams", product="Caribbean Dreams Moringa Mint Tea",
                category="sugary_drinks", calories=2, sugar=0, sodium=0,
                protein=0, total_fat=0, fiber=0, carbohydrates=0,
                why_healthy="Moringa is a superfood packed with vitamins and minerals",
                suitable_for="Hypertension,Diabetes,Obesity,Heart Disease,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Caribbean Dreams", product="Caribbean Dreams Peppermint Tea",
                category="sugary_drinks", calories=2, sugar=0, sodium=0,
                protein=0, total_fat=0, fiber=0, carbohydrates=0,
                why_healthy="Naturally caffeine free aids digestion and reduces bloating",
                suitable_for="Hypertension,Diabetes,Obesity,Heart Disease,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Caribbean Dreams", product="Caribbean Dreams Detox Tea",
                category="sugary_drinks", calories=2, sugar=0, sodium=0,
                protein=0, total_fat=0, fiber=0, carbohydrates=0,
                why_healthy="All natural cleansing herbal blend supports weight management",
                suitable_for="Obesity,PCOS,Diabetes"),
            JamaicanProduct(brand="Grace Foods", product="Grace Unsalted Peanuts",
                category="snacks", calories=160, sugar=1, sodium=0,
                protein=7, total_fat=14, fiber=2, carbohydrates=5,
                why_healthy="High protein healthy fats no added sugar or salt",
                suitable_for="Diabetes,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Grace Foods", product="Grace Bulla Cake",
                category="snacks", calories=130, sugar=8, sodium=95,
                protein=2, total_fat=2, fiber=1, carbohydrates=26,
                why_healthy="Traditional low fat Jamaican snack made with molasses",
                suitable_for="Heart Disease,High Cholesterol"),
            JamaicanProduct(brand="Lasco", product="Lasco Low Fat Milk",
                category="dairy", calories=100, sugar=12, sodium=120,
                protein=8, total_fat=2, fiber=0, carbohydrates=12,
                why_healthy="High calcium and protein with reduced fat content",
                suitable_for="Obesity,Heart Disease,High Cholesterol"),
            JamaicanProduct(brand="Lasco", product="Lasco Skimmed Milk Powder",
                category="dairy", calories=80, sugar=11, sodium=115,
                protein=8, total_fat=0, fiber=0, carbohydrates=12,
                why_healthy="Zero fat dairy with high protein and calcium",
                suitable_for="Obesity,Heart Disease,High Cholesterol"),
            JamaicanProduct(brand="Grace Foods", product="Grace Callaloo",
                category="canned_foods", calories=25, sugar=1, sodium=180,
                protein=3, total_fat=0, fiber=2, carbohydrates=4,
                why_healthy="High in iron and vitamins very low calories",
                suitable_for="Hypertension,Diabetes,Obesity,Heart Disease,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Grace Foods", product="Grace Ackee in Brine",
                category="canned_foods", calories=90, sugar=2, sodium=200,
                protein=3, total_fat=8, fiber=3, carbohydrates=4,
                why_healthy="Traditional Jamaican superfood high in healthy fats",
                suitable_for="Diabetes,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Grace Foods", product="Grace Red Kidney Beans",
                category="canned_foods", calories=110, sugar=1, sodium=140,
                protein=7, total_fat=0, fiber=6, carbohydrates=20,
                why_healthy="High fiber and protein great for blood sugar control",
                suitable_for="Hypertension,Diabetes,Obesity,Heart Disease,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Grace Foods", product="Grace Mackerel in Brine",
                category="canned_foods", calories=120, sugar=0, sodium=300,
                protein=18, total_fat=5, fiber=0, carbohydrates=0,
                why_healthy="High protein omega 3 rich zero carb option",
                suitable_for="Diabetes,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Grace Foods", product="Grace Green Pigeon Peas",
                category="canned_foods", calories=100, sugar=1, sodium=130,
                protein=6, total_fat=0, fiber=5, carbohydrates=18,
                why_healthy="High fiber plant protein good for digestion",
                suitable_for="Diabetes,Obesity,Heart Disease,PCOS"),
            JamaicanProduct(brand="Grace Foods", product="Grace Sardines in Tomato Sauce",
                category="canned_foods", calories=130, sugar=2, sodium=310,
                protein=15, total_fat=7, fiber=0, carbohydrates=3,
                why_healthy="High omega 3 and protein excellent for heart health",
                suitable_for="Diabetes,PCOS,High Cholesterol,Heart Disease"),
            JamaicanProduct(brand="Lasco", product="Lasco Cornmeal Porridge Mix",
                category="cereals", calories=130, sugar=4, sodium=85,
                protein=3, total_fat=1, fiber=2, carbohydrates=28,
                why_healthy="Whole grain traditional Jamaican breakfast with lower sugar",
                suitable_for="Heart Disease,High Cholesterol"),
            JamaicanProduct(brand="Grace Foods", product="Grace Oats",
                category="cereals", calories=150, sugar=1, sodium=0,
                protein=5, total_fat=3, fiber=4, carbohydrates=27,
                why_healthy="High fiber whole grain excellent for heart health",
                suitable_for="Hypertension,Diabetes,Obesity,Heart Disease,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Walkerswood", product="Walkerswood Traditional Jerk Seasoning",
                category="condiments", calories=15, sugar=1, sodium=280,
                protein=0, total_fat=0, fiber=0, carbohydrates=3,
                why_healthy="All natural Jamaican spices no artificial additives",
                suitable_for="Diabetes,Obesity,PCOS"),
            JamaicanProduct(brand="Walkerswood", product="Walkerswood Scotch Bonnet Pepper Sauce",
                category="condiments", calories=10, sugar=1, sodium=200,
                protein=0, total_fat=0, fiber=0, carbohydrates=2,
                why_healthy="Natural hot sauce boosts metabolism no artificial ingredients",
                suitable_for="Diabetes,Obesity,PCOS,High Cholesterol"),
            JamaicanProduct(brand="Pickapeppa", product="Pickapeppa Sauce Original",
                category="condiments", calories=20, sugar=4, sodium=160,
                protein=0, total_fat=0, fiber=0, carbohydrates=5,
                why_healthy="Natural Jamaican sauce no artificial preservatives",
                suitable_for="Obesity,High Cholesterol"),
        ]

        db.add_all(products)
        db.commit()
        print(f"✅ Seeded {len(products)} Jamaican products!")
    finally:
        db.close()


def get_alternatives_from_db(category: str, health_conditions: list = []):
    """Gets real Jamaican alternatives from PostgreSQL"""
    db = SessionLocal()
    try:
        query = db.query(JamaicanProduct).filter(
            JamaicanProduct.category == category
        )
        products = query.all()

        if not products:
            products = db.query(JamaicanProduct).limit(10).all()

        filtered = []
        for product in products:
            suitable = True
            suitable_for = product.suitable_for or ""
            for condition in health_conditions:
                if condition not in suitable_for:
                    suitable = False
                    break
            if suitable:
                filtered.append({
                    "brand": product.brand,
                    "product": product.product,
                    "calories": str(product.calories),
                    "sugar": f"{product.sugar}g",
                    "sodium": f"{product.sodium}mg",
                    "protein": f"{product.protein}g",
                    "why": product.why_healthy
                })

        return filtered[:3] if filtered else [
            {
                "brand": p.brand,
                "product": p.product,
                "calories": str(p.calories),
                "sugar": f"{p.sugar}g",
                "sodium": f"{p.sodium}mg",
                "protein": f"{p.protein}g",
                "why": p.why_healthy
            }
            for p in products[:3]
        ]
    finally:
        db.close()