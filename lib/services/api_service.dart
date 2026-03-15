import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const _storage = FlutterSecureStorage();

  // ─── Token Management ──────────────────────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // ─── Auth Headers ──────────────────────────────────
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Signup ────────────────────────────────────────
  static Future<Map<String, dynamic>> signup(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        await saveToken(data['token']);
      }
      return data;
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  // ─── Login ─────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        await saveToken(data['token']);
      }
      return data;
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  // ─── Logout ────────────────────────────────────────
  static Future<void> logout() async {
    await deleteToken();
  }

  // ─── Get Current User ──────────────────────────────
  static Future<Map<String, dynamic>> getMe() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  // ─── Save Health Profile ───────────────────────────
  static Future<Map<String, dynamic>> saveHealthProfile({
    required int age,
    required String gender,
    required double weightKg,
    required double heightCm,
    required String dietaryGoal,
    required List<String> healthConditions,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/health-profile'),
        headers: headers,
        body: jsonEncode({
          'age': age,
          'gender': gender,
          'weight_kg': weightKg,
          'height_cm': heightCm,
          'dietary_goal': dietaryGoal,
          'health_conditions': healthConditions,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  // ─── Get Health Conditions ─────────────────────────
  static Future<List<String>> getHealthConditions() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/health-profile'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (data['health_conditions'] != null) {
        return List<String>.from(data['health_conditions']);
      }
    } catch (e) {
      // Fall back to local storage
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('health_conditions');
    if (saved != null) {
      return List<String>.from(jsonDecode(saved));
    }
    return [];
  }

  // ─── Scan Label ────────────────────────────────────
  static Future<Map<String, dynamic>> scanNutritionLabel(
      File image) async {
    try {
      final token = await getToken();
      final conditions = await getHealthConditions();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/scan'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );

      request.fields['conditions'] = jsonEncode(conditions);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        return {'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  // ─── Get Daily Totals ──────────────────────────────
  static Future<Map<String, dynamic>> getDailyTotals() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/daily-totals'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }

  // ─── Get Scan History ──────────────────────────────
  static Future<Map<String, dynamic>> getScanHistory() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Connection failed: $e'};
    }
  }
}