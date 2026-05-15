import 'dart:convert';
import 'package:http/http.dart' as http;
class ApiService {
  static const String baseUrl = 'https://api-gateway-production-0bf2.up.railway.app';

  static Future<http.Response> get(String endpoint, {String? token}) async {
    print('API GET: $endpoint');
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    print('API GET Response [$endpoint]: ${response.statusCode} - ${response.body}');
    return response;
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
    print('API POST: $endpoint Body: $body');
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    print('API POST Response [$endpoint]: ${response.statusCode} - ${response.body}');
    return response;
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body, {String? token}) async {
    print('API PATCH: $endpoint Body: $body');
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    print('API PATCH Response [$endpoint]: ${response.statusCode} - ${response.body}');
    return response;
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body, {String? token}) async {
    print('API PUT: $endpoint Body: $body');
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    print('API PUT Response [$endpoint]: ${response.statusCode} - ${response.body}');
    return response;
  }
}
