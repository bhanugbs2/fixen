import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/fixen_logo.dart';
import '../../../../common/widgets/glass_container.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

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
          Positioned(
            top: -size.width * 0.25,
            right: -size.width * 0.15,
            child: _GlowOrb(
              diameter: size.width * 0.7,
              color: const Color(0xFF0EA5E9).withOpacity(isDark ? 0.12 : 0.08),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.2,
            left: -size.width * 0.2,
            child: _GlowOrb(
              diameter: size.width * 0.65,
              color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.1 : 0.07),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          const Center(
                            child: FixenLogo(
                              size: 160,
                              showLabel: true,
                              showTagline: true,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Choose your role',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select how you want to use FIXEN — book services, work as a verified pro, or manage the platform.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _RoleCard(
                            title: 'User / Customer',
                            description:
                                'Request Electricians, Plumbers & Carpenters to your doorstep.',
                            icon: Icons.person_rounded,
                            color: const Color(0xFF10B981),
                            onTap: () => context.push('/login'),
                          ),
                          const SizedBox(height: 14),
                          _RoleCard(
                            title: 'Verified Worker',
                            description:
                                'Receive service bookings. Access your jobs & earnings.',
                            icon: Icons.engineering_rounded,
                            color: const Color(0xFF0EA5E9),
                            onTap: () => context.push('/worker-login'),
                          ),
                          const SizedBox(height: 14),
                          _RoleCard(
                            title: 'FIXEN Administrator',
                            description:
                                'Manage worker approvals, analytics, invoices & reports.',
                            icon: Icons.admin_panel_settings_rounded,
                            color: const Color(0xFFF59E0B),
                            onTap: () => context.push('/admin-login'),
                          ),
                          const Spacer(),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ServiceChip(
                                label: 'Plumbing',
                                color: const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 8),
                              _ServiceChip(
                                label: 'Electrical',
                                color: const Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 8),
                              _ServiceChip(
                                label: 'Carpentry',
                                color: const Color(0xFFEA580C),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double diameter;
  final Color color;

  const _GlowOrb({required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ServiceChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : color.withOpacity(0.9),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.02,
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = 1 - _controller.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: Transform.scale(
        scale: scale,
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          borderRadius: 20,
          bgGradientColor: isDark ? const Color(0x11FFFFFF) : Colors.white,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.25),
                      widget.color.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.color.withOpacity(0.25)),
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(isDark ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: widget.color,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
