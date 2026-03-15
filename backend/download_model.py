from ultralytics import YOLO

print("Downloading YOLOv8 model...")

# This downloads the model automatically
model = YOLO('yolov8n.pt')

# Save it to the models folder
model.save('models/yolov8n.pt')

print("Model downloaded and saved to models/yolov8n.pt ✅")