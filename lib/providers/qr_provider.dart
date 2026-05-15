import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class QRProvider with ChangeNotifier {
  bool _isValidating = false;
  bool get isValidating => _isValidating;

  Future<bool> verifyQRCode(String qrCode, String token, {Map<String, String>? headers}) async {
    _isValidating = true;
    notifyListeners();

    try {
      // URL encode the QR code as required by documentation
      final encodedQR = Uri.encodeComponent(qrCode);
      final response = await ApiService.get(
        '/api/v1/qr/verify/$encodedQR',
        token: token,
        extraHeaders: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['valid'] ?? false;
      }
      return false;
    } catch (e) {
      print('QR Debug: Verification failed: $e');
      return false;
    } finally {
      _isValidating = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getDriverFromQR(String qrCode, String token, {Map<String, String>? headers}) async {
    // Usually the QR code contains the driver_id or a reference to it
    // For this implementation, we assume the QR data IS the driver ID if verified
    return {
      'driver_id': qrCode.split('/').last,
      'scanned_at': DateTime.now().toIso8601String(),
    };
  }
}
