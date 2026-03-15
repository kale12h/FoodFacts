from ultralytics import YOLO

print("Downloading YOLOv8 model...")

# This downloads the model automatically
model = YOLO('yolov8n.pt')

# Save it to the models folder
model.save('models/yolov8n.pt')

# Export to ONNX
model.export(format='onnx', imgsz=640)
print("Model exported to ONNX ✅")