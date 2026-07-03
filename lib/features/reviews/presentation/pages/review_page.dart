import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/custom_text_field.dart';
import '../../../../common/widgets/primary_button.dart';

class ReviewPage extends StatefulWidget {
  final String bookingId;

  const ReviewPage({super.key, required this.bookingId});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  final List<String> _photos = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Review submitted for booking ${widget.bookingId}!'),
        backgroundColor: Colors.green,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How was the service? ⭐',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your rating and feedback help us maintain our high standard of Government Verified Technicians.',
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 32),
              
              // Worker info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C2541) : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: Row(
                  children: [
                    _buildProfileAvatar(
                      name: 'Ch. Venkata Ramana',
                      service: 'Plumber',
                      radius: 24,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Ch. Venkata Ramana', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 2),
                        Text('Service ID: BK-5896  •  Plumber', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 36),
              
              // Stars
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 32),
              
              // Comments
              CustomTextField(
                controller: _commentController,
                labelText: 'Share your feedback',
                hintText: 'What did the technician do well? How was their service quality?',
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              
              // Photo attachment mockup
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _photos.add('Photo #${_photos.length + 1}');
                      });
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Add Service Photos'),
                  ),
                ],
              ),
              if (_photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _photos.map((ph) => Chip(
                    label: Text(ph, style: const TextStyle(fontSize: 11)),
                    onDeleted: () {
                      setState(() {
                        _photos.remove(ph);
                      });
                    },
                  )).toList(),
                ),
              ],
              
              const SizedBox(height: 48),
              PrimaryButton(
                text: 'Submit Feedback',
                onPressed: _submitReview,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar({required String name, required String service, double radius = 28}) {
    final colors = [
      [const Color(0xFF6366F1), const Color(0xFF4F46E5)], // Indigo
      [const Color(0xFFEC4899), const Color(0xFFDB2777)], // Pink
      [const Color(0xFF14B8A6), const Color(0xFF0D9488)], // Teal
      [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)], // Blue
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], // Purple
    ];
    final index = name.hashCode.abs() % colors.length;
    final gradientColors = colors[index];

    final nameParts = name.trim().split(RegExp(r'\s+'));
    final initials = nameParts.length > 1
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : '';

    IconData icon = Icons.person_rounded;
    final s = service.toLowerCase();
    if (s.contains('electrician')) {
      icon = Icons.electric_bolt_rounded;
    } else if (s.contains('plumber') || s.contains('pipe')) {
      icon = Icons.plumbing_rounded;
    } else if (s.contains('carpenter')) {
      icon = Icons.construction_rounded;
    } else if (s.contains('admin')) {
      icon = Icons.admin_panel_settings_rounded;
    } else if (s.contains('worker') || s.contains('technician')) {
      icon = Icons.engineering_rounded;
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.75,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              )
            : Icon(
                icon,
                color: Colors.white,
                size: radius * 0.9,
              ),
      ),
    );
  }
}
