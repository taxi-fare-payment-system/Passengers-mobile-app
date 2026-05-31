import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/auth_provider.dart';
import '../providers/qr_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_modals.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _scannedQrCode;
  bool _isQrMode = false;
  String? _qrBannerMessage;
  bool _showManualLogin = false;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final hasCreds = await auth.hasStoredCredentials();
      if (mounted && hasCreds) {
        setState(() => _canUseBiometrics = true);
      }
      await auth.tryAutoLogin();
      if (auth.storedPhone != null && auth.storedPhone!.isNotEmpty) {
        setState(() {
          String displayPhone = auth.storedPhone!;
          if (displayPhone.startsWith('+251')) {
            displayPhone = displayPhone.substring(4);
          } else if (displayPhone.startsWith('0')) {
            displayPhone = displayPhone.substring(1);
          }
          _phoneController.text = displayPhone;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('WULO PAY', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 4, color: AppTheme.accentColor)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text('welcome_back'.tr(), style: theme.textTheme.displayLarge?.copyWith(fontSize: 40)),
            const SizedBox(height: 8),
            Text(_isQrMode 
                ? 'authorize_to_continue'.tr() == 'authorize_to_continue' ? 'AUTHORIZE TO CONTINUE' : 'authorize_to_continue'.tr()
                : 'sign_in_passenger'.tr(), 
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            
            // State-driven UI presentation
            if (_isQrMode)
              _buildQRScannedView(theme)
            else if (_showManualLogin)
              _buildManualLoginView(theme)
            else
              _buildCleanQRScannerView(theme),
              
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/register'),
                child: RichText(
                  text: TextSpan(
                    text: '${'new_here'.tr()} ',
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: 'create_account'.tr(),
                        style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanQRScannerView(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Immersive centerpiece scanning container
        GestureDetector(
          onTap: () => _showQRScanner(context),
          child: Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.accentColor.withOpacity(0.15), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withOpacity(0.04),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppTheme.accentColor,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'scan_qr_code'.tr().toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),
        
        // Beautiful toggle to manual phone number form
        Center(
          child: TextButton(
            onPressed: () => setState(() => _showManualLogin = true),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'use_phone_instead'.tr().toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accentColor,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.accentColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRScannedView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // Scanned confirmation banner card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.accentColor.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.accentColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'qr_code_scanned'.tr().toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accentColor,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Phone: +251 ${_phoneController.text}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Password Input only
        Text('password'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enabled: !_isLoading,
          style: const TextStyle(fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: '••••••••',
            fillColor: theme.cardColor,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: theme.hintColor),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 40),
        
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 56),
          ),
          child: _isLoading 
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
            : Text('LOGIN'.tr().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 24),
        
        // Cancel QR mode
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _isQrMode = false;
                _scannedQrCode = null;
                _qrBannerMessage = null;
                _passwordController.clear();
              });
            },
            child: Text(
              'cancel_scan'.tr().toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualLoginView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
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
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: !_isLoading,
                style: const TextStyle(fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  hintText: '91 234 5678',
                  fillColor: theme.cardColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('password'.tr().toUpperCase(), style: theme.textTheme.labelSmall),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enabled: !_isLoading,
          style: const TextStyle(fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: '••••••••',
            fillColor: theme.cardColor,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: theme.hintColor),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _showForgotPasswordDialog(),
            child: Text('forgot_password'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.accentColor)),
          ),
        ),
        const SizedBox(height: 32),
        
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 56),
          ),
          child: _isLoading 
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
            : Text('login'.tr().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        if (_canUseBiometrics) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleBiometricLogin,
            icon: const Icon(Icons.fingerprint_rounded, size: 28),
            label: Text('login_with_biometrics'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.cardColor,
              foregroundColor: AppTheme.accentColor,
              minimumSize: const Size(double.infinity, 56),
              side: BorderSide(color: AppTheme.accentColor.withOpacity(0.5)),
            ),
          ),
        ],
        const SizedBox(height: 24),
        
        // Back to QR scan centerpiece
        Center(
          child: TextButton(
            onPressed: () => setState(() => _showManualLogin = false),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'back_to_qr_scan'.tr().toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accentColor,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.biometricLogin();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) AppModals.showError(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    if (phone.isEmpty || password.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.login('0$phone', password);
      if (mounted) {
        if (_scannedQrCode != null) {
          final qrProvider = context.read<QRProvider>();
          final isValid = await qrProvider.verifyQRCode(_scannedQrCode!, auth.token!, headers: auth.headers);
          if (mounted) {
            if (isValid) {
              Navigator.pushReplacementNamed(context, '/home');
              Navigator.pushNamed(context, '/confirm-payment', arguments: {'trip_id': _scannedQrCode});
            } else {
              Navigator.pushReplacementNamed(context, '/home');
              AppModals.showError(context, 'invalid_qr_code'.tr());
            }
          }
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) AppModals.showError(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showQRScanner(BuildContext context) {
    bool hasScanned = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        height: MediaQuery.of(modalContext).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(modalContext).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(modalContext).dividerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('scan_qr_to_quick_login'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: MobileScanner(
                    onDetect: (capture) async {
                      if (hasScanned) return;
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final String? code = barcodes.first.rawValue?.trim();
                        if (code != null) {
                          hasScanned = true;
                          Navigator.pop(modalContext);
                          
                          // Try to decode base64 driver information to extract a phone number if available
                          String? extractedPhone;
                          try {
                            final decoded = utf8.decode(base64.decode(base64.normalize(code)));
                            final Map<String, dynamic> data = jsonDecode(decoded);
                            if (data.containsKey('phone')) {
                              extractedPhone = data['phone']?.toString();
                            } else if (data.containsKey('driver_phone')) {
                              extractedPhone = data['driver_phone']?.toString();
                            }
                          } catch (_) {}

                          String displayPhone = extractedPhone ?? _phoneController.text.trim();
                          if (displayPhone.startsWith('+251')) {
                            displayPhone = displayPhone.substring(4);
                          } else if (displayPhone.startsWith('0')) {
                            displayPhone = displayPhone.substring(1);
                          }

                          Navigator.pushNamed(
                            context,
                            '/confirm-payment',
                            arguments: {
                              'trip_id': code,
                              'passenger_phone': displayPhone,
                            },
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => Navigator.pop(modalContext), 
              child: Text('cancel'.tr(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary))
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController forgotPhoneController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(modalContext).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(modalContext).dividerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('reset_password'.tr(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text('reset_password_desc'.tr(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
                    const SizedBox(height: 32),
                    
                    Text('phone_number'.tr().toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                          ),
                          child: const Text('+251', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: forgotPhoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                            decoration: InputDecoration(
                              hintText: '91 234 5678',
                              fillColor: Theme.of(context).cardColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    ElevatedButton(
                      onPressed: () async {
                        final phone = forgotPhoneController.text.trim();
                        if (phone.isEmpty) return;
                        try {
                          await context.read<AuthProvider>().resetPassword('0$phone');
                          if (context.mounted) {
                            Navigator.pop(modalContext);
                            AppModals.showSuccess(context, 'reset_instructions_sent'.tr());
                          }
                        } catch (e) {
                          if (context.mounted) AppModals.showError(context, e.toString().replaceAll('Exception: ', ''));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: Text('send'.tr().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(modalContext),
                        child: Text(
                          'cancel'.tr().toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
