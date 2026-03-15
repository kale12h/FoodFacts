import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class HealthSetupScreen extends StatefulWidget {
  @override
  _HealthSetupScreenState createState() => _HealthSetupScreenState();
}

class _HealthSetupScreenState extends State<HealthSetupScreen> {
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _gender = 'Male';
  String _dietaryGoal = 'General Health';
  List<String> _selectedConditions = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentStep = 0;

  final List<String> _conditions = [
    'Hypertension',
    'Diabetes',
    'High Cholesterol',
    'Obesity',
    'Heart Disease',
    'PCOS',
  ];

  final List<String> _dietaryGoals = [
    'General Health',
    'Weight Loss',
    'Muscle Gain',
    'Heart Health',
    'Diabetes Management',
    'Low Sodium Diet',
  ];

  Future<void> _saveProfile() async {
    if (_ageController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.saveHealthProfile(
      age: int.parse(_ageController.text),
      gender: _gender,
      weightKg: double.parse(_weightController.text),
      heightCm: double.parse(_heightController.text),
      dietaryGoal: _dietaryGoal,
      healthConditions: _selectedConditions,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      setState(() => _errorMessage = 'Failed to save profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  Row(
                    children: List.generate(3, (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: index <= _currentStep
                              ? Color(0xFF2D6A4F)
                              : Colors.grey[200],
                        ),
                      ),
                    )),
                  ),
                  SizedBox(height: 24),
                  Text(
                    _getStepTitle(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    _getStepSubtitle(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _buildCurrentStep(),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                            color: Colors.red[700], fontSize: 14),
                      ),
                    ),
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _currentStep--),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFF2D6A4F),
                              side: BorderSide(color: Color(0xFF2D6A4F)),
                              padding:
                                  EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Back'),
                          ),
                        ),
                      if (_currentStep > 0) SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2D6A4F),
                            foregroundColor: Colors.white,
                            padding:
                                EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _currentStep == 2
                                      ? 'Finish Setup'
                                      : 'Continue',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomeScreen()),
                    ),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNext() {
    if (_currentStep < 2) {
      setState(() {
        _errorMessage = null;
        _currentStep++;
      });
    } else {
      _saveProfile();
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Basic Information';
      case 1: return 'Your Goals';
      case 2: return 'Health Conditions';
      default: return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0: return 'Tell us about yourself';
      case 1: return 'What are you trying to achieve?';
      case 2: return 'Select any conditions that apply';
      default: return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildBasicInfoStep();
      case 1: return _buildGoalsStep();
      case 2: return _buildConditionsStep();
      default: return SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        // Age
        _buildLabel('Age'),
        SizedBox(height: 8),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Enter your age', Icons.cake_outlined),
        ),
        SizedBox(height: 16),

        // Gender
        _buildLabel('Gender'),
        SizedBox(height: 8),
        Row(
          children: ['Male', 'Female', 'Other'].map((g) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _gender = g),
              child: Container(
                margin: EdgeInsets.only(right: g != 'Other' ? 8 : 0),
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _gender == g
                      ? Color(0xFF2D6A4F)
                      : Colors.grey[100],
                  border: Border.all(
                    color: _gender == g
                        ? Color(0xFF2D6A4F)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Center(
                  child: Text(
                    g,
                    style: TextStyle(
                      color: _gender == g
                          ? Colors.white
                          : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
        SizedBox(height: 16),

        // Weight
        _buildLabel('Weight (kg)'),
        SizedBox(height: 8),
        TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Enter your weight', Icons.monitor_weight_outlined),
        ),
        SizedBox(height: 16),

        // Height
        _buildLabel('Height (cm)'),
        SizedBox(height: 8),
        TextField(
          controller: _heightController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Enter your height', Icons.height),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGoalsStep() {
    return Column(
      children: _dietaryGoals.map((goal) => GestureDetector(
        onTap: () => setState(() => _dietaryGoal = goal),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _dietaryGoal == goal
                ? Color(0xFF2D6A4F).withOpacity(0.05)
                : Colors.grey[50],
            border: Border.all(
              color: _dietaryGoal == goal
                  ? Color(0xFF2D6A4F)
                  : Colors.grey[200]!,
              width: _dietaryGoal == goal ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _goalIcon(goal),
                color: _dietaryGoal == goal
                    ? Color(0xFF2D6A4F)
                    : Colors.grey,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                goal,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _dietaryGoal == goal
                      ? Color(0xFF2D6A4F)
                      : Color(0xFF1A1A2E),
                ),
              ),
              Spacer(),
              if (_dietaryGoal == goal)
                Icon(Icons.check_circle,
                    color: Color(0xFF2D6A4F), size: 20),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildConditionsStep() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'We will warn you about foods that may affect your conditions',
                  style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
        ..._conditions.map((condition) => GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedConditions.contains(condition)) {
                _selectedConditions.remove(condition);
              } else {
                _selectedConditions.add(condition);
              }
            });
          },
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _selectedConditions.contains(condition)
                  ? Color(0xFF2D6A4F).withOpacity(0.05)
                  : Colors.grey[50],
              border: Border.all(
                color: _selectedConditions.contains(condition)
                    ? Color(0xFF2D6A4F)
                    : Colors.grey[200]!,
                width: _selectedConditions.contains(condition) ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(_conditionEmoji(condition),
                    style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Text(
                  condition,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _selectedConditions.contains(condition)
                        ? Color(0xFF2D6A4F)
                        : Color(0xFF1A1A2E),
                  ),
                ),
                Spacer(),
                if (_selectedConditions.contains(condition))
                  Icon(Icons.check_circle,
                      color: Color(0xFF2D6A4F), size: 20)
                else
                  Icon(Icons.circle_outlined,
                      color: Colors.grey, size: 20),
              ],
            ),
          ),
        )),
        SizedBox(height: 24),
      ],
    );
  }

  IconData _goalIcon(String goal) {
    switch (goal) {
      case 'Weight Loss': return Icons.trending_down;
      case 'Muscle Gain': return Icons.fitness_center;
      case 'Heart Health': return Icons.favorite_outline;
      case 'Diabetes Management': return Icons.bloodtype_outlined;
      case 'Low Sodium Diet': return Icons.no_food_outlined;
      default: return Icons.health_and_safety_outlined;
    }
  }

  String _conditionEmoji(String condition) {
    switch (condition) {
      case 'Hypertension': return '🫀';
      case 'Diabetes': return '🩸';
      case 'High Cholesterol': return '🧬';
      case 'Obesity': return '⚖️';
      case 'Heart Disease': return '❤️';
      case 'PCOS': return '🔬';
      default: return '💊';
    }
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Color(0xFF2D6A4F)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF2D6A4F)),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
          fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
    );
  }
}