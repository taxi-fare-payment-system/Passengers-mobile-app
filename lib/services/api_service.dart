import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Using 10.0.2.2 for Android Emulator to reach localhost
  // For physical devices or other platforms, use your machine's IP address.
  static const String baseUrl = 'http://10.0.2.2:8080'; // Gateway port

  static Future<http.Response> post(String path, Map<String, dynamic> data, {String? token}) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> get(String path, {String? token}) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await http.get(url, headers: headers);
  }

  static Future<http.Response> patch(String path, Map<String, dynamic> data, {String? token}) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await http.patch(
      url,
      headers: headers,
      body: jsonEncode(data),
    );
  }
}
