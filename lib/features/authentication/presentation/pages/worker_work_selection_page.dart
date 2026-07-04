import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/glass_container.dart';
import '../../../../common/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class WorkerWorkSelectionPage extends ConsumerStatefulWidget {
  const WorkerWorkSelectionPage({super.key});

  @override
  ConsumerState<WorkerWorkSelectionPage> createState() => _WorkerWorkSelectionPageState();
}

class _WorkerWorkSelectionPageState extends ConsumerState<WorkerWorkSelectionPage> {
  String? _selectedCategory;

  void _onSubmit() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select one specialty category.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).updateWorkerCategory(_selectedCategory!);
    if (success && mounted) {
      context.go('/worker-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);

    // Listen for error messages
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.errorMessage != null && mounted) {
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF0B1329),
                        const Color(0xFF162447),
                        const Color(0xFF1C2541),
                      ]
                    : [
                        const Color(0xFFF8FAFC),
                        const Color(0xFFEFF6FF),
                        const Color(0xFFE2E8F0),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30),
                  Text(
                    'Welcome to FIXEN! 🛠️',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please select your primary specialty category. This represents the only type of job requests you will receive.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  _buildOptionCard(
                    title: 'Electrician',
                    description: 'Resolve wiring, switches, lighting & appliance repairs.',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildOptionCard(
                    title: 'Carpenter',
                    description: 'Repair furniture, doors, cupboards & woodwork.',
                    icon: Icons.handyman_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildOptionCard(
                    title: 'Plumber',
                    description: 'Fix leaks, pipes, faucets, drainage & installations.',
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF0EA5E9),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  PrimaryButton(
                    text: 'Confirm Specialty & Continue',
                    isLoading: authState.status == AuthStatus.loading,
                    onPressed: _onSubmit,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedCategory == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        bgGradientColor: isSelected
            ? color.withOpacity(isDark ? 0.25 : 0.15)
            : (isDark ? const Color(0x0CFFFFFF) : Colors.white),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.3)
                    : color.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : color.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : (isDark ? Colors.white30 : Colors.black26),
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
