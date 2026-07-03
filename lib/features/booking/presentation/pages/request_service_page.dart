import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../common/widgets/custom_text_field.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/glass_container.dart';

class RequestServicePage extends StatefulWidget {
  final String category;

  const RequestServicePage({super.key, required this.category});

  @override
  State<RequestServicePage> createState() => _RequestServicePageState();
}

class _RequestServicePageState extends State<RequestServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final List<String> _attachedImages = [];
  final List<String> _voiceRecordings = [];
  
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  
  // Search Flow Status
  bool _isSearching = false;
  int _searchRadius = 5; // KM
  int _searchCountdown = 10; // 10s for demo, represents 60s in production
  Timer? _searchTimer;
  bool _noWorkersFound = false;
  bool _quotesReceived = false;

  final ImagePicker _picker = ImagePicker();

  double _userLat = 16.3067;
  double _userLng = 80.4365;
  bool _hasFetchedLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
          _hasFetchedLocation = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _descController.dispose();
    _recordTimer?.cancel();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _attachImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) {
      setState(() {
        _attachedImages.add(pickedFile.path);
      });
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
        _voiceRecordings.add('Voice Note #${_voiceRecordings.length + 1} (${_recordSeconds}s)');
      });
    } else {
      _recordSeconds = 0;
      setState(() {
        _isRecording = true;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordSeconds++;
        });
      });
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _noWorkersFound = false;
      _quotesReceived = false;
      _searchRadius = 5;
      _searchCountdown = 5; // Speed up to 5s per step for preview experience
    });

    _runSearchStep();
  }

  void _runSearchStep() {
    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_searchCountdown > 0) {
        setState(() {
          _searchCountdown--;
        });
      } else {
        timer.cancel();
        if (_searchRadius == 5) {
          setState(() {
            _searchRadius = 10;
            _searchCountdown = 5;
          });
          _runSearchStep();
        } else if (_searchRadius == 10) {
          setState(() {
            _searchRadius = 20;
            _searchCountdown = 5;
          });
          _runSearchStep();
        } else {
          // Finished 20 KM search, transition to either results or no workers
          setState(() {
            _isSearching = false;
            // Let's match worker for category
            _quotesReceived = true;
          });
        }
      }
    });
  }

  void _simulateNoWorkers() {
    setState(() {
      _isSearching = false;
      _noWorkersFound = true;
      _quotesReceived = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isSearching) {
      return _buildSearchingRadarScreen();
    }

    if (_noWorkersFound) {
      return _buildNoWorkersScreen();
    }

    if (_quotesReceived) {
      return _buildQuotationScreen();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Request ${widget.category}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.category == 'Electrician' 
                            ? '⚡' 
                            : widget.category == 'Plumber' 
                                ? '🚰' 
                                : '🪚',
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified ${widget.category} Services',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Premium diagnostics, repair, and installations.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                
                // Description field
                CustomTextField(
                  controller: _descController,
                  labelText: 'Describe the issue',
                  hintText: 'Describe what needs fixing, e.g. Kitchen tap is leaking continuously...',
                  maxLines: 4,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please describe your request' : null,
                ),
                const SizedBox(height: 24),

                // Voice description
                Text(
                  'Record Voice Description',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        height: 54,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C2541) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _isRecording 
                                ? 'Recording... (${_recordSeconds}s)' 
                                : _voiceRecordings.isEmpty 
                                    ? 'No recordings added' 
                                    : '${_voiceRecordings.length} voice note(s) added',
                            style: TextStyle(
                              color: _isRecording ? Colors.redAccent : Colors.grey,
                              fontSize: 13,
                              fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _toggleRecording,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.redAccent : Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_voiceRecordings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _voiceRecordings.map((rec) => Chip(
                      label: Text(rec, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.teal.withOpacity(0.1),
                      onDeleted: () {
                        setState(() {
                          _voiceRecordings.remove(rec);
                        });
                      },
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 28),

                // Image upload
                Text(
                  'Upload Problem Images',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _attachImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C2541) : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        child: Icon(Icons.add_a_photo_outlined, color: Theme.of(context).primaryColor, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      Uri.parse(_attachedImages[index]).isAbsolute 
                                          ? File(_attachedImages[index]) 
                                          : File(_attachedImages[index]),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _attachedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 36),

                // Request Location Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C2541) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pin_drop_rounded, color: Theme.of(context).primaryColor, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Service Location',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Current location automatically pinned',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pin adjust on map opened (Simulated)')),
                          );
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Request button
                PrimaryButton(
                  text: 'Find Available Workers',
                  onPressed: _startSearch,
                ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: _simulateNoWorkers,
                    child: const Text(
                      'Simulate "No Workers Found" state',
                      style: TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SUB-SCREEN: SEARCHING RADAR SCREEN ---
  Widget _buildSearchingRadarScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1329) : const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Radar animated loader placeholder
              // Radar animated loader map representation
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Grid lines
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CustomPaint(
                          painter: _SearchRadarPainter(
                            isDark: isDark,
                            radius: _searchRadius,
                          ),
                        ),
                      ),
                    ),
                    
                    // User Pin
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Searching Here', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 2),
                          const Icon(Icons.person_pin_circle_rounded, color: Colors.blueAccent, size: 36),
                        ],
                      ),
                    ),

                    // Plotted worker markers that pop up as the scan radius increases
                    if (_searchRadius >= 5)
                      Positioned(
                        left: 90,
                        top: 40,
                        child: _buildRadarPin(context, 'Karan Sharma', Colors.amber),
                      ),
                    if (_searchRadius >= 10)
                      Positioned(
                        right: 80,
                        bottom: 60,
                        child: _buildRadarPin(context, 'Vijay Verma', Colors.blue),
                      ),
                    if (_searchRadius >= 20)
                      Positioned(
                        right: 50,
                        top: 70,
                        child: _buildRadarPin(context, 'Rajesh Kumar', Colors.green),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Searching for Nearby ${widget.category}s',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 12),
              Text(
                'Radius: $_searchRadius KM  •  Checking availability...',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Expanding radius in ${_searchCountdown}s',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 48),
              OutlinedButton(
                onPressed: () {
                  _searchTimer?.cancel();
                  setState(() {
                    _isSearching = false;
                  });
                },
                child: const Text('Cancel Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SUB-SCREEN: NO WORKERS FOUND ---
  Widget _buildNoWorkersScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_search_rounded, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'No Workers Available Nearby',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 12),
              const Text(
                'We searched up to 20 KM, but no tech matching your description is online right now. Try expanding your search or retry.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 36),
              PrimaryButton(
                text: 'Retry Search Now',
                onPressed: _startSearch,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _noWorkersFound = false;
                  });
                },
                child: const Text('Back to Edit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SUB-SCREEN: QUOTATIONS LIST ---
  Widget _buildQuotationScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matched Technicians'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Received Quotations 📋',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Technicians reviewed your issue details and submitted bids. Accept a quote to begin tracking.',
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 24),
          ..._getCategoryQuotations(),
          const SizedBox(height: 36),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _quotesReceived = false;
              });
            },
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationCard(
    BuildContext context, {
    required String name,
    required double rating,
    required int reviewsCount,
    required int experience,
    required double distance,
    required int eta,
    required double price,
    required String message,
    required String imageUrl,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      bgGradientColor: isDark ? const Color(0x11FFFFFF) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildProfileAvatar(
                name: name,
                service: widget.category,
                radius: 26,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '$rating ($reviewsCount reviews)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  $experience yrs exp',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '₹${price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_car_rounded, color: Colors.grey, size: 16),
                  const SizedBox(width: 6),
                  Text('$distance KM away', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, color: Colors.grey, size: 16),
                  const SizedBox(width: 6),
                  Text('ETA: $eta mins', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$message"',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {
                      _quotesReceived = false;
                    });
                  },
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // Accepts quotation and routes to live tracking screen
                    context.go('/live-tracking/mock_booking_123');
                  },
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarPin(BuildContext context, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
      ],
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

  List<Widget> _getCategoryQuotations() {
    final s = widget.category.toLowerCase();
    if (s.contains('plumber')) {
      return [
        _buildQuotationCard(
          context,
          name: 'Ch. Venkata Ramana',
          rating: 4.9,
          reviewsCount: 52,
          experience: 8,
          distance: 0.8,
          eta: 8,
          price: 350,
          message: 'Available in Arundelpet. I can fix water leaks and install pipes immediately.',
          imageUrl: '',
        ),
        const SizedBox(height: 20),
        _buildQuotationCard(
          context,
          name: 'P. Suresh Babu',
          rating: 4.7,
          reviewsCount: 31,
          experience: 5,
          distance: 1.5,
          eta: 14,
          price: 299,
          message: 'Experienced plumber near Brodipet. I carry all replacement valves and tools.',
          imageUrl: '',
        ),
        const SizedBox(height: 20),
        _buildQuotationCard(
          context,
          name: 'M. Nagabhushanam',
          rating: 4.8,
          reviewsCount: 42,
          experience: 10,
          distance: 2.1,
          eta: 18,
          price: 450,
          message: 'Specialist in blockages, tap repairs, and water tank systems. Friendly service.',
          imageUrl: '',
        ),
      ];
    } else if (s.contains('carpenter')) {
      return [
        _buildQuotationCard(
          context,
          name: 'K. Srinivasa Rao',
          rating: 4.8,
          reviewsCount: 64,
          experience: 9,
          distance: 1.1,
          eta: 11,
          price: 499,
          message: 'Furniture assembly, doors alignment, and wood repairs. High precision woodworks.',
          imageUrl: '',
        ),
        const SizedBox(height: 20),
        _buildQuotationCard(
          context,
          name: 'B. Gopala Krishna',
          rating: 4.6,
          reviewsCount: 29,
          experience: 4,
          distance: 1.9,
          eta: 16,
          price: 380,
          message: 'Guntur carpenter available now. Specialised in lock fixing, cupboards, and hinge repairs.',
          imageUrl: '',
        ),
        const SizedBox(height: 20),
        _buildQuotationCard(
          context,
          name: 'D. Sai Teja',
          rating: 4.9,
          reviewsCount: 78,
          experience: 12,
          distance: 2.5,
          eta: 22,
          price: 550,
          message: 'Top-rated carpenter. Expert in modular kitchen fixes, wardrobes, and structural woodwork.',
          imageUrl: '',
        ),
      ];
    } else {
      // Default: Electrician
      return [
        _buildQuotationCard(
          context,
          name: 'T. Sai Kumar',
          rating: 4.9,
          reviewsCount: 48,
          experience: 6,
          distance: 1.2,
          eta: 10,
          price: 450,
          message: 'I have standard tools ready. Can resolve wiring issues and shorts in 15 mins.',
          imageUrl: '',
        ),
        const SizedBox(height: 20),
        _buildQuotationCard(
          context,
          name: 'Y. Rajesh Naidu',
          rating: 4.7,
          reviewsCount: 22,
          experience: 4,
          distance: 2.8,
          eta: 18,
          price: 399,
          message: 'Experienced with switchboards, fans installation, and short circuits near Arundelpet.',
          imageUrl: '',
        ),
        const SizedBox(height: 20),
        _buildQuotationCard(
          context,
          name: 'G. Venkateswarlu',
          rating: 4.8,
          reviewsCount: 88,
          experience: 14,
          distance: 0.9,
          eta: 7,
          price: 500,
          message: 'Certified industrial & domestic electrician in Brodipet. Swift diagnoses.',
          imageUrl: '',
        ),
      ];
    }
  }
}

class _SearchRadarPainter extends CustomPainter {
  final bool isDark;
  final int radius;
  _SearchRadarPainter({required this.isDark, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)
      ..strokeWidth = 1.0;

    const double step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw scanning circular rings
    final center = Offset(size.width / 2, size.height / 2);
    final radarPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 40.0, radarPaint);
    canvas.drawCircle(center, 80.0, radarPaint);
    canvas.drawCircle(center, 120.0, radarPaint);
  }

  @override
  bool shouldRepaint(covariant _SearchRadarPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.radius != radius;
}
