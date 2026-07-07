import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../common/validators/validators.dart';
import '../../../../common/widgets/custom_text_field.dart';
import '../../../../common/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  
  File? _profileImage;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
      return;
    }
    // Request camera/gallery permissions first
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isGranted) {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery/Camera permission is required to upload profile image')),
        );
      }
    }
  }

  void _onRegisterPressed() async {
    if (_formKey.currentState!.validate()) {
      if (!kIsWeb) {
        // First verify and request location permissions
        final locationStatus = await Permission.location.request();
        if (!locationStatus.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required to register with FIXEN.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }

      ref.read(authNotifierProvider.notifier).clearError();
      await ref.read(authNotifierProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            mobileNumber: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            profileImagePath: _profileImage?.path,
          );

      final authState = ref.read(authNotifierProvider);
      if (authState.status == AuthStatus.authenticated && mounted) {
        context.go('/user-dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for errors
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
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join FIXEN 🛠️',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to connect with trusted local mechanics.',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white60 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 28),
                
                // Profile Image Picker
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: isDark ? const Color(0xFF1C2541) : const Color(0xFFE2E8F0),
                          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                          child: _profileImage == null
                              ? Icon(
                                  Icons.camera_alt_outlined,
                                  color: Theme.of(context).primaryColor,
                                  size: 32,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? const Color(0xFF0B1329) : Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Full Name
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 20),
                
                // Email Address
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 20),
                
                // Mobile Number
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Mobile Number',
                  hintText: 'e.g. +919876543210',
                  prefixIcon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: 20),
                
                // Address description
                CustomTextField(
                  controller: _addressController,
                  labelText: 'Home Address',
                  hintText: 'Flat number, Street name, City',
                  prefixIcon: Icons.home_outlined,
                  maxLines: 2,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Address is required' : null,
                ),
                const SizedBox(height: 20),
                
                // Password
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Choose a strong password',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 20),
                
                // Confirm Password
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: Icons.lock_clock_outlined,
                  isPassword: true,
                  validator: (val) => Validators.validateConfirmPassword(val, _passwordController.text),
                ),
                const SizedBox(height: 32),
                
                // Register Button
                PrimaryButton(
                  text: 'Register Account',
                  isLoading: authState.status == AuthStatus.loading,
                  onPressed: _onRegisterPressed,
                ),
                const SizedBox(height: 24),
                
                // Back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: isDark ? Colors.white60 : const Color(0xFF475569),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
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
