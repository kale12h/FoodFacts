import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _dailyTotals = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDailyTotals();
  }

  Future<void> _loadDailyTotals() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getDailyTotals();
    setState(() {
      _isLoading = false;
      if (result.containsKey('error')) {
        _errorMessage = result['error'];
      } else {
        _dailyTotals = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text('Daily Nutrition',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDailyTotals,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF2D6A4F)))
          : _errorMessage != null
              ? _buildError()
              : _buildDashboard(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 16),
          Text('Could not load daily totals',
              style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadDailyTotals,
            style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2D6A4F)),
            child: Text('Retry',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final totalScans = _dailyTotals['total_scans'] ?? 0;
    final date = _dailyTotals['date'] ?? '';

    return RefreshIndicator(
      onRefresh: _loadDailyTotals,
      color: Color(0xFF2D6A4F),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF2D6A4F),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      color: Colors.white70, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "Today's Summary",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalScans scans',
                      style: TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // No scans yet
            if (totalScans == 0)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('🍽️',
                        style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text(
                      'No foods scanned today',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Scan a food label to start tracking',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else ...[
              // Calories big card
              _buildCaloriesCard(),
              SizedBox(height: 16),

              // Nutrient grid
              Text(
                'Nutrients Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildNutrientGridCard(
                    '🍬', 'Sugar',
                    _dailyTotals['sugar'] ?? 0,
                    50, 'g', Colors.pink,
                  ),
                  _buildNutrientGridCard(
                    '🧂', 'Sodium',
                    _dailyTotals['sodium'] ?? 0,
                    2300, 'mg', Colors.teal,
                  ),
                  _buildNutrientGridCard(
                    '🫙', 'Total Fat',
                    _dailyTotals['total_fat'] ?? 0,
                    78, 'g', Colors.orange,
                  ),
                  _buildNutrientGridCard(
                    '🌾', 'Carbs',
                    _dailyTotals['carbohydrates'] ?? 0,
                    275, 'g', Colors.purple,
                  ),
                  _buildNutrientGridCard(
                    '🥩', 'Protein',
                    _dailyTotals['protein'] ?? 0,
                    50, 'g', Colors.blue,
                  ),
                  _buildNutrientGridCard(
                    '🌿', 'Fiber',
                    _dailyTotals['fiber'] ?? 0,
                    28, 'g', Colors.green,
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Daily tips
              _buildDailyTips(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesCard() {
    final calories = _dailyTotals['calories'] ?? 0;
    final dailyCalories = 2000;
    final percent = (calories / dailyCalories).clamp(0.0, 1.0);
    final remaining = dailyCalories - calories;

    Color statusColor = remaining > 0 ? Color(0xFF2D6A4F) : Colors.red;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🔥', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'Calories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Spacer(),
              Text(
                '$calories / $dailyCalories kcal',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 12,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                remaining > 0
                    ? '${remaining} kcal remaining'
                    : '${(-remaining).toInt()} kcal over limit',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientGridCard(
    String emoji,
    String label,
    dynamic value,
    int dailyValue,
    String unit,
    Color color,
  ) {
    final numValue = (value is double) ? value : (value as num).toDouble();
    final percent = (numValue / dailyValue).clamp(0.0, 1.0);

    Color statusColor;
    if (label == 'Protein' || label == 'Fiber') {
      statusColor = percent > 0.5 ? Colors.green : color;
    } else {
      statusColor = percent > 0.75 ? Colors.red : color;
    }

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 18)),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '${numValue.toStringAsFixed(1)}$unit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 5,
            ),
          ),
          Text(
            'of ${dailyValue}$unit daily',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTips() {
    final sugar = (_dailyTotals['sugar'] ?? 0).toDouble();
    final sodium = (_dailyTotals['sodium'] ?? 0).toDouble();
    final calories = (_dailyTotals['calories'] ?? 0).toDouble();

    List<Map<String, String>> tips = [];

    if (sugar > 40) {
      tips.add({
        'emoji': '🍬',
        'tip': 'Your sugar intake is high today. Try drinking water instead of sugary drinks.'
      });
    }
    if (sodium > 1500) {
      tips.add({
        'emoji': '🧂',
        'tip': 'High sodium today. Avoid adding extra salt to your meals.'
      });
    }
    if (calories > 1800) {
      tips.add({
        'emoji': '🔥',
        'tip': 'You are close to your daily calorie limit. Choose lighter options.'
      });
    }
    if (tips.isEmpty) {
      tips.add({
        'emoji': '✅',
        'tip': 'Great job! Your nutrition looks balanced today. Keep it up!'
      });
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Today\'s Tips',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 12),
          ...tips.map((tip) => Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip['emoji']!,
                        style: TextStyle(fontSize: 18)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip['tip']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
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
}