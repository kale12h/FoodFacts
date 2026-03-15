import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _scans = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getScanHistory();
    setState(() {
      _isLoading = false;
      if (result.containsKey('error')) {
        _errorMessage = result['error'];
      } else {
        _scans = result['scans'] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text('Scan History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF2D6A4F)))
          : _errorMessage != null
              ? _buildError()
              : _buildHistory(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 16),
          Text('Could not load history',
              style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadHistory,
            style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2D6A4F)),
            child: Text('Retry',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_scans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📋', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'No scans yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your scan history will appear here',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: Color(0xFF2D6A4F),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _scans.length,
        itemBuilder: (context, index) {
          final scan = _scans[index];
          return _buildScanCard(scan);
        },
      ),
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan) {
    final healthScore = scan['health_score'] ?? 0;
    final productName = scan['product_name'] ?? 'Unknown Product';
    final scannedAt = scan['scanned_at'] ?? '';
    final calories = scan['calories'] ?? 0;
    final sugar = scan['sugar'] ?? 0;
    final sodium = scan['sodium'] ?? 0;

    Color scoreColor;
    String scoreEmoji;
    if (healthScore >= 75) {
      scoreColor = Color(0xFF2D6A4F);
      scoreEmoji = '😊';
    } else if (healthScore >= 50) {
      scoreColor = Colors.orange;
      scoreEmoji = '😐';
    } else {
      scoreColor = Colors.red;
      scoreEmoji = '😟';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              color: scoreColor.withOpacity(0.05),
            ),
            child: Row(
              children: [
                Text(scoreEmoji, style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        _formatDate(scannedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: scoreColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$healthScore/100',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Nutrient summary
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMiniNutrient('🔥', 'Calories',
                    '$calories kcal'),
                _buildDivider(),
                _buildMiniNutrient(
                    '🍬', 'Sugar', '${sugar}g'),
                _buildDivider(),
                _buildMiniNutrient(
                    '🧂', 'Sodium', '${sodium}mg'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniNutrient(
      String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: 16)),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[200],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}