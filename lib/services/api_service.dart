import 'dart:convert';
import 'package:http/http.dart' as http;
class ApiService {
  static const String baseUrl = 'https://api-gateway-production-0bf2.up.railway.app';

  static Future<http.Response> get(String endpoint, {String? token, Map<String, String>? extraHeaders}) async {
    print('API GET: $endpoint');
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (extraHeaders != null) ...extraHeaders,
      },
    );
    print('API GET Response [$endpoint]: ${response.statusCode} - ${response.body}');
    return response;
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {String? token, Map<String, String>? extraHeaders}) async {
    print('API POST: $endpoint Body: $body');
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (extraHeaders != null) ...extraHeaders,
      },
      body: jsonEncode(body),
    );
    print('API POST Response [$endpoint]: ${response.statusCode} - ${response.body}');
    return response;
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body, {String? token, Map<String, String>? extraHeaders}) async {
    print('API PATCH: $endpoint Body: $body');
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (extraHeaders != null) ...extraHeaders,
      },
      body: jsonEncode(body),
    );
    print('API PATCH Response [$endpoint]: ${response.statusCode} - ${response.body}');
    return response;
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body, {String? token, Map<String, String>? extraHeaders}) async {
    print('API PUT: $endpoint Body: $body');
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (extraHeaders != null) ...extraHeaders,
      },
      body: jsonEncode(body),
    );
    print('API PUT Response [$endpoint]: ${response.statusCode} - ${response.body}');
    return response;
  }

  static Future<http.Response> delete(String endpoint, Map<String, dynamic> body, {String? token, Map<String, String>? extraHeaders}) async {
    print('API DELETE: $endpoint Body: $body');
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (extraHeaders != null) ...extraHeaders,
      },
      body: jsonEncode(body),
    );
    print('API DELETE Response [$endpoint]: ${response.statusCode} - ${response.body}');
    return response;
  }
}
