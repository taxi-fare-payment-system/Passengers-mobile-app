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
  List<dynamic> _nextStops = [];
  Timer? _pollingTimer;

  List<dynamic> get routes => _routes;
  List<dynamic> get tripHistory => _tripHistory;
  bool get isLoading => _isLoading;
  List<dynamic> get vehicles => _vehicles;
  Map<String, dynamic>? get vehicleDetails => _vehicleDetails;
  Map<String, dynamic>? get currentTrip => _currentTrip;
  List<dynamic> get nextStops => _nextStops;

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

  Future<void> fetchActiveTripByDriver(String driverId, String token, {Map<String, String>? headers}) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Find active trip for this driver
      final response = await ApiService.get('/api/v1/trips/drivers/$driverId/active', token: token, extraHeaders: headers);
      if (response.statusCode == 200) {
        final tripData = jsonDecode(response.body);
        _currentTrip = tripData;
        
        // Fetch vehicle details too
        final vId = tripData['vehicle_id'] ?? tripData['vehicleId'];
        if (vId != null) {
          fetchVehicleDetails(vId.toString(), token, headers: headers);
        }
        
        // Fetch route details if missing
        final rId = _currentTrip!['routeId'] ?? _currentTrip!['route_id'];
        if (_currentTrip != null && _currentTrip!['route'] == null && rId != null) {
          print('Trip Debug: Fetching route details for $rId');
          final routeResp = await ApiService.get('/api/v1/routes/$rId', token: token, extraHeaders: headers);
          if (routeResp.statusCode == 200) {
            final routeDetails = jsonDecode(routeResp.body);
            // Enrich with baseFare from cached routes if available
            final cachedRoute = _routes.firstWhere((r) => r['id'] == rId, orElse: () => null);
            if (cachedRoute != null && cachedRoute['baseFare'] != null) {
              routeDetails['baseFare'] = cachedRoute['baseFare'];
            }
            _currentTrip!['route'] = routeDetails;
            print('Trip Debug: Route details fetched successfully');
          } else {
            print('Trip Debug: Failed to fetch route details status ${routeResp.statusCode}');
          }
        }
        
        notifyListeners();
      } else {
        throw Exception('No active trip found for this driver');
      }
    } catch (e) {
      debugPrint('Error fetching active trip by driver: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNextStops(String tripId, String token, {Map<String, String>? headers}) async {
    try {
      print('Trip Debug: Fetching next stops for $tripId');
      final response = await ApiService.get('/api/v1/trips/$tripId/stops/next', token: token, extraHeaders: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _nextStops = data['stops'] ?? [];
        print('Trip Debug: Fetched ${_nextStops.length} next stops');
        notifyListeners();
      } else {
        print('Trip Debug: Next stops fetch failed status ${response.statusCode}: ${response.body}');
        _nextStops = [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching next stops: $e');
      _nextStops = [];
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
        
        final vId = newTrip?['vehicle_id'] ?? newTrip?['vehicleId'];
        if (vId != null) {
          fetchVehicleDetails(vId.toString(), token, headers: headers);
        } else if (newTrip?['driver_id'] != null || newTrip?['driverId'] != null) {
          // Fallback: Fetch vehicle assigned to driver
          final dId = newTrip?['driver_id'] ?? newTrip?['driverId'];
          _fetchVehicleByDriver(dId.toString(), token, headers: headers);
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

  Future<void> _fetchVehicleByDriver(String driverId, String token, {Map<String, String>? headers}) async {
    try {
      final response = await ApiService.get('/api/v1/vehicles/drivers/$driverId', token: token, extraHeaders: headers);
      if (response.statusCode == 200) {
        _vehicleDetails = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching vehicle by driver: $e');
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

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return (data['transactionId'] ?? data['transaction_id'])?.toString() ?? '';
    } else {
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
      print('Price quote error: $e');
      // Fallback to Base Fare if quote fails
      final baseFare = currentTrip?['route']?['baseFare'];
      if (baseFare != null) {
        return (baseFare as num).toDouble();
      }
      rethrow;
    }
  }

}
