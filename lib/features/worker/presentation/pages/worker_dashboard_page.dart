import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/user_model.dart';
import '../../../../common/widgets/glass_container.dart';
import '../../../../common/widgets/fixen_map_view.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../../common/widgets/custom_text_field.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../data/local/secure_storage_helper.dart';
import '../../../../data/remote/api_client.dart';
import '../../../../data/remote/socket_service.dart';

class WorkerDashboardPage extends ConsumerStatefulWidget {
  const WorkerDashboardPage({super.key});

  @override
  ConsumerState<WorkerDashboardPage> createState() => _WorkerDashboardPageState();
}

class _WorkerDashboardPageState extends ConsumerState<WorkerDashboardPage> {
  int _currentIndex = 0;
  bool _isActive = true;
  bool _isBlocked = false; // Blocked status triggers unpaid commission banner
  double _commissionDue = 450.00;
  double _monthlyEarnings = 4500.00;
  
  // Simulated incoming booking request
  bool _hasIncomingRequest = false;
  final _quotePriceController = TextEditingController();
  final _quoteEtaController = TextEditingController();

  String _incomingBookingId = '';
  String _incomingCategory = 'Plumber';
  String _incomingDesc = 'Kitchen pipe burst, continuous leakage';
  String _incomingUserName = 'G Bhanu Shankar';
  String _incomingUserMobile = '+919876543211';
  double _incomingUserLat = 16.3067;
  double _incomingUserLng = 80.4365;

  final Map<String, bool> _languagesSelected = {
    'Telugu': true,
    'Hindi': false,
    'English': true,
  };

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  Future<void> _connectSocket() async {
    final secureStorage = SecureStorageHelper();
    final token = await secureStorage.getAccessToken();
    if (token != null) {
      final socketService = ref.read(socketServiceProvider);
      socketService.initialize(token);

      socketService.on('bookingRequest', (data) {
        if (mounted && _isActive && !_isBlocked) {
          setState(() {
            _hasIncomingRequest = true;
            _incomingBookingId = data['bookingId'] ?? '';
            _incomingCategory = data['category'] ?? 'Plumber';
            _incomingDesc = data['description'] ?? '';
            _incomingUserName = data['user']?['name'] ?? 'Client';
            _incomingUserMobile = data['user']?['mobileNumber'] ?? '';
            final loc = data['location'];
            if (loc != null) {
              _incomingUserLat = double.tryParse(loc['latitude']?.toString() ?? '') ?? 16.3067;
              _incomingUserLng = double.tryParse(loc['longitude']?.toString() ?? '') ?? 80.4365;
            }
          });
        }
      });

      socketService.on('quoteAccepted', (data) {
        if (mounted) {
          final bId = data['bookingId'] ?? 'mock_booking_123';
          final price = double.tryParse(data['price']?.toString() ?? '') ?? 450.0;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Quote Accepted!'),
              content: const Text('Customer accepted your quotation. Please proceed to the service location immediately.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/live-tracking/$bId?price=$price');
                  },
                  child: const Text('Start Travelling'),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _quotePriceController.dispose();
    _quoteEtaController.dispose();
    super.dispose();
  }

  void _payCommission() {
    // Show a payment sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pay Commission Due',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 8),
              Text(
                'Monthly commission (10%) calculated on your earnings of ₹${_monthlyEarnings.toStringAsFixed(0)}.',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount Due:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '₹${_commissionDue.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Select Payment Method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildPaymentOptionTile(context, icon: Icons.qr_code_rounded, name: 'UPI (GPay, PhonePe)'),
              _buildPaymentOptionTile(context, icon: Icons.credit_card_rounded, name: 'Credit / Debit Card'),
              _buildPaymentOptionTile(context, icon: Icons.account_balance_rounded, name: 'Net Banking'),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Pay Now',
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isBlocked = false;
                    _commissionDue = 0.00;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment Successful! Account reactivated.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOptionTile(BuildContext context, {required IconData icon, required String name}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2541) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 22),
          const SizedBox(width: 16),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          const Icon(Icons.radio_button_off_rounded, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Future<void> _submitQuotation() async {
    if (_quotePriceController.text.isEmpty || _quoteEtaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out price and ETA estimates.')),
      );
      return;
    }

    final price = double.tryParse(_quotePriceController.text.trim()) ?? 0.0;
    final eta = int.tryParse(_quoteEtaController.text.trim()) ?? 0;

    setState(() {
      _hasIncomingRequest = false;
    });

    try {
      final apiClient = ApiClient();
      await apiClient.post('/bookings/$_incomingBookingId/quote', data: {
        'price': price,
        'eta': eta,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quotation of ₹${price.toStringAsFixed(2)} sent to customer.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Fallback for simulation/testing if connection fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent quote (Local Sim): ₹${price.toStringAsFixed(2)}.'),
          backgroundColor: Colors.teal,
        ),
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _showJobAcceptedDialog(price: price);
        }
      });
    }
  }

  void _showJobAcceptedDialog({double price = 450.0}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quote Accepted!'),
        content: const Text('Customer accepted your quotation. Please proceed to the service location immediately.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Route to tracking page
              context.go('/live-tracking/${_incomingBookingId.isEmpty ? "mock_booking_123" : _incomingBookingId}?price=$price');
            },
            child: const Text('Start Travelling'),
          ),
        ],
      ),
    );
  }

  void _showComplaintDialog(BuildContext context) {
    final complaintController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('File a Complaint / Feedback'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Submit any issues, disputes, or complaints directly to the FIXEN admin team.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: complaintController,
                labelText: 'Details of Complaint',
                hintText: 'Enter complaint details here...',
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Complaint submitted successfully to FIXEN office.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomeTab(BuildContext context, UserModel? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // Base Body Scroll
        SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Status Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Rajesh Kumar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Service: ${user?.service ?? 'Plumber'}  •  Rating: ${user?.rating ?? 4.8} ★',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _isActive,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: _isBlocked 
                        ? null 
                        : (val) {
                            setState(() {
                              _isActive = val;
                            });
                          },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _isActive ? '🟢 Active & receiving job requests' : '🔴 Offline. Open switch to receive bookings',
                style: TextStyle(fontSize: 13, color: _isActive ? Colors.green : Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Blocked Simulation Button
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isBlocked = !_isBlocked;
                    if (_isBlocked) {
                      _isActive = false;
                    }
                  });
                },
                child: Text(_isBlocked ? 'Dev: Unblock Worker' : 'Dev: Block Worker (Unpaid Commission)'),
              ),
              const SizedBox(height: 24),

              // Statistics
              Text(
                'Your Performance Metrics',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard(context, title: "Today's Jobs", val: "3", icon: Icons.today_rounded, color: Colors.teal),
                  const SizedBox(width: 16),
                  _buildStatCard(context, title: "Completed", val: "148", icon: Icons.task_alt_rounded, color: Colors.blue),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard(context, title: "Monthly Earnings", val: "₹$_monthlyEarnings", icon: Icons.payments_rounded, color: Colors.amber),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    context, 
                    title: "Commission Due", 
                    val: "₹$_commissionDue", 
                    icon: Icons.receipt_long_rounded, 
                    color: Colors.redAccent,
                    hasAction: _commissionDue > 0,
                    onActionPressed: _payCommission,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Location / Map Preview
              Text(
                'Your Active GPS Radius (5 KM)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 180,
                  child: FixenMapView(
                    latitude: 16.3067,
                    longitude: 80.4365,
                    zoom: 13.5,
                    liteMode: true,
                    markers: const [
                      FixenMapMarker(
                        id: 'job_request_1',
                        label: 'Kitchen Pipe Burst',
                        latitude: 16.3120,
                        longitude: 80.4418,
                      ),
                      FixenMapMarker(
                        id: 'job_request_2',
                        label: 'Fan repair',
                        latitude: 16.2998,
                        longitude: 80.4311,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // --- BLOCKING OVERLAY SCREEN ---
        if (_isBlocked)
          Container(
            color: Colors.black.withOpacity(0.85),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block_rounded, color: Colors.redAccent, size: 80),
                    const SizedBox(height: 24),
                    const Text(
                      'Account Temporarily Blocked',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Account blocked until commission payment. You cannot go active, appear on maps, or accept bookings until the 10% monthly commission due is paid.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Commission Due:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                          Text(
                            '₹${_commissionDue.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    PrimaryButton(
                      text: 'Pay Due Commission',
                      onPressed: _payCommission,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // --- FLOATING INCOMING REQUEST SHEET ---
        if (_hasIncomingRequest && !_isBlocked)
          Container(
            color: Colors.black54,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C2541) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'INCOMING JOB',
                                  style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Text('1.5 KM away', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Problem: Kitchen Pipe Burst',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Outfit'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The main water inlet pipe in the kitchen is leaking heavily from the elbow joint. Floor is getting flooded. Need emergency repair.',
                        style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.audiotrack_rounded, color: Theme.of(context).primaryColor, size: 18),
                          const SizedBox(width: 8),
                          const Text('Voice note attachment included (12s)', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _quotePriceController,
                              labelText: 'Your Price (₹)',
                              hintText: 'e.g. 450',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _quoteEtaController,
                              labelText: 'ETA (Mins)',
                              hintText: 'e.g. 15',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                setState(() {
                                  _hasIncomingRequest = false;
                                });
                              },
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _submitQuotation,
                              child: const Text('Submit Quote'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mockJobs = [
      {
        'category': 'Plumbing Repair',
        'address': 'Brodipet 4th Lane, Guntur',
        'date': '05 July 2026',
        'price': '₹350.00',
      },
      {
        'category': 'Switchboard Repair',
        'address': 'Arundelpet Main Rd, Guntur',
        'date': '01 July 2026',
        'price': '₹299.00',
      }
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: mockJobs.length,
      itemBuilder: (context, index) {
        final job = mockJobs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x0EFFFFFF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(job['category']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(job['price']!, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Text(job['address']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(job['date']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('COMPLETED', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(BuildContext context, UserModel? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile pic
          Center(
            child: Stack(
              children: [
                _buildProfileAvatar(
                  name: user?.name ?? 'Worker Profile',
                  service: user?.service ?? 'Worker',
                  radius: 46,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Ch. Venkata Ramana',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Service: ${user?.service ?? "Carpenter"}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // First profile section
          _buildSectionHeader('Personal Profile (Read Only)'),
          const SizedBox(height: 12),
          _buildReadOnlyDetailTile(
            context,
            icon: Icons.person_outline_rounded,
            label: 'Name',
            val: user?.name ?? 'Ch. Venkata Ramana',
          ),
          _buildReadOnlyDetailTile(
            context,
            icon: Icons.email_outlined,
            label: 'Email',
            val: user?.email ?? 'ramana@fixen.com',
          ),
          _buildReadOnlyDetailTile(
            context,
            icon: Icons.phone_android_rounded,
            label: 'Phone Number',
            val: user?.mobileNumber ?? '+919876543210',
            subtitle: 'Reserved number - contact office to edit',
          ),
          _buildReadOnlyDetailTile(
            context,
            icon: Icons.badge_outlined,
            label: 'Worker ID',
            val: user?.id ?? 'W-984802',
            subtitle: 'Reserved ID - contact office to edit',
          ),
          const SizedBox(height: 20),

          // Second section: Customer Care (Admin mobile number only admin can edit)
          _buildSectionHeader('Customer Care'),
          const SizedBox(height: 12),
          _buildReadOnlyDetailTile(
            context,
            icon: Icons.headset_mic_rounded,
            label: 'Support Number',
            val: '+919988776655',
            subtitle: 'Reserved for Admin (Admin only can edit)',
          ),
          const SizedBox(height: 20),

          // Third section: Language selection like TELUGU, HINDI, ENGLISH
          _buildSectionHeader('Language Settings'),
          const SizedBox(height: 12),
          _buildLanguageSelectionTile(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildReadOnlyDetailTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String val,
    String? subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x06FFFFFF) : Colors.black.withOpacity(0.015),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.orangeAccent)),
                ],
              ],
            ),
          ),
          const Icon(Icons.lock_rounded, color: Colors.grey, size: 14),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectionTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x08FFFFFF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: _languagesSelected.keys.map((lang) {
          final isSel = _languagesSelected[lang]!;
          return CheckboxListTile(
            title: Text(lang, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            value: isSel,
            activeColor: Theme.of(context).primaryColor,
            onChanged: (val) {
              setState(() {
                _languagesSelected[lang] = val ?? false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Language preference "$lang" updated.'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            controlAffinity: ListTileControlAffinity.trailing,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProfileAvatar({required String name, required String service, double radius = 28}) {
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final initials = nameParts.length > 1
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : 'W';

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.75,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final tabs = [
      _buildHomeTab(context, user),
      _buildHistoryTab(context),
      _buildProfileTab(context, user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Worker Dashboard'
              : _currentIndex == 1
                  ? 'Job History'
                  : 'Profile Settings',
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.report_problem_outlined),
              tooltip: 'Report / Complaint',
              onPressed: () => _showComplaintDialog(context),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (mounted) {
                context.go('/role-selection');
              }
            },
          )
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String val,
    required IconData icon,
    required Color color,
    bool hasAction = false,
    VoidCallback? onActionPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2541) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                if (hasAction)
                  GestureDetector(
                    onTap: onActionPressed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
                      child: const Text('Pay Due', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              val,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});

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
    
    // Draw outer rings to look like a radar
    final center = Offset(size.width / 2, size.height / 2);
    final radarPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawCircle(center, 40.0, radarPaint);
    canvas.drawCircle(center, 80.0, radarPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
