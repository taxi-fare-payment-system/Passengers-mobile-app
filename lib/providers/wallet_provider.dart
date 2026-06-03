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

  Future<String?> getWalletByUserId(String userId, String type, String token, {Map<String, String>? headers}) async {
    try {
      final response = await ApiService.get(
        '/api/v1/wallet/users/$userId?type=$type',
        token: token,
        extraHeaders: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['id'] ?? data['wallet_id'])?.toString();
      }
    } catch (e) {
      debugPrint('Error getting wallet for user $userId: $e');
    }
    return null;
  }

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

  Future<bool> pollBalanceChange(String userId, String token) async {
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
        return true;
      }
      await Future.delayed(const Duration(seconds: 5));
      attempts++;
    }
    if (attempts >= 24) {
      print('Wallet Debug: Polling timed out without detecting a change.');
    }
    return false;
  }

  Future<void> fetchTransactions(String userId, String token, {Map<String, String>? headers}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/api/v1/wallet/transactions?limit=50', token: token, extraHeaders: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> allTx = List.from(data is List ? data : (data['data'] ?? data['items'] ?? []));
        
        // Sort first
        allTx.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });

        // Match individual fare payments with their corresponding fee (created at the same time)
        final Set<String> feeIdsToSkip = {};
        final Map<String, double> fareExtraFees = {};
        
        for (var tx in allTx) {
          final msg = (tx['message'] ?? '').toString().toLowerCase();
          if (msg.contains('fare payment') && tx['trip_id'] != null) {
             for (var otherTx in allTx) {
                final otherMsg = (otherTx['message'] ?? '').toString().toLowerCase();
                if (otherMsg.contains('platform fee') && otherTx['trip_id'] == tx['trip_id']) {
                   final date1 = DateTime.tryParse(tx['created_at']?.toString() ?? '') ?? DateTime.now();
                   final date2 = DateTime.tryParse(otherTx['created_at']?.toString() ?? '') ?? DateTime.now();
                   if (date1.difference(date2).inSeconds.abs() <= 5 && !feeIdsToSkip.contains(otherTx['id'])) {
                       feeIdsToSkip.add(otherTx['id']);
                       fareExtraFees[tx['id']] = double.tryParse(otherTx['amount']?.toString() ?? '0') ?? 0;
                       break; 
                   }
                }
             }
          }
        }

        final List<dynamic> finalTxs = [];
        for (var tx in allTx) {
           if (feeIdsToSkip.contains(tx['id'])) continue;
           
           final newTx = Map<String, dynamic>.from(tx);
           if (fareExtraFees.containsKey(tx['id'])) {
               final amt = double.tryParse(newTx['amount']?.toString() ?? '0') ?? 0;
               final fee = fareExtraFees[tx['id']]!;
               
               // Show decimal only if necessary
               final total = amt + fee;
               newTx['amount'] = total == total.toInt() ? total.toInt().toString() : total.toStringAsFixed(2);
           }
           finalTxs.add(newTx);
        }

        _transactions = finalTxs;
      } else {
        print('Wallet Debug: Transaction fetch failed status ${response.statusCode}: ${response.body}');
        _transactions = [];
      }
    } catch (e) {
      print('Wallet Debug (tx): Error fetching transactions: $e');
      _transactions = [];
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
    required String toPhoneNumber,
    required double amount,
    String? message,
    required String token,
  }) async {
    _isTransferring = true;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/api/v1/wallet/$fromWalletId/transfer',
        {
          'amount': amount,
          'to_phone_number': toPhoneNumber,
          'message': message ?? 'P2P Transfer',
        },
        token: token,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body)['message'] ?? 'Transfer failed';
        throw Exception(error);
      }
      
      // Auto-refresh wallet after success
      final userId = jsonDecode(response.body)['payer_user_id']?.toString() ?? '';
      if (userId.isNotEmpty) {
        await refreshWallet(userId, token);
      }
    } finally {
      _isTransferring = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> payFare({
    required String walletId,
    required double amount,
    required String driverWalletId,
    required String tripId,
    required String receiverFullName,
    int? subCityId,
    String? assistantId,
    String? message,
    required String token,
  }) async {
    final response = await ApiService.put(
      '/api/v1/wallet/$walletId/pay-fare',
      {
        'amount': amount,
        'driver_wallet_id': driverWalletId,
        'trip_id': tripId,
        'receiver_full_name': receiverFullName,
        if (subCityId != null) 'sub_city_id': subCityId,
        if (assistantId != null) 'assistant_id': assistantId,
        'message': message ?? 'Trip payment',
      },
      token: token,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['message'] ?? 'Fare payment failed';
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> withdraw({
    required String walletId,
    required double amount,
    required String accountName,
    required String accountNumber,
    required String bankCode,
    String? withdrawalReference,
    String? message,
    required String token,
    Map<String, String>? headers,
  }) async {
    final response = await ApiService.put(
      '/api/v1/wallet/$walletId/withdraw',
      {
        'amount': amount,
        'account_name': accountName,
        'account_number': accountNumber,
        'bank_code': bankCode,
        if (withdrawalReference != null) 'withdrawal_reference': withdrawalReference,
        'message': message ?? 'Wallet withdrawal',
      },
      token: token,
      extraHeaders: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['message'] ?? 'Withdrawal failed';
      throw Exception(error);
    }
  }

  Future<void> refreshWallet(String userId, String token) async {
    await fetchBalance(userId, token);
    await fetchTransactions(userId, token);
  }
}
