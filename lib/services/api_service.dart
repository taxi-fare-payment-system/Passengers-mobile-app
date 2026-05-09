import 'dart:convert';
import 'package:http/http.dart' as http;
class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080';

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

  static Future<http.Response> put(String path, Map<String, dynamic> data, {String? token}) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await http.put(
      url,
      headers: headers,
      body: jsonEncode(data),
    );
  }
}
