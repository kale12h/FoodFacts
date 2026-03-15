from PIL import Image
from ultralytics import YOLO
from openai import OpenAI
from dotenv import load_dotenv
import io
import os
import base64
import re

# Load environment variables
load_dotenv()

# Configure OpenAI
client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

# Load YOLO model
model_path = os.path.join(os.path.dirname(__file__), 'models', 'yolov8n.pt')
yolo_model = None
if os.path.exists(model_path):
    yolo_model = YOLO(model_path)


def process_image(image_bytes):
    """
    Receives image bytes, runs YOLO to detect
    nutrition label, then crops it
    """
    try:
        img = Image.open(io.BytesIO(image_bytes))

        if img.mode != 'RGB':
            img = img.convert('RGB')

        max_size = (1024, 1024)
        img.thumbnail(max_size)

        if yolo_model is not None:
            results = yolo_model(img)
            boxes = results[0].boxes
            if len(boxes) > 0:
                box = boxes[0].xyxy[0].tolist()
                x1, y1, x2, y2 = map(int, box)
                img = img.crop((x1, y1, x2, y2))

        img_byte_arr = io.BytesIO()
        img.save(img_byte_arr, format='JPEG', quality=95)
        img_byte_arr = img_byte_arr.getvalue()

        return {
            "success": True,
            "image": img_byte_arr,
            "width": img.width,
            "height": img.height
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }


def extract_text_from_image(image_bytes, health_conditions=[]):
    """
    Sends image directly to GPT-4 Vision
    Extracts nutrition facts, identifies product,
    and checks against health conditions
    """
    try:
        # Convert image to base64
        base64_image = base64.b64encode(image_bytes).decode('utf-8')

        # Build conditions text
        conditions_text = ""
        if health_conditions:
            conditions_text = f"""
            The user has these health conditions: {', '.join(health_conditions)}.

            Check for warnings based on these rules:
            - Hypertension: warn if sodium > 600mg
            - Diabetes: warn if sugar > 12g or carbohydrates > 45g
            - High Cholesterol: warn if saturated fat > 5g or trans fat > 0g
            - Obesity: warn if calories > 500 or total fat > 20g
            - Heart Disease: warn if sodium > 600mg or saturated fat > 5g
            - PCOS: warn if sugar > 12g or carbohydrates > 45g or trans fat > 0g
            """

        # Send image to GPT-4 Vision
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": f"""Look at this nutrition label image and do 3 things:

                            1. Identify the product if visible, or describe what type 
                            of product it is based on the nutrition values:
                            product_name: [brand and product name if visible, 
                            otherwise describe e.g. "Sugary Carbonated Drink"]
                            product_category: [one of: sugary_drinks, snacks, 
                            dairy, canned_foods, cereals, condiments]

                            2. Extract ALL nutrition facts in this exact format:
                            calories: [number]
                            total_fat: [number]
                            saturated_fat: [number]
                            trans_fat: [number]
                            cholesterol: [number]
                            sodium: [number]
                            carbohydrates: [number]
                            fiber: [number]
                            sugar: [number]
                            protein: [number]
                            vitamin_d: [number]
                            calcium: [number]
                            iron: [number]
                            potassium: [number]

                            3. List any health warnings based on these conditions:
                            {conditions_text}
                            warnings: [list warnings separated by | or write NONE]

                            If a nutrition value is not found write null.
                            Only return data in the format above, nothing else.
                            """
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ],
            max_tokens=800
        )

        raw_text = response.choices[0].message.content

        # Extract warnings
        warnings = []
        warnings_match = re.search(
            r'warnings:\s*(.+?)(?:\n|$)', raw_text, re.IGNORECASE
        )
        if warnings_match:
            warnings_text = warnings_match.group(1).strip()
            if warnings_text.upper() != 'NONE':
                warnings = [w.strip() for w in warnings_text.split('|')]

        # Extract product name
        product_name = "Unknown"
        product_match = re.search(
            r'product_name:\s*(.+?)(?:\n|$)', raw_text, re.IGNORECASE
        )
        if product_match:
            product_name = product_match.group(1).strip()

        # Extract product category
        product_category = "sugary_drinks"
        category_match = re.search(
            r'product_category:\s*(.+?)(?:\n|$)', raw_text, re.IGNORECASE
        )
        if category_match:
            product_category = category_match.group(1).strip().lower()

        return {
            "success": True,
            "text": raw_text,
            "warnings": warnings,
            "product_name": product_name,
            "product_category": product_category
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }
