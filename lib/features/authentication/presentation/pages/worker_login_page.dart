import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/validators/validators.dart';
import '../../../../common/widgets/custom_text_field.dart';
import '../../../../common/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class WorkerLoginPage extends ConsumerStatefulWidget {
  final String category;
  const WorkerLoginPage({super.key, required this.category});

  @override
  ConsumerState<WorkerLoginPage> createState() => _WorkerLoginPageState();
}

class _WorkerLoginPageState extends ConsumerState<WorkerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onVerifyPressed() async {
    if (_formKey.currentState!.validate()) {
      ref.read(authNotifierProvider.notifier).clearError();
      await ref.read(authNotifierProvider.notifier).requestWorkerLogin(_phoneController.text.trim());
      
      final authState = ref.read(authNotifierProvider);
      if (authState.status == AuthStatus.otpRequired && mounted) {
        context.push('/worker-otp');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for error messages
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/role-selection'),
        ),
        title: Text('${widget.category} Portal'),
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
                  '${widget.category} Access 🛠️',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Workers registered as ${widget.category.toLowerCase()}s must be enrolled in the FIXEN database. Enter your registered mobile number to receive a verification OTP.',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white60 : const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                
                // Phone Field
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Registered Mobile Number',
                  hintText: 'e.g., +919876543210',
                  prefixIcon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: 32),
                
                // Submit Button
                PrimaryButton(
                  text: 'Request Access OTP',
                  isLoading: authState.status == AuthStatus.loading,
                  onPressed: _onVerifyPressed,
                ),
                const SizedBox(height: 40),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x0AFFFFFF) : Colors.black54.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Theme.of(context).primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Self-registration is not supported. If you are a new worker, please contact the nearest FIXEN office to complete your enrollment and register.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF475569),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
