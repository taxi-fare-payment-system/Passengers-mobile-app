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

  Future<void> fetchTransactions(String userId, String token, {Map<String, String>? headers}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/api/v1/wallet/transactions?limit=50', token: token, extraHeaders: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> allTx = data is List ? data : (data['data'] ?? data['items'] ?? []);
        
        // Sort and update
        allTx.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });

        _transactions = allTx;
        print('Wallet Debug: Fetched ${_transactions.length} transactions');
      } else {
        print('Wallet Debug: Transaction fetch failed status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Wallet Debug (tx): Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> fetchTransactionDetail(String txId, String token) async {
    final response = await ApiService.get('/api/v1/wallet/transactions/$txId', token: token);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is Map ? data : (data['data'] ?? data);
    } else {
      throw Exception('Failed to fetch transaction detail');
    }
  }

  Future<void> transferFunds({
    required String fromWalletId,
    String? toWalletId,
    String? recipientPhone,
    required double amount,
    String? recipientName,
    String? message,
    required String token,
    String? userId,
  }) async {
    _isTransferring = true;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/api/v1/wallet/transfers',
        {
          'amount': amount,
          'payer_user_id': userId,
          'sender_wallet_id': fromWalletId,
          if (toWalletId != null) 'receiver_wallet_id': toWalletId,
          if (recipientPhone != null) 'receiver_phone': recipientPhone,
          if (recipientName != null) 'receiver_full_name': recipientName,
          'message': message ?? 'P2P Transfer',
        },
        token: token,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body)['message'] ?? 'Transfer failed';
        throw Exception(error);
      }
    } finally {
      _isTransferring = false;
      notifyListeners();
    }
  }
}
