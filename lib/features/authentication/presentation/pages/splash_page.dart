import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/fixen_logo.dart';
import '../providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();

    // Check authentication after animation finishes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkAuthentication();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAuthentication() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.checkAuth();
    final authState = ref.read(authNotifierProvider);

    if (mounted) {
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        final role = authState.user!.role;
        if (role == 'worker') {
          // If blocked, we can still navigate to worker dashboard which will show block state
          context.go('/worker-dashboard');
        } else if (role == 'admin') {
          context.go('/admin-dashboard');
        } else {
          context.go('/user-dashboard');
        }
      } else {
        context.go('/role-selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1329)
          : const Color(0xFFF8FAFC),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FixenLogo(size: 180, showLabel: true, showTagline: true),
              const SizedBox(height: 48),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
