import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WalletProvider with ChangeNotifier {
  String? _balance;
  String? _walletId;
  bool _isLoading = false;
  bool _isTransferring = false;

  String? get balance => _balance;
  String? get walletId => _walletId;
  bool get isLoading => _isLoading;
  bool get isTransferring => _isTransferring;
  List<dynamic> _transactions = [];
  List<dynamic> get transactions => _transactions;

  Future<void> fetchBalance(String userId, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/wallet/users/$userId?type=passenger',
        token: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _balance = data['balance'];
        _walletId = data['id'].toString();
      } else {
        throw Exception('Failed to fetch balance');
      }
    } catch (e) {
      debugPrint('Error fetching balance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  Future<String> initiateTopup({
    required String userId,
    required double amount,
    required String phone,
    required String firstName,
    required String lastName,
    required String token,
  }) async {
    final response = await ApiService.post(
      '/payment/api/v1/payments/initiate',
      {
        'amount': amount,
        'reason': 'wallet topup',
        'payer_user_id': userId,
        'phone_number': phone,
        'first_name': firstName,
        'last_name': lastName,
      },
      token: token,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['checkout_url'];
    } else {
      final error = jsonDecode(response.body)['message'] ?? 'Failed to initiate top-up';
      throw Exception(error);
    }
  }

  Future<void> pollBalanceChange(String userId, String token) async {
    final oldBalance = double.tryParse(_balance ?? '0') ?? 0.0;
    int attempts = 0;
    while (attempts < 12) { // 1 minute max (5s * 12)
      await fetchBalance(userId, token);
      final newBalance = double.tryParse(_balance ?? '0') ?? 0.0;
      if (newBalance > oldBalance) break;
      await Future.delayed(const Duration(seconds: 5));
      attempts++;
    }
  }

  Future<void> fetchTransactions(String userId, String token, {String? reason, String? status, String? sort}) async {
    _isLoading = true;
    notifyListeners();

    try {
      String url = '/payment/transactions?payer_user_id=$userId';
      if (reason != null) url += '&reason=$reason';
      if (status != null) url += '&status=$status';
      if (sort != null) url += '&sort=$sort';
      
      final response = await ApiService.get(url, token: token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _transactions = data['items'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> fetchTransactionDetail(String txId, String token) async {
    final response = await ApiService.get('/payment/api/v1/payments/receipts/$txId', token: token);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch transaction detail');
    }
  }

  Future<void> transferFunds({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required String recipientName,
    String? message,
    required String token,
  }) async {
    _isTransferring = true;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/payment/api/v1/payments/transfer',
        {
          'sender_wallet_id': fromWalletId,
          'receiver_wallet_id': toWalletId,
          'amount': amount,
          'recipient_name': recipientName,
          'reason': message ?? 'P2P Transfer',
        },
        token: token,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body)['message'] ?? 'Transfer failed';
        throw Exception(error);
      }
    } finally {
      _isTransferring = false;
      notifyListeners();
    }
  }
}
