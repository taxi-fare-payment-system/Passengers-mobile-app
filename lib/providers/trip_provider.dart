import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TripProvider with ChangeNotifier {
  List<dynamic> _routes = [];
  bool _isLoading = false;
  List<dynamic> _vehicles = [];
  List<dynamic> _tripHistory = [];
  Map<String, dynamic>? _vehicleDetails;
  Map<String, dynamic>? _currentTrip;
  Timer? _pollingTimer;

  List<dynamic> get routes => _routes;
  List<dynamic> get tripHistory => _tripHistory;
  bool get isLoading => _isLoading;
  List<dynamic> get vehicles => _vehicles;
  Map<String, dynamic>? get vehicleDetails => _vehicleDetails;
  Map<String, dynamic>? get currentTrip => _currentTrip;

  void startTripPolling(String tripId, String token, {Map<String, String>? headers}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchTripStatus(tripId, token, headers: headers);
    });
  }

  void stopTripPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchRoutes(String token, {Map<String, String>? headers}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/api/v1/routes', token: token, extraHeaders: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _routes = data['items'] ?? [];
      } else {
        print('Trip Debug: Error fetching routes: ${response.body}');
        throw Exception('Failed to fetch routes');
      }
    } catch (e) {
      debugPrint('Error fetching routes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchVehiclesForRoute(String routeId, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/api/v1/routes/$routeId/vehicles', token: token);
      if (response.statusCode == 200) {
        _vehicles = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTrip(Map<String, dynamic> tripData, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/api/v1/trips', tripData, token: token);
      if (response.statusCode == 201) {
        _currentTrip = jsonDecode(response.body);
        if (_currentTrip != null && _currentTrip!['id'] != null) {
          startTripPolling(_currentTrip!['id'].toString(), token);
        }
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to create trip');
      }
    } catch (e) {
      debugPrint('Error creating trip: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTripStatus(String tripId, String token, {Map<String, String>? headers}) async {
    try {
      final response = await ApiService.get('/api/v1/trips/$tripId', token: token, extraHeaders: headers);
      if (response.statusCode == 200) {
        final newTrip = jsonDecode(response.body);
        _currentTrip = newTrip;
        
        // Fetch route details if not included in the trip response
        if (_currentTrip != null && _currentTrip!['route'] == null && _currentTrip!['route_id'] != null) {
          final routeResp = await ApiService.get('/api/v1/routes/${_currentTrip!['route_id']}', token: token, extraHeaders: headers);
          if (routeResp.statusCode == 200) {
            _currentTrip!['route'] = jsonDecode(routeResp.body);
          }
        }
        
        if (newTrip != null && newTrip['vehicle_id'] != null) {
          fetchVehicleDetails(newTrip['vehicle_id'].toString(), token, headers: headers);
        }
        
        // Stop polling if trip is finished
        if (newTrip['status'] == 'COMPLETED' || newTrip['status'] == 'CANCELLED') {
          stopTripPolling();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching trip status: $e');
    }
  }

  Future<void> fetchVehicleDetails(String vehicleId, String token, {Map<String, String>? headers}) async {
    try {
      final response = await ApiService.get('/api/v1/vehicles/$vehicleId', token: token, extraHeaders: headers);
      if (response.statusCode == 200) {
        _vehicleDetails = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching vehicle details: $e');
    }
  }

  Future<String> payFare({
    required String tripId,
    required double amount,
    required String walletId,
    required String driverId,
    required String token,
    Map<String, String>? headers,
  }) async {
    print('Trip Debug: Initiating payment for Trip: $tripId, Amount: $amount');
    final response = await ApiService.post(
      '/api/v1/trips/$tripId/payments/initiate',
      {
        'amount': amount,
        'wallet_id': walletId,
        'driver_id': driverId,
        'message': 'Fare payment for trip $tripId',
      },
      token: token,
      extraHeaders: headers,
    );

    if (response.statusCode == 200) {
      print('Trip Debug: Payment successful: ${response.body}');
      final data = jsonDecode(response.body);
      return data['transactionId'] ?? data['transaction_id'];
    } else {
      print('Trip Debug: Payment failed status ${response.statusCode}: ${response.body}');
      final error = jsonDecode(response.body)['message'] ?? 'Payment failed';
      throw Exception(error);
    }
  }

  Future<double> fetchPriceQuote({
    required String tripId,
    required int destinationStopIndex,
    required String token,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await ApiService.post(
        '/api/v1/trips/$tripId/quotes/price',
        {
          'destinationStopIndex': destinationStopIndex,
        },
        token: token,
        extraHeaders: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['price'] as num).toDouble();
      } else {
        throw Exception('Failed to get price quote');
      }
    } catch (e) {
      debugPrint('Error fetching price quote: $e');
      rethrow;
    }
  }

  Future<void> fetchTripHistory(String token, {Map<String, String>? headers}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/api/v1/trips/history', token: token, extraHeaders: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _tripHistory = data['items'] ?? [];
        print('Trip Debug: Fetched ${_tripHistory.length} history items');
      } else {
        print('Trip Debug: History error: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching trip history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
