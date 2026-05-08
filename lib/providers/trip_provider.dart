import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TripProvider with ChangeNotifier {
  List<dynamic> _routes = [];
  bool _isLoading = false;
  List<dynamic> _vehicles = [];
  Map<String, dynamic>? _vehicleDetails;
  Map<String, dynamic>? _currentTrip;
  Timer? _pollingTimer;

  List<dynamic> get routes => _routes;
  bool get isLoading => _isLoading;
  List<dynamic> get vehicles => _vehicles;
  Map<String, dynamic>? get vehicleDetails => _vehicleDetails;
  Map<String, dynamic>? get currentTrip => _currentTrip;

  void startTripPolling(String tripId, String token) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchTripStatus(tripId, token);
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

  Future<void> fetchRoutes(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/routes/routes', token: token);
      if (response.statusCode == 200) {
        _routes = jsonDecode(response.body);
      } else {
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
      final response = await ApiService.get('/routes/routes/$routeId/vehicles', token: token);
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
      final response = await ApiService.post('/trip/trips', tripData, token: token);
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

  Future<void> fetchTripStatus(String tripId, String token) async {
    try {
      final response = await ApiService.get('/trip/trips/$tripId', token: token);
      if (response.statusCode == 200) {
        final newTrip = jsonDecode(response.body);
        _currentTrip = newTrip;
        
        if (newTrip != null && newTrip['vehicle_id'] != null) {
          fetchVehicleDetails(newTrip['vehicle_id'].toString(), token);
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

  Future<void> fetchVehicleDetails(String vehicleId, String token) async {
    try {
      final response = await ApiService.get('/vehicle/vehicles/$vehicleId', token: token);
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
    required String userId,
    required String phone,
    required String token,
  }) async {
    final response = await ApiService.post(
      '/payment/api/v1/payments/initiate',
      {
        'amount': amount,
        'reason': 'fare',
        'trip_id': tripId,
        'payer_user_id': userId,
        'phone_number': phone,
        'first_name': 'Passenger', // Placeholder
        'last_name': 'User',
      },
      token: token,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['transaction_id'];
    } else {
      final error = jsonDecode(response.body)['message'] ?? 'Payment failed';
      throw Exception(error);
    }
  }

  Future<double> fetchPriceQuote({
    required String tripId,
    required int destinationStopIndex,
    required String token,
  }) async {
    try {
      final response = await ApiService.post(
        '/trip/trips/$tripId/quotes/price',
        {
          'destinationStopIndex': destinationStopIndex,
        },
        token: token,
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
}
