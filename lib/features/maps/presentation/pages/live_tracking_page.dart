import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../common/widgets/fixen_map_view.dart';
import '../../../../common/widgets/glass_container.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/custom_text_field.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class LiveTrackingPage extends ConsumerStatefulWidget {
  final String bookingId;

  const LiveTrackingPage({super.key, required this.bookingId});

  @override
  ConsumerState<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends ConsumerState<LiveTrackingPage> {
  // Lifecycle States:
  // 1. travelling
  // 2. arrived (OTP verification pending)
  // 3. progress (Service started)
  // 4. completed (Ready for payment)
  // 5. paid (Invoice & review)
  String _lifecycleStatus = "travelling"; 

  // Location / Map details
  double _distance = 3.1; // KM
  int _eta = 12; // Mins
  Timer? _movementTimer;
  double _workerLatOffset = 0.015;
  double _workerLngOffset = 0.015;

  // OTP details
  final String _generatedOtp = "7482"; // Random OTP shown to customer
  final _otpInputController = TextEditingController();
  int _otpAttempts = 5;

  // Payment details
  String _selectedPaymentMethod = "UPI";
  bool _isGeneratingInvoice = false;

  // Review details
  double _rating = 5.0;
  final _commentController = TextEditingController();

  // Live location details
  double _userLat = 16.3067;
  double _userLng = 80.4365;
  String _userAddress = "Brodipet, Guntur, Andhra Pradesh";
  bool _isLoadingLocation = true;
  double _zoomLevel = 15.0;
  Offset _mapOffset = Offset.zero;
  Offset? _dragStart;
  String get _targetDashboard {
    final userRole = ref.read(authNotifierProvider).user?.role ?? 'user';
    return userRole == 'worker' ? '/worker-dashboard' : '/user-dashboard';
  }

  @override
  void initState() {
    super.initState();
    _startMovementSimulation();
    _fetchLiveLocation();
  }

  Future<void> _fetchLiveLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
        _isLoadingLocation = false;
      });

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _userAddress = "${place.name ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''} - ${place.postalCode ?? ''}";
        });
      }
    } catch (_) {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _otpInputController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _startMovementSimulation() {
    _movementTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_lifecycleStatus == "travelling") {
        setState(() {
          if (_distance > 0.3) {
            _distance -= 0.6;
            _eta -= 2;
            if (_eta < 1) _eta = 1;
            // Simulated coordinates moving closer to center
            _workerLatOffset *= 0.7;
            _workerLngOffset *= 0.7;
          } else {
            _distance = 0.0;
            _eta = 0;
            _lifecycleStatus = "arrived";
            timer.cancel();
          }
        });
      }
    });
  }

  void _verifyOtpCode() {
    if (_otpInputController.text == _generatedOtp) {
      setState(() {
        _lifecycleStatus = "progress";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP Verified! Service session started.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _otpAttempts--;
      });
      if (_otpAttempts <= 0) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Verification Suspended'),
            content: const Text('Too many incorrect OTP attempts. The booking has been paused. Please contact customer support.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(_targetDashboard);
                },
                child: const Text('Back to Home'),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incorrect OTP! $_otpAttempts attempts remaining.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _completeService() {
    setState(() {
      _lifecycleStatus = "completed";
    });
  }

  void _processPayment() {
    setState(() {
      _isGeneratingInvoice = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isGeneratingInvoice = false;
        _lifecycleStatus = "paid";
      });
    });
  }

  void _submitReview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you! Your feedback has been recorded.'),
        backgroundColor: Colors.green,
      ),
    );
    context.go(_targetDashboard);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final useGoogleMap = FixenMapView.supportsGoogleMaps;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showExitConfirmation(context),
        ),
      ),
      body: Stack(
        children: [
          // Map Background Preview (Simulated GPS coordinate widget)
          GestureDetector(
            onPanStart: useGoogleMap ? null : (details) {
              _dragStart = details.localPosition;
            },
            onPanUpdate: useGoogleMap ? null : (details) {
              if (_dragStart != null) {
                setState(() {
                  _mapOffset += details.delta;
                });
              }
            },
            onPanEnd: useGoogleMap ? null : (_) {
              _dragStart = null;
            },
            child: Container(
              color: isDark ? const Color(0xFF0B1329) : const Color(0xFFF1F5F9),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: useGoogleMap
                        ? FixenMapView(
                            latitude: _userLat,
                            longitude: _userLng,
                            zoom: _zoomLevel,
                            markers: [
                              if (_lifecycleStatus == 'travelling')
                                FixenMapMarker(
                                  id: 'active_worker',
                                  label: 'Ch. Venkata Ramana - ETA $_eta mins',
                                  latitude: _userLat + _workerLatOffset,
                                  longitude: _userLng + _workerLngOffset,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                                ),
                              if (_lifecycleStatus != 'travelling' && _lifecycleStatus != 'paid') ...[
                                FixenMapMarker(
                                  id: 'nearby_plumber',
                                  label: 'Plumber - 200m',
                                  latitude: _userLat + 0.0018,
                                  longitude: _userLng - 0.0012,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                ),
                                FixenMapMarker(
                                  id: 'nearby_carpenter',
                                  label: 'Carpenter - 450m',
                                  latitude: _userLat - 0.0032,
                                  longitude: _userLng + 0.0024,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                                ),
                                FixenMapMarker(
                                  id: 'nearby_electrician',
                                  label: 'Electrician - 800m',
                                  latitude: _userLat + 0.0045,
                                  longitude: _userLng + 0.0030,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                                ),
                              ],
                            ],
                            polylines: _lifecycleStatus == 'travelling'
                                ? {
                                    Polyline(
                                      polylineId: const PolylineId('worker_route'),
                                      points: [
                                        LatLng(_userLat + _workerLatOffset, _userLng + _workerLngOffset),
                                        LatLng(_userLat + (_workerLatOffset / 2), _userLng + 0.003),
                                        LatLng(_userLat, _userLng),
                                      ],
                                      color: const Color(0xFF10B981),
                                      width: 5,
                                    ),
                                  }
                                : const {},
                          )
                        : CustomPaint(
                            painter: _LiveMapPainter(
                              isDark: isDark,
                              userLat: _userLat,
                              userLng: _userLng,
                              workerLatOffset: _workerLatOffset,
                              workerLngOffset: _workerLngOffset,
                              zoomLevel: _zoomLevel,
                              status: _lifecycleStatus,
                              mapOffset: _mapOffset,
                            ),
                          ),
                  ),
                  
                  // Fallback user pin marker for non-mobile platforms.
                  if (!useGoogleMap)
                  Positioned(
                    left: MediaQuery.of(context).size.width / 2 - 40 + _mapOffset.dx,
                    top: MediaQuery.of(context).size.height / 2 - 50 + _mapOffset.dy,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'You (Live)',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.person_pin_circle_rounded, color: Colors.blueAccent, size: 42),
                      ],
                    ),
                  ),

                  // Surrounding Workers pins ("around location" shifted by mapOffset)
                  if (!useGoogleMap && _lifecycleStatus != "travelling" && _lifecycleStatus != "paid") ...[
                    Positioned(
                      left: 80 + _mapOffset.dx,
                      top: 150 + _mapOffset.dy,
                      child: _buildAroundMarker(context, icon: Icons.plumbing_rounded, color: Colors.blue, label: 'Plumber (200m)'),
                    ),
                    Positioned(
                      right: 70 - _mapOffset.dx,
                      bottom: 250 - _mapOffset.dy,
                      child: _buildAroundMarker(context, icon: Icons.construction_rounded, color: Colors.green, label: 'Carpenter (450m)'),
                    ),
                    Positioned(
                      left: 90 + _mapOffset.dx,
                      bottom: 180 - _mapOffset.dy,
                      child: _buildAroundMarker(context, icon: Icons.electric_bolt_rounded, color: Colors.amber, label: 'Electrician (800m)'),
                    ),
                  ],

                  // Active travelling worker Pin Marker (shifted by mapOffset)
                  if (!useGoogleMap && _lifecycleStatus == "travelling")
                    Positioned(
                      left: MediaQuery.of(context).size.width / 2 - 40 + _mapOffset.dx + (MediaQuery.of(context).size.width * 0.3 * (_distance / 3.1)),
                      top: MediaQuery.of(context).size.height / 2 - 30 + _mapOffset.dy + (MediaQuery.of(context).size.height * -0.3 * (_distance / 3.1)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Tech Ramana',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(Icons.engineering_rounded, color: Theme.of(context).primaryColor, size: 36),
                        ],
                      ),
                    ),

                // GPS Data HUD card (Top overlay)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: GlassContainer(
                    bgGradientColor: isDark ? const Color(0xEC111827) : Colors.white.withOpacity(0.9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gps_fixed_rounded, color: Colors.greenAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Live GPS Coordinates: ${_userLat.toStringAsFixed(6)}° N, ${_userLng.toStringAsFixed(6)}° E',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                              ),
                            ),
                            if (_isLoadingLocation)
                              const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _userAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Map HUD Zoom controls
                Positioned(
                  right: 16,
                  top: 100,
                  child: Column(
                    children: [
                      _buildMapControlButton(
                        icon: Icons.add_rounded,
                        onPressed: () {
                          setState(() {
                            if (_zoomLevel < 18) _zoomLevel += 1;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildMapControlButton(
                        icon: Icons.remove_rounded,
                        onPressed: () {
                          setState(() {
                            if (_zoomLevel > 12) _zoomLevel -= 1;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

          // Sliding details sheet based on booking lifecycle
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildDetailsCardByState(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave Session?'),
        content: const Text('The tracking is active. Leaving this screen will not cancel the job.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go(_targetDashboard);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCardByState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (_lifecycleStatus) {
      case "travelling":
        return GlassContainer(
          bgGradientColor: isDark ? const Color(0xEC1C2541) : Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Technician is Travelling',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ETA: $_eta mins',
                      style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Distance: ${_distance.toStringAsFixed(1)} KM away  •  Route: MG Road Polyline',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  _buildProfileAvatar(
                    name: 'Ch. Venkata Ramana',
                    service: 'Plumber',
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Ch. Venkata Ramana', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Verified Plumber • 4.8 ★ (34 reviews)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline_rounded, color: Theme.of(context).primaryColor),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact credentials hidden inside FIXEN for security.')),
                      );
                    },
                  )
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // Bypass travelling step for testing convenience
                  setState(() {
                    _lifecycleStatus = "arrived";
                    _distance = 0.0;
                    _eta = 0;
                  });
                },
                child: const Text('Dev Skip: Trigger Arrived state'),
              ),
            ],
          ),
        );

      case "arrived":
        return GlassContainer(
          bgGradientColor: isDark ? const Color(0xEC1C2541) : Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Technician Arrived!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Verify OTP to start the home service session.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              // Customer-side view (displays random OTP)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Share this OTP with worker:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(
                      _generatedOtp,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3, color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Worker-side view (accepts OTP input)
              const Text('Worker verification console:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _otpInputController,
                      labelText: 'Enter 4-Digit OTP',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  PrimaryButton(
                    text: 'Verify',
                    width: 90,
                    onPressed: _verifyOtpCode,
                  ),
                ],
              ),
            ],
          ),
        );

      case "progress":
        return GlassContainer(
          bgGradientColor: isDark ? const Color(0xEC1C2541) : Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Service In Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Rajesh Kumar is working on: Kitchen Pipe Burst', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text(
                '•  Session started: 01 min ago\n•  Technician will notify when done',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Complete Service (Worker Side)',
                onPressed: _completeService,
              ),
            ],
          ),
        );

      case "completed":
        final isWorker = ref.read(authNotifierProvider).user?.role == 'worker';
        return GlassContainer(
          bgGradientColor: isDark ? const Color(0xEC1C2541) : Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isWorker ? 'Job Completed! Bill Generated' : 'Job Completed! Ready for Payment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Outfit', color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 4),
              Text(
                isWorker ? 'The customer has been billed for the service.' : 'Please review the bill and choose your payment method.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Diagnostics & Pipe Repair:', style: TextStyle(fontSize: 13)),
                  Text('₹299.00', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Material Spares (Pipe elbow joint):', style: TextStyle(fontSize: 13)),
                  Text('₹151.00', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Total Amount Due:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('₹450.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
                ],
              ),
              const SizedBox(height: 16),
              
              if (isWorker) ...[
                const Divider(height: 24),
                Row(
                  children: const [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Waiting for customer payment...',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _processPayment,
                  child: const Text('Dev: Simulate Customer Paid'),
                ),
              ] else ...[
                // Select Payment Method
                const Text('Payment Method:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPaymentRadio("UPI"),
                    const SizedBox(width: 12),
                    _buildPaymentRadio("Card"),
                    const SizedBox(width: 12),
                    _buildPaymentRadio("Cash"),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'Pay ₹450.00',
                  isLoading: _isGeneratingInvoice,
                  onPressed: _processPayment,
                ),
              ],
            ],
          ),
        );

      case "paid":
        final isWorker = ref.read(authNotifierProvider).user?.role == 'worker';
        return GlassContainer(
          bgGradientColor: isDark ? const Color(0xEC1C2541) : Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isWorker ? 'Job Completed & Paid! 🎉' : 'Payment Successful! Bill Paid.',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (!isWorker) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Downloading Invoice PDF...')),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Download Invoice'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invoice emailed successfully.')),
                          );
                        },
                        icon: const Icon(Icons.email_outlined, size: 16),
                        label: const Text('Email Invoice'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              
              // Rate technician or customer
              Text(
                isWorker ? 'Rate G Bhanu Shankar (Customer):' : 'Rate Rajesh Kumar:',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _commentController,
                labelText: isWorker ? 'Write customer feedback (Optional)' : 'Write a review (Optional)',
                hintText: isWorker ? 'Share your experience with this customer...' : 'Share your experience...',
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: isWorker ? 'Submit Rating & Return' : 'Submit Feedback',
                onPressed: _submitReview,
              ),
              if (!isWorker) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Navigate to reporting
                      _showReportWorkerDialog(context);
                    },
                    child: const Text('Report Worker / Dispute Payment', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        );

      default:
        return Container();
    }
  }

  Widget _buildPaymentRadio(String value) {
    final isSelected = _selectedPaymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.15) : Colors.transparent,
            border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReportWorkerDialog(BuildContext context) {
    final reasonController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Report Worker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: reasonController, labelText: 'Reason (e.g. Overcharged, Behaviour)'),
              const SizedBox(height: 12),
              CustomTextField(controller: descController, labelText: 'Description', maxLines: 3),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dispute Report submitted to FIXEN Office.')),
                );
                context.go(_targetDashboard);
              },
              child: const Text('Submit Dispute'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAroundMarker(BuildContext context, {required IconData icon, required Color color, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ],
    );
  }

  Widget _buildMapControlButton({required IconData icon, required VoidCallback onPressed}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 20),
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

class _LiveMapPainter extends CustomPainter {
  final bool isDark;
  final double userLat;
  final double userLng;
  final double workerLatOffset;
  final double workerLngOffset;
  final double zoomLevel;
  final String status;
  final Offset mapOffset;

  _LiveMapPainter({
    required this.isDark,
    required this.userLat,
    required this.userLng,
    required this.workerLatOffset,
    required this.workerLngOffset,
    required this.zoomLevel,
    required this.status,
    required this.mapOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(mapOffset.dx, mapOffset.dy);

    final center = Offset(size.width / 2, size.height / 2);
    final scale = zoomLevel / 15.0;

    // Draw background streets grid (aesthetic)
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.015)
      ..strokeWidth = 1.0;
      
    final double step = 30.0 * scale;
    for (double x = -size.width; x < size.width * 2; x += step) {
      canvas.drawLine(Offset(x, -size.height), Offset(x, size.height * 2), gridPaint);
    }
    for (double y = -size.height; y < size.height * 2; y += step) {
      canvas.drawLine(Offset(-size.width, y), Offset(size.width * 2, y), gridPaint);
    }

    // Draw Parks (green blocks)
    final parkPaint = Paint()
      ..color = isDark ? const Color(0xFF1E3F20).withOpacity(0.4) : const Color(0xFFE8F5E9)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - 220 * scale, center.dy + 80 * scale, 120 * scale, 80 * scale),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx + 150 * scale, center.dy - 180 * scale, 90 * scale, 60 * scale),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    // Draw Water Bodies (blue paths)
    final waterPaint = Paint()
      ..color = isDark ? const Color(0xFF1D3557).withOpacity(0.6) : const Color(0xFFE0F2FE)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(center.dx - 180 * scale, center.dy - 120 * scale), 45 * scale, waterPaint);

    // Draw Buildings / Urban blocks (filled grey rounded rects)
    final buildPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;
    final buildStroke = Paint()
      ..color = isDark ? Colors.white10 : Colors.black.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    void drawBuilding(double x, double y, double w, double h) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx + x * scale, center.dy + y * scale, w * scale, h * scale),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, buildPaint);
      canvas.drawRRect(rect, buildStroke);
    }

    drawBuilding(-120, -50, 40, 30);
    drawBuilding(-70, -50, 35, 30);
    drawBuilding(-120, -10, 40, 30);
    drawBuilding(-70, -10, 35, 30);

    drawBuilding(60, 40, 45, 35);
    drawBuilding(115, 40, 40, 35);
    drawBuilding(60, 85, 45, 30);

    // Draw Main Roads (thick solid lines)
    final roadBackgroundPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadBorderPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawRoad(Path path, double width) {
      canvas.drawPath(path, roadBorderPaint..strokeWidth = (width + 2) * scale);
      canvas.drawPath(path, roadBackgroundPaint..strokeWidth = width * scale);
    }

    final roadPath1 = Path()
      ..moveTo(center.dx - size.width, center.dy)
      ..lineTo(center.dx + size.width, center.dy);

    final roadPath2 = Path()
      ..moveTo(center.dx, center.dy - size.height)
      ..lineTo(center.dx, center.dy + size.height);

    final roadPath3 = Path()
      ..moveTo(center.dx - size.width, center.dy - 120 * scale)
      ..quadraticBezierTo(center.dx - 100 * scale, center.dy - 100 * scale, center.dx + size.width, center.dy - 200 * scale);

    drawRoad(roadPath1, 14);
    drawRoad(roadPath2, 14);
    drawRoad(roadPath3, 10);

    // Draw route polyline from worker to user
    if (status == "travelling") {
      final routePaint = Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      
      final workerPos = Offset(
        center.dx + (size.width * 0.3 * (workerLatOffset / 0.015)),
        center.dy + (size.height * -0.3 * (workerLngOffset / 0.015)),
      );
      
      canvas.drawLine(workerPos, center, routePaint);
    }

    // Draw Road Labels
    const textStyle = TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold);
    void drawText(String text, double x, double y, double rotationAngle) {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      
      canvas.save();
      canvas.translate(center.dx + x * scale, center.dy + y * scale);
      canvas.rotate(rotationAngle);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    drawText("Arundelpet Main Rd", -180, 4, 0);
    drawText("Brodipet 4th Lane", -6, -200, 3.1415 / 2);
    drawText("Guntur Bypass Link", 120, -185, -0.08);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiveMapPainter oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.userLat != userLat ||
      oldDelegate.userLng != userLng ||
      oldDelegate.workerLatOffset != workerLatOffset ||
      oldDelegate.workerLngOffset != workerLngOffset ||
      oldDelegate.zoomLevel != zoomLevel ||
      oldDelegate.status != status ||
      oldDelegate.mapOffset != mapOffset;
}
