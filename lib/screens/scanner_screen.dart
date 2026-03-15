import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'results_screen.dart';

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _capturedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> scanLabel() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (photo != null) {
      setState(() {
        _capturedImage = File(photo.path);
        _isLoading = true;
      });

      // Send image to Python backend
      final result = await ApiService.scanNutritionLabel(_capturedImage!);

      setState(() {
        _isLoading = false;
      });

      // Go to results screen with the data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(nutritionData: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Scan Nutrition Label'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show image preview or placeholder
            if (_capturedImage != null)
              Container(
                height: 300,
                width: double.infinity,
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_capturedImage!, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 300,
                width: double.infinity,
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey, width: 2),
                  color: Colors.grey[100],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No image captured yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 24),

            // Loading indicator or scan button
            if (_isLoading)
              Column(
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 12),
                  Text('Scanning label...'),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: scanLabel,
                icon: Icon(Icons.camera_alt),
                label: Text('Scan Label'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
