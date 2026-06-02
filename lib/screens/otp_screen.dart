import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_modals.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() => _secondsRemaining = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 64,
      textStyle: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
    );

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
            Text('verify_phone'.tr(), style: theme.textTheme.displayLarge?.copyWith(fontSize: 40)),
            const SizedBox(height: 8),
            Text('enter_otp_msg_short'.tr(), style: theme.textTheme.bodyLarge),
            const SizedBox(height: 60),
            
            Center(
              child: Pinput(
                length: 6,
                controller: _pinController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppTheme.accentColor, width: 2),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: AppTheme.accentColor),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _secondsRemaining == 0 ? () {
                          // Handle resend logic here
                          _startTimer();
                          final args = ModalRoute.of(context)!.settings.arguments;
                          String phone = args is String ? args : (args as Map)['phone'];
                          context.read<AuthProvider>().sendOTP(phone).catchError((e) {
                            if (mounted) AppModals.showError(context, e.toString());
                          });
                        } : null,
                        child: Text(
                          _secondsRemaining > 0
                              ? '${'resend_code_in'.tr()} 00:${_secondsRemaining.toString().padLeft(2, '0')}'
                              : 'resend_code'.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11, 
                            letterSpacing: 1,
                            color: _secondsRemaining > 0 ? theme.hintColor : AppTheme.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'change_phone_number'.tr(),
                      style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleVerify,
              child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                : Text('verify_continue'.tr().toUpperCase()),
            ),
            
            const SizedBox(height: 24),
            Center(
              child: Text(
                'by_continuing_agree_generic'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: theme.hintColor.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVerify() async {
    final args = ModalRoute.of(context)!.settings.arguments;
    String phone;
    String? password;
    
    if (args is String) {
      phone = args;
    } else {
      final map = args as Map<String, dynamic>;
      phone = map['phone'];
      password = map['password'];
    }

    final code = _pinController.text;
    if (code.length != 6) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().verifyOTP(phone, code);
      if (password != null) await context.read<AuthProvider>().login(phone, password);
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (mounted) AppModals.showError(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
