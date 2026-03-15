import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> nutritionData;

  const ResultsScreen({Key? key, required this.nutritionData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nutrition = nutritionData['nutrition'] ?? {};
    final warnings = List<String>.from(nutritionData['warnings'] ?? []);
    final alternatives =
        List<dynamic>.from(nutritionData['alternatives'] ?? []);
    final healthScore = nutritionData['health_score'] ?? 0;
    final productName =
        nutritionData['product_name'] ?? 'Scanned Product';

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text('Scan Results',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top hero section
            _buildHeroSection(healthScore, productName),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warnings
                  if (warnings.isNotEmpty) ...[
                    _buildWarningsSection(warnings),
                    SizedBox(height: 16),
                  ],

                  // Simple nutrition breakdown
                  _buildSimpleNutritionSection(nutrition),
                  SizedBox(height: 16),

                  // Alternatives
                  if (alternatives.isNotEmpty) ...[
                    _buildAlternativesSection(alternatives),
                    SizedBox(height: 16),
                  ],

                  // Full details toggle
                  _buildFullDetailsSection(nutrition),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hero section with big health score
  Widget _buildHeroSection(int score, String productName) {
    Color bgColor;
    Color scoreColor;
    String emoji;
    String message;

    if (score >= 75) {
      bgColor = Color(0xFF2D6A4F);
      scoreColor = Color(0xFF95D5B2);
      emoji = '😊';
      message = 'This product looks good!';
    } else if (score >= 50) {
      bgColor = Color(0xFFB7791F);
      scoreColor = Color(0xFFFBD38D);
      emoji = '😐';
      message = 'Eat this in moderation';
    } else {
      bgColor = Color(0xFF9B2C2C);
      scoreColor = Color(0xFFFEB2B2);
      emoji = '😟';
      message = 'Not great for your health';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Product name
          Text(
            productName,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),

          // Big emoji
          Text(emoji, style: TextStyle(fontSize: 64)),
          SizedBox(height: 8),

          // Score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white54,
                ),
              ),
            ],
          ),

          // Message
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Health Score',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Simple easy to understand nutrition section
  Widget _buildSimpleNutritionSection(Map nutrition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s in this product?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Based on one serving',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 12),

        // Simple nutrient cards
        _buildSimpleNutrientCard(
          icon: '🔥',
          label: 'Calories',
          value: nutrition['calories'],
          dailyValue: 2000,
          unit: 'kcal',
          lowLabel: 'Low calories',
          medLabel: 'Moderate calories',
          highLabel: 'High calories!',
        ),
        _buildSimpleNutrientCard(
          icon: '🍬',
          label: 'Sugar',
          value: nutrition['sugar'],
          dailyValue: 50,
          unit: 'g',
          lowLabel: 'Low sugar ✓',
          medLabel: 'Some sugar',
          highLabel: 'Too much sugar!',
        ),
        _buildSimpleNutrientCard(
          icon: '🧂',
          label: 'Salt (Sodium)',
          value: nutrition['sodium'],
          dailyValue: 2300,
          unit: 'mg',
          lowLabel: 'Low salt ✓',
          medLabel: 'Some salt',
          highLabel: 'Too much salt!',
        ),
        _buildSimpleNutrientCard(
          icon: '🥩',
          label: 'Protein',
          value: nutrition['protein'],
          dailyValue: 50,
          unit: 'g',
          lowLabel: 'Low protein',
          medLabel: 'Some protein',
          highLabel: 'High protein ✓',
          isGoodHigh: true,
        ),
        _buildSimpleNutrientCard(
          icon: '🫙',
          label: 'Fat',
          value: nutrition['total_fat'],
          dailyValue: 78,
          unit: 'g',
          lowLabel: 'Low fat ✓',
          medLabel: 'Some fat',
          highLabel: 'High fat!',
        ),
        _buildSimpleNutrientCard(
          icon: '🌾',
          label: 'Carbohydrates',
          value: nutrition['carbohydrates'],
          dailyValue: 275,
          unit: 'g',
          lowLabel: 'Low carbs',
          medLabel: 'Some carbs',
          highLabel: 'High carbs!',
        ),
      ],
    );
  }

  // Simple nutrient card with traffic light
  Widget _buildSimpleNutrientCard({
    required String icon,
    required String label,
    required dynamic value,
    required int dailyValue,
    required String unit,
    required String lowLabel,
    required String medLabel,
    required String highLabel,
    bool isGoodHigh = false,
  }) {
    if (value == null) return SizedBox.shrink();

    double percent = (value / dailyValue) * 100;

    // Traffic light colors
    Color lightColor;
    String statusLabel;
    Color bgColor;

    if (isGoodHigh) {
      // For protein — high is good
      if (percent > 30) {
        lightColor = Colors.green;
        statusLabel = highLabel;
        bgColor = Colors.green.withOpacity(0.05);
      } else if (percent > 10) {
        lightColor = Colors.orange;
        statusLabel = medLabel;
        bgColor = Colors.orange.withOpacity(0.05);
      } else {
        lightColor = Colors.red;
        statusLabel = lowLabel;
        bgColor = Colors.red.withOpacity(0.05);
      }
    } else {
      if (percent > 50) {
        lightColor = Colors.red;
        statusLabel = highLabel;
        bgColor = Colors.red.withOpacity(0.05);
      } else if (percent > 20) {
        lightColor = Colors.orange;
        statusLabel = medLabel;
        bgColor = Colors.orange.withOpacity(0.05);
      } else {
        lightColor = Colors.green;
        statusLabel = lowLabel;
        bgColor = Colors.green.withOpacity(0.05);
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bgColor,
        border: Border.all(color: lightColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Icon
          Text(icon, style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),

          // Label and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(lightColor),
                    minHeight: 6,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: lightColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 12),

          // Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value$unit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: lightColor,
                ),
              ),
              Text(
                'Recommended: $dailyValue$unit/day',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          SizedBox(width: 8),

          // Traffic light dot
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lightColor,
            ),
          ),
        ],
      ),
    );
  }

  // Warnings section
  Widget _buildWarningsSection(List<String> warnings) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color(0xFFFFF5F5),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('⚠️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Health Warnings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...warnings.map((warning) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔴',
                        style: TextStyle(fontSize: 12)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // Alternatives section
  Widget _buildAlternativesSection(List<dynamic> alternatives) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💚 Healthier Jamaican Options',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Try these instead',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        SizedBox(height: 12),
        ...alternatives.asMap().entries.map((entry) {
          var alt = entry.value;
          Map<String, dynamic> product = {};
           if (alt is Map) {
            product = Map<String, dynamic>.from(alt);
          } else if (alt is String) {
            product = {'product': alt, 'brand': '', 'why': '', 'calories': 'N/A'};
          } else {
            return SizedBox.shrink();
          }

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Green check circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2D6A4F).withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text('✅',
                        style: TextStyle(fontSize: 20)),
                  ),
                ),
                SizedBox(width: 12),

                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['product'] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        'by ${product['brand'] ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        product['why'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2D6A4F),
                        ),
                      ),
                    ],
                  ),
                ),

                // Calories
                Column(
                  children: [
                    Text(
                      '${product['calories'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D6A4F),
                      ),
                    ),
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Full details section (collapsible)
  Widget _buildFullDetailsSection(Map nutrition) {
    return ExpansionTile(
      title: Text(
        '📋 See Full Nutrition Details',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D6A4F),
        ),
      ),
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDetailRow('Calories',
                  '${nutrition['calories'] ?? 'N/A'} kcal'),
              _buildDetailRow('Total Fat',
                  '${nutrition['total_fat'] ?? 'N/A'} g'),
              _buildDetailRow('Saturated Fat',
                  '${nutrition['saturated_fat'] ?? 'N/A'} g'),
              _buildDetailRow('Trans Fat',
                  '${nutrition['trans_fat'] ?? 'N/A'} g'),
              _buildDetailRow('Cholesterol',
                  '${nutrition['cholesterol'] ?? 'N/A'} mg'),
              _buildDetailRow('Sodium',
                  '${nutrition['sodium'] ?? 'N/A'} mg'),
              _buildDetailRow('Carbohydrates',
                  '${nutrition['carbohydrates'] ?? 'N/A'} g'),
              _buildDetailRow(
                  'Fiber', '${nutrition['fiber'] ?? 'N/A'} g'),
              _buildDetailRow(
                  'Sugar', '${nutrition['sugar'] ?? 'N/A'} g'),
              _buildDetailRow('Protein',
                  '${nutrition['protein'] ?? 'N/A'} g'),
              _buildDetailRow('Vitamin D',
                  '${nutrition['vitamin_d'] ?? 'N/A'} mcg'),
              _buildDetailRow('Calcium',
                  '${nutrition['calcium'] ?? 'N/A'} mg'),
              _buildDetailRow(
                  'Iron', '${nutrition['iron'] ?? 'N/A'} mg'),
              _buildDetailRow('Potassium',
                  '${nutrition['potassium'] ?? 'N/A'} mg'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[700])),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}