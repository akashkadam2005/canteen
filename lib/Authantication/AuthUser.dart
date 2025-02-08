import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiHelper {
  // Singleton instance
  static final ApiHelper _instance = ApiHelper._internal();

  // Base URL
  final String baseUrl = 'http://192.168.175.172/CanteenAutomation/api/';

  // Image base URL
  final String imageBaseUrl = 'http://192.168.175.172/CanteenAutomation/uploads/';

  // Private constructor for singleton
  ApiHelper._internal();

  // Factory constructor to return the same instance
  factory ApiHelper() => _instance;

  // HTTP POST method
  Future<http.Response> httpPost(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  // HTTP GET method
  Future<http.Response> httpGet(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url);
  }

  // HTTP DELETE method
  Future<http.Response> httpDelete(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  // Helper method to get full image URL
  String getImageUrl(String imageName) {
      return '$imageBaseUrl$imageName';
    }
  }
