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

  Future<void> fetchBalance(String userId, String token, {Map<String, String>? headers}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '/api/v1/wallet/users/$userId?type=passenger',
        token: token,
        extraHeaders: headers,
      );

      if (response.statusCode == 200) {
        print('Wallet Debug: Response body: ${response.body}');
        final data = jsonDecode(response.body);
        _balance = data['balance']?.toString();
        _walletId = (data['id'] ?? data['wallet_id'])?.toString();
        print('Wallet Debug: Extracted Balance: $_balance, WalletID: $_walletId');
      } else if (response.statusCode == 404) {
        print('Wallet Debug: Wallet not found for UserID: $userId');
        _balance = '0.00';
      } else {
        print('Wallet Debug: Error response: ${response.body}');
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
    required String walletId,
    required double amount,
    String? phone,
    String? email,
    required String token,
  }) async {
    print('Wallet Debug: Initiating topup for $walletId with amount $amount');
    final response = await ApiService.put(
      '/api/v1/wallet/$walletId/topup',
      {
        'amount': amount,
        'phone_number': phone,
        'email': email,
        'message': 'Wallet topup',
      },
      token: token,
    );

    if (response.statusCode == 200) {
      print('Wallet Debug (topup): Response body: ${response.body}');
      final data = jsonDecode(response.body);
      return data['checkout_url'];
    } else {
      print('Wallet Debug (topup): Error response: ${response.body}');
      final error = jsonDecode(response.body)['message'] ?? 'Failed to initiate top-up';
      throw Exception(error);
    }
  }

  Future<void> pollBalanceChange(String userId, String token) async {
    final oldBalance = double.tryParse(_balance ?? '0') ?? 0.0;
    print('Wallet Debug: Starting poll. Old balance: $oldBalance, UserID: $userId');
    int attempts = 0;
    while (attempts < 24) { // 2 minutes max (5s * 24)
      print('Wallet Debug: Polling attempt ${attempts + 1}/24...');
      await fetchBalance(userId, token);
      final newBalance = double.tryParse(_balance ?? '0') ?? 0.0;
      print('Wallet Debug: Current balance: $newBalance');
      
      if (newBalance > oldBalance) {
        print('Wallet Debug: Balance INCREASE detected!');
        break;
      }
      await Future.delayed(const Duration(seconds: 5));
      attempts++;
    }
    if (attempts >= 24) {
      print('Wallet Debug: Polling timed out without detecting a change.');
    }
  }

  Future<void> fetchTransactions(String userId, String token, {String? reason, String? status, String? sort, Map<String, String>? headers}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> allTx = [];
      
      // Try the direct payments endpoint with payer_user_id filter (based on backend code)
      try {
        final respPayments = await ApiService.get('/api/v1/payments/transactions?payer_user_id=$userId', token: token, extraHeaders: headers);
        if (respPayments.statusCode == 200) {
          final data = jsonDecode(respPayments.body);
          allTx.addAll(data is List ? data : (data['data'] ?? data['items'] ?? []));
        } else {
          print('Wallet Debug: Direct Payments (payer_user_id) failed: ${respPayments.body}');
        }
      } catch (e) {
        print('Wallet Debug: Direct Payments catch: $e');
      }

      // If that failed, try the wallet proxy as a secondary fallback
      if (allTx.isEmpty) {
        try {
          final respSent = await ApiService.get('/api/v1/wallet/transactions?sender_wallet_id=$_walletId', token: token, extraHeaders: headers);
          if (respSent.statusCode == 200) {
            final data = jsonDecode(respSent.body);
            allTx.addAll(data is List ? data : (data['data'] ?? []));
          }
        } catch (e) {
          print('Wallet Debug: Wallet Proxy failed: $e');
        }
      }

      // Sort and update
      allTx.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      _transactions = allTx;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Wallet Debug (tx): Final Error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> fetchTransactionDetail(String txId, String token) async {
    final response = await ApiService.get('/api/v1/wallet/transactions?sender_wallet_id=$_walletId&transaction_id=$txId', token: token);
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
        '/api/v1/wallet/transfer', // Updated to go through public wallet proxy if available
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
