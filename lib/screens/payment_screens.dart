import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/qr_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/driver_provider.dart';
import '../utils/app_modals.dart';
import 'feedback_screens.dart';

class ConfirmPaymentScreen extends StatefulWidget {
  const ConfirmPaymentScreen({super.key});

  @override
  State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  int? _selectedStopIndex;
  bool _isLoadingStops = false;
  bool _isPaying = false;
  String? _error;

  String? _passengerPhone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        if (args['amount'] != null) {
          _amountController.text = args['amount'].toString();
        }
        _passengerPhone = args['passenger_phone']?.toString();
        _fetchStops(args['trip_id']?.toString());
      }
    });
  }

  Future<void> _fetchStops(String? qrCode) async {
    if (qrCode == null) return;
    setState(() => _isLoadingStops = true);
    try {
      final auth = context.read<AuthProvider>();
      final tripProvider = context.read<TripProvider>();
      final trimmedCode = qrCode.trim();
      
      // Check if the qrCode is already a valid UUID
      final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      final isUuid = uuidRegex.hasMatch(trimmedCode);
      
      if (isUuid) {
        // Fetch trip status to load currentTrip and fetch next stops directly
        await tripProvider.fetchTripStatus(trimmedCode, auth.token ?? '', headers: auth.headers);
        if (tripProvider.currentTrip != null) {
          await tripProvider.fetchNextStops(trimmedCode, auth.token ?? '', headers: auth.headers);
        } else {
          // If no trip was loaded, maybe the UUID represents a driver ID!
          // Fallback: Fetch active trip by driver ID
          await tripProvider.fetchActiveTripByDriver(trimmedCode, auth.token ?? '', headers: auth.headers);
          final realTripId = tripProvider.currentTrip?['id']?.toString();
          if (realTripId != null) {
            await tripProvider.fetchNextStops(realTripId, auth.token ?? '', headers: auth.headers);
          }
        }
      } else {
        // 1. Resolve Driver/Trip from QR
        final qrProvider = context.read<QRProvider>();
        final qrData = await qrProvider.getDriverFromQR(trimmedCode, auth.token ?? '', headers: auth.headers);
        final driverId = qrData?['driver_id'];
        
        if (driverId != null) {
          // 2. Get active trip for this driver to get the REAL UUID
          await tripProvider.fetchActiveTripByDriver(driverId, auth.token ?? '', headers: auth.headers);
          
          // 3. Use the real Trip UUID to fetch stops
          final realTripId = tripProvider.currentTrip?['id']?.toString();
          if (realTripId != null) {
            await tripProvider.fetchNextStops(realTripId, auth.token ?? '', headers: auth.headers);
          }
        }
      }
    } catch (e) {
      print('Error fetching stops: $e');
    } finally {
      setState(() => _isLoadingStops = false);
    }
  }

  Future<void> _handlePayment() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final tripProvider = context.read<TripProvider>();
    final tripId = tripProvider.currentTrip?['id']?.toString() ?? args?['trip_id']?.toString();
    if (tripId == null) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      _showPaymentAuthSheet(context, tripId);
      return;
    }

    setState(() {
      _isPaying = true;
      _error = null;
    });

    try {
      final wallet = context.read<WalletProvider>();
      
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) {
        setState(() {
          _isPaying = false;
        });
        if (mounted) {
          AppModals.showError(context, 'please_enter_valid_amount'.tr());
        }
        return;
      }
      
      if (_selectedStopIndex == null) {
        setState(() {
          _isPaying = false;
        });
        if (mounted) {
          AppModals.showError(context, 'please_select_destination'.tr());
        }
        return;
      }
      
      final txId = await tripProvider.payFare(
        tripId: tripId,
        amount: amount,
        walletId: wallet.walletId ?? '',
        driverId: (tripProvider.currentTrip?['driver_id'] ?? tripProvider.currentTrip?['driverId'])?.toString() ?? '',
        destinationStopIndex: _selectedStopIndex!,
        token: auth.token!,
        headers: auth.headers,
      );

      final userId = (auth.user?['id'] ?? auth.user?['user_id'])?.toString() ?? '';
      if (userId.isNotEmpty) {
        wallet.refreshWallet(userId, auth.token!);
        // Trigger notification and transaction refresh
        context.read<NotificationProvider>().fetchNotifications(auth.token!, headers: auth.headers);
        wallet.fetchTransactions(userId, auth.token!);
      }

      if (mounted) {
        final driverId = tripProvider.currentTrip?['driverId'] ?? tripProvider.currentTrip?['driver_id'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              transactionId: txId, 
              amount: amount,
              tripId: tripId,
              driverId: driverId,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isPaying = false;
      });
      
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      String displayMsg = errorMsg;
      if (errorMsg.toLowerCase().contains('insufficient balance') || 
          errorMsg.toLowerCase().contains('not enough') || 
          errorMsg.toLowerCase().contains('balance')) {
        displayMsg = 'insufficient_balance_msg'.tr();
      }
      
      if (mounted) {
        AppModals.showError(context, displayMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final auth = context.read<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('confirm_payment'.tr(), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBar: _isLoadingStops ? null : SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                  child: Text('cancel'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isPaying ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                  child: _isPaying
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                    : Text('pay_fare'.tr().toUpperCase(), style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoadingStops
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.accentColor),
                  const SizedBox(height: 24),
                  Text('fetching_trip_details'.tr(), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Driver Card
            if (tripProvider.currentTrip != null)
              GestureDetector(
                onTap: () {
                  final driverId = (tripProvider.currentTrip!['driver_id'] ?? tripProvider.currentTrip!['driverId'])?.toString();
                  if (driverId != null) {
                    Navigator.pushNamed(context, '/driver-profile', arguments: {'driverId': driverId});
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFF101828),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_taxi_rounded, color: AppTheme.accentColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tripProvider.currentTrip!['driverName'] ?? 'assigned_soon'.tr(),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                            ),
                            Text(
                              '${tripProvider.currentTrip!['route']?['start']?['metadata']?['name'] ?? '...'} → ${tripProvider.currentTrip!['route']?['end']?['metadata']?['name'] ?? '...'}',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Amount Input
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Text('enter_amount_currency'.tr(args: ['currency'.tr()]).toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color, letterSpacing: -2),
                    decoration: const InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '0.00',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            Text('where_getting_off'.tr().toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 16),
            
            // Stops Grid
            for (var stop in (tripProvider.nextStops.isNotEmpty 
              ? tripProvider.nextStops 
              : (tripProvider.currentTrip?['route']?['stops'] as List? ?? []))) 
                _StopItem(
                  stop: stop,
                  isSelected: _selectedStopIndex == (stop['stopIndex'] ?? stop['index'] ?? stop['sequence']),
                  onTap: () async {
                    final stopIndex = stop['stopIndex'] ?? stop['index'] ?? stop['sequence'];
                    setState(() => _selectedStopIndex = stopIndex as int?);
                    if (stop['amount'] != null) {
                      final parsedAmount = double.tryParse(stop['amount'].toString())?.toStringAsFixed(2) ?? stop['amount'].toString();
                      setState(() => _amountController.text = parsedAmount);
                    } else {
                      try {
                        final price = await tripProvider.fetchPriceQuote(
                          tripId: tripProvider.currentTrip?['id']?.toString() ?? (ModalRoute.of(context)?.settings.arguments as Map?)?['trip_id']?.toString() ?? '',
                          destinationStopIndex: stopIndex as int,
                          token: auth.token ?? '',
                          headers: auth.headers,
                        );
                        setState(() => _amountController.text = price.toStringAsFixed(2));
                      } catch (e) {
                        final baseFare = tripProvider.currentTrip?['route']?['baseFare'];
                        if (baseFare != null) {
                          final parsedBase = double.tryParse(baseFare.toString())?.toStringAsFixed(2) ?? baseFare.toString();
                          setState(() => _amountController.text = parsedBase);
                        }
                      }
                    }
                  },
                ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showPaymentAuthSheet(BuildContext context, String tripId) {
    final TextEditingController phoneController = TextEditingController(text: _passengerPhone ?? '');
    final TextEditingController passwordController = TextEditingController();
    bool isPasswordObscured = true;
    bool isAuthLoading = false;
    String? authError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final theme = Theme.of(context);
          final hasPhone = _passengerPhone != null && _passengerPhone!.isNotEmpty;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              top: 24,
              left: 32,
              right: 32,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'confirm_identity'.tr().toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  hasPhone
                      ? '${'enter_password_to_pay'.tr()} (+251 $_passengerPhone)'
                      : 'enter_phone_password_msg'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
                
                if (!hasPhone) ...[
                  const SizedBox(height: 24),
                  Text('phone_number'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                        ),
                        child: const Text('+251', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !isAuthLoading,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                          decoration: InputDecoration(
                            hintText: '91 234 5678',
                            fillColor: theme.cardColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Password field
                Text('password'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: isPasswordObscured,
                  enabled: !isAuthLoading,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    fillColor: theme.cardColor,
                    suffixIcon: IconButton(
                      icon: Icon(isPasswordObscured ? Icons.visibility_off : Icons.visibility, color: theme.hintColor),
                      onPressed: () => setSheetState(() => isPasswordObscured = !isPasswordObscured),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (authError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authError!,
                            style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                ElevatedButton(
                  onPressed: isAuthLoading
                      ? null
                      : () async {
                          var phone = phoneController.text.trim();
                          final password = passwordController.text.trim();
                          if (phone.isEmpty || password.isEmpty) return;

                          // Format phone to 0-prefixed if necessary
                          if (phone.startsWith('+251')) {
                            phone = phone.substring(4);
                          } else if (phone.startsWith('0')) {
                            phone = phone.substring(1);
                          }

                          setSheetState(() {
                            isAuthLoading = true;
                            authError = null;
                          });

                          try {
                            final auth = context.read<AuthProvider>();
                            final wallet = context.read<WalletProvider>();

                            // 1. Log in passenger
                            await auth.login('0$phone', password);

                            // 2. Fetch logged-in wallet balance
                            final userId = (auth.user?['id'] ?? auth.user?['user_id'])?.toString() ?? '';
                            if (userId.isNotEmpty) {
                              await wallet.refreshWallet(userId, auth.token!);
                            }

                            // 3. Pop bottom sheet and execute payment
                            if (context.mounted) {
                              Navigator.pop(sheetContext);
                              _handlePayment();
                            }
                          } catch (e) {
                            setSheetState(() {
                              isAuthLoading = false;
                              authError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: isAuthLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                      : Text('verify_and_pay'.tr().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text('cancel'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StopItem extends StatelessWidget {
  final dynamic stop;
  final bool isSelected;
  final VoidCallback onTap;

  const _StopItem({required this.stop, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String stopName = stop['name'] ?? 'Stop';
    if (stop['metadata']?['name'] != null) stopName = stop['metadata']['name'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentColor : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppTheme.accentColor : Theme.of(context).dividerColor.withOpacity(0.05),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded, color: isSelected ? Colors.black : Colors.grey[400]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stopName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isSelected ? Colors.black : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (stop['distanceKm'] != null)
                      Text(
                        '${stop['distanceKm']} km',
                        style: TextStyle(fontSize: 12, color: isSelected ? Colors.black.withOpacity(0.6) : Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              if (stop['amount'] != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    '${double.tryParse(stop['amount'].toString())?.toStringAsFixed(2) ?? stop['amount']} ${'currency'.tr()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: isSelected ? Colors.black : AppTheme.accentColor,
                    ),
                  ),
                ),
              if (isSelected && stop['amount'] == null) 
                const Icon(Icons.check_circle_rounded, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatefulWidget {
  final String transactionId;
  final double amount;
  final String tripId;
  final String? driverId;

  const PaymentSuccessScreen({
    super.key, 
    required this.transactionId, 
    required this.amount,
    required this.tripId,
    this.driverId,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Immersive pulsing emerald gradient status ring
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withOpacity(0.1),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                Text(
                  'payment_successful'.tr().toUpperCase(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 28, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'paid_for_trip'.tr(args: [widget.amount.toStringAsFixed(2), 'currency'.tr()]),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor.withOpacity(0.7),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Show transaction ID badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
                  ),
                  child: Text(
                    'TXID: ${widget.transactionId.toUpperCase()}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.hintColor,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                if (widget.driverId != null) ...[
                  FutureBuilder<Map<String, dynamic>?>(
                    future: context.read<DriverProvider>().getDriverProfileData(widget.driverId!, auth.token!, headers: auth.headers),
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      final reviews = profile?['reviews'] ?? {};
                      final reviewList = reviews['reviews'] as List? ?? [];
                      final currentUserId = (auth.user?['id'] ?? auth.user?['user_id'])?.toString() ?? '';
                      final hasReviewed = reviewList.any((r) => r['reviewer_id']?.toString() == currentUserId);
                      final isLoading = snapshot.connectionState == ConnectionState.waiting;
                      
                      return Row(
                        children: [
                          if (isLoading)
                            const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.accentColor)))
                          else if (!hasReviewed) ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushReplacement(
                                  context, 
                                  MaterialPageRoute(builder: (context) => RateTripScreen(tripId: widget.tripId, driverId: widget.driverId))
                                ),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                                child: Text('rate_your_trip'.tr().toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                backgroundColor: theme.cardColor,
                                foregroundColor: AppTheme.accentColor,
                                side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                                elevation: 0,
                              ),
                              child: Text('back_to_home'.tr().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: theme.cardColor,
                        foregroundColor: AppTheme.accentColor,
                        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                        elevation: 0,
                      ),
                      child: Text('back_to_home'.tr().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
