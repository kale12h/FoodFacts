from PIL import Image
import os
import base64
import re
import numpy as np
import json

try:
    import onnxruntime as ort
    import cv2
    onnxruntime_available = True
except ImportError:
    onnxruntime_available = False

from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure OpenAI
client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

# Load ONNX model
yolo_session = None
if onnxruntime_available:
    model_path = os.path.join(os.path.dirname(__file__), 'yolov8n.onnx')
    if os.path.exists(model_path):
        yolo_session = ort.InferenceSession(model_path)

def preprocess_image(img, input_size=640):
    """
    Preprocess image for YOLOv8 ONNX model
    """
    if not onnxruntime_available:
        return None
    # Resize to input_size x input_size
    img_resized = cv2.resize(np.array(img), (input_size, input_size))
    # Convert to RGB if needed
    if img_resized.shape[2] == 4:  # RGBA
        img_resized = cv2.cvtColor(img_resized, cv2.COLOR_RGBA2RGB)
    # Normalize to 0-1
    img_normalized = img_resized / 255.0
    # Transpose to CHW
    img_chw = np.transpose(img_normalized, (2, 0, 1))
    # Add batch dimension
    img_batch = np.expand_dims(img_chw, axis=0).astype(np.float32)
    return img_batch

def postprocess_output(output, conf_threshold=0.5, iou_threshold=0.45):
    """
    Postprocess YOLOv8 output to get bounding boxes
    """
    if not onnxruntime_available:
        return []
    # YOLOv8 output: [1, 84, 8400]
    predictions = output[0][0]  # Remove batch dim, shape [84, 8400]
    
    # Reshape to [8400, 84]
    predictions = predictions.T
    
    # Split into boxes, scores, classes
    boxes = predictions[:, :4]  # x, y, w, h
    scores = predictions[:, 4:5] * predictions[:, 5:]  # conf * class_probs
    scores = np.max(scores, axis=1)
    classes = np.argmax(predictions[:, 5:], axis=1)
    
    # Filter by confidence
    mask = scores > conf_threshold
    boxes = boxes[mask]
    scores = scores[mask]
    classes = classes[mask]
    
    # Convert boxes from xywh to xyxy
    boxes[:, 2] += boxes[:, 0]  # x2 = x + w
    boxes[:, 3] += boxes[:, 1]  # y2 = y + h
    
    # Apply NMS (simple version)
    indices = cv2.dnn.NMSBoxes(boxes.tolist(), scores.tolist(), conf_threshold, iou_threshold)
    if len(indices) > 0:
        indices = indices.flatten()
        boxes = boxes[indices]
        scores = scores[indices]
        classes = classes[indices]
    
    return boxes, scores, classes


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

        if yolo_session is not None:
            # Preprocess
            input_tensor = preprocess_image(img)
            # Run inference
            outputs = yolo_session.run(None, {'images': input_tensor})
            # Postprocess
            boxes, scores, classes = postprocess_output(outputs)
            if len(boxes) > 0:
                # Take the first box
                x, y, w, h = boxes[0]
                # Scale back to original size
                orig_w, orig_h = img.size
                scale_x = orig_w / 640
                scale_y = orig_h / 640
                x = int(x * scale_x)
                y = int(y * scale_y)
                w = int(w * scale_x)
                h = int(h * scale_y)
                img = img.crop((x, y, x + w, y + h))

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
                            "text": f"""Look at this nutrition label image and extract the information as JSON.

Return a JSON object with these exact keys:
{{
    "product_name": "brand and product name if visible, otherwise describe e.g. Sugary Carbonated Drink",
    "product_category": "one of: sugary_drinks, snacks, dairy, canned_foods, cereals, condiments",
    "nutrition": {{
        "calories": number or null,
        "total_fat": number or null,
        "saturated_fat": number or null,
        "trans_fat": number or null,
        "cholesterol": number or null,
        "sodium": number or null,
        "carbohydrates": number or null,
        "fiber": number or null,
        "sugar": number or null,
        "protein": number or null,
        "vitamin_d": number or null,
        "calcium": number or null,
        "iron": number or null,
        "potassium": number or null
    }},
    "warnings": ["list of warnings based on health conditions", ...] or []
}}

Health conditions to check for warnings:
{conditions_text}

If a value is not found, use null.
Only return the JSON object, nothing else.
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

        # Clean the response to extract JSON
        cleaned_text = raw_text.strip()
        if cleaned_text.startswith('```json'):
            cleaned_text = cleaned_text[7:]
        if cleaned_text.endswith('```'):
            cleaned_text = cleaned_text[:-3]
        cleaned_text = cleaned_text.strip()

        # Parse JSON response
        try:
            data = json.loads(cleaned_text)
            product_name = data.get("product_name", "Unknown")
            product_category = data.get("product_category", "sugary_drinks")
            nutrition = data.get("nutrition", {})
            warnings = data.get("warnings", [])
        except json.JSONDecodeError as e:
            print(f"JSON decode error: {e}")
            print(f"Raw response: {raw_text}")
            # Fallback to old parsing if not JSON
            product_name = "Unknown"
            product_category = "sugary_drinks"
            nutrition = {}
            warnings = []

        return {
            "success": True,
            "text": raw_text,
            "product_name": product_name,
            "product_category": product_category,
            "warnings": warnings,
            "nutrition": nutrition
        }
            "product_name": product_name,
            "product_category": product_category
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }
