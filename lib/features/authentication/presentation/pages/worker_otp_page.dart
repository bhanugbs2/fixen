import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/validators/validators.dart';
import '../../../../common/widgets/custom_text_field.dart';
import '../../../../common/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class WorkerOtpPage extends ConsumerStatefulWidget {
  const WorkerOtpPage({super.key});

  @override
  ConsumerState<WorkerOtpPage> createState() => _WorkerOtpPageState();
}

class _WorkerOtpPageState extends ConsumerState<WorkerOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  
  int _attemptsRemaining = 5;
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _onVerifyOtp() async {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(authNotifierProvider.notifier);
      final success = await notifier.verifyWorkerOtp(_otpController.text.trim());

      if (success) {
        if (mounted) {
          final user = ref.read(authNotifierProvider).user;
          if (user != null && (user.service == null || user.service!.isEmpty)) {
            context.go('/worker-work-selection');
          } else {
            context.go('/worker-dashboard');
          }
        }
      } else {
        setState(() {
          _attemptsRemaining--;
        });

        if (_attemptsRemaining <= 0) {
          if (mounted) {
            _showLockoutDialog();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid OTP. $_attemptsRemaining attempts remaining.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    }
  }

  void _showLockoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Access Blocked'),
        content: const Text('You have exceeded the maximum of 5 OTP verification attempts. This login session has been closed for security reasons.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authNotifierProvider.notifier).logout();
              context.go('/role-selection');
            },
            child: const Text('Return to Home'),
          ),
        ],
      ),
    );
  }

  void _onResendOtp() {
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A new OTP has been sent (Simulated).'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final mobileNumber = authState.verificationMobileNumber ?? '+919876543210';
    final maskedPhone = mobileNumber.length > 4 
        ? '${mobileNumber.substring(0, 3)}******${mobileNumber.substring(mobileNumber.length - 4)}'
        : mobileNumber;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('OTP Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Verify Your Identity 🛡️',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A 6-digit OTP code was sent to the registered mobile number ($maskedPhone) connected to Worker ID: ${authState.pendingWorkerId ?? ""}. Enter the code to verify your profile and start receiving jobs.',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white60 : const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                
                // OTP Field
                CustomTextField(
                  controller: _otpController,
                  labelText: '6-Digit OTP Code',
                  hintText: 'Enter OTP code',
                  prefixIcon: Icons.password_rounded,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateOtp,
                ),
                const SizedBox(height: 12),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: _secondsRemaining > 0
                      ? Text(
                          'Resend OTP in ${_secondsRemaining}s',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        )
                      : TextButton(
                          onPressed: _onResendOtp,
                          child: Text(
                            'Resend Code',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                
                // Verify button
                PrimaryButton(
                  text: 'Verify & Login',
                  isLoading: authState.status == AuthStatus.loading,
                  onPressed: _onVerifyOtp,
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Security Reminder: Never share your OTP with anyone.${authState.debugOtp != null && authState.debugOtp!.isNotEmpty ? " For testing, your received OTP is ${authState.debugOtp}." : " Correct code is \"123456\" for sandbox testing."}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
