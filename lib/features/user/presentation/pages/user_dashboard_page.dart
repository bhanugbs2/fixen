import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../common/widgets/custom_text_field.dart';
import '../../../../common/widgets/glass_container.dart';
import '../../../../common/widgets/primary_button.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../models/user_model.dart';

class UserDashboardPage extends ConsumerStatefulWidget {
  const UserDashboardPage({super.key});

  @override
  ConsumerState<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends ConsumerState<UserDashboardPage> {
  int _currentIndex = 0;
  String _currentAddress = "Locating address...";
  bool _isLoadingLocation = false;
  bool _profileSeeded = false;
  String _profileName = 'G Bhanu Shankar';
  String _profileEmail = 'bhanushankargbs@gmail.com';
  String _profilePhone = '+919876543211';
  String _savedAddress = 'Flat 302, Brodipet, Guntur, Andhra Pradesh';
  String _paymentMethod = 'UPI - bhanushankar@upi';
  bool _pushAlerts = true;
  bool _darkPreference = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoadingLocation = true;
      _currentAddress = "Fetching GPS location...";
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = "Location services disabled.";
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = "Location permission denied.";
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = "Location permission permanently denied.";
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          setState(() {
            _currentAddress = "${place.name}, ${place.subLocality}, ${place.locality} - ${place.postalCode}";
            _isLoadingLocation = false;
          });
        } else {
          setState(() {
            _currentAddress = "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
            _isLoadingLocation = false;
          });
        }
      } catch (_) {
        setState(() {
          _currentAddress = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = "Brodipet, Guntur, Andhra Pradesh";
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    if (!_profileSeeded && user != null) {
      _profileSeeded = true;
      _profileName = user.name.isNotEmpty ? user.name : _profileName;
      _profileEmail = user.email.isNotEmpty ? user.email : _profileEmail;
      _profilePhone = user.mobileNumber.isNotEmpty ? user.mobileNumber : _profilePhone;
      _savedAddress = user.address.isNotEmpty ? user.address : _savedAddress;
    }

    final tabs = [
      _buildHomeTab(context, _profileName),
      _buildHistoryTab(context),
      _buildNotificationsTab(context),
      _buildProfileTab(context, user),
    ];

    return Scaffold(
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history_rounded), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications_rounded), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
      body: tabs[_currentIndex],
    );
  }

  // --- HOME TAB ---
  Widget _buildHomeTab(BuildContext context, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _determinePosition,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Location
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $name 👋',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: Theme.of(context).primaryColor, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _currentAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            if (_isLoadingLocation)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location_rounded),
                    onPressed: _determinePosition,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Search Input
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C2541) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for electrician, plumber...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Offers banner (Carousel stub)
              Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.handyman_rounded,
                        size: 160,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'MONSOON OFFER',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Flat 20% Off on Plumbers',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Verified experts starting at \$299',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 3 Service categories (ONLY these three)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Our Verified Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildServiceCard(context, 'Electrician', '⚡', const Color(0xFFF59E0B)),
                  const SizedBox(width: 12),
                  _buildServiceCard(context, 'Plumber', '🚰', const Color(0xFF0EA5E9)),
                  const SizedBox(width: 12),
                  _buildServiceCard(context, 'Carpenter', '🪚', const Color(0xFF10B981)),
                ],
              ),
              const SizedBox(height: 28),

              // Recent bookings widget
              _buildRecentBookingsCard(context),
              const SizedBox(height: 28),

              // Popular workers
              Text(
                'Top Verified Techs Nearby',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              _buildWorkerListItem(
                context,
                name: 'T. Sai Kumar',
                service: 'Electrician',
                rating: '4.9 (48)',
                experience: '6 yrs',
                distance: '1.2 km',
                imageUrl: '',
              ),
              const SizedBox(height: 12),
              _buildWorkerListItem(
                context,
                name: 'Ch. Venkata Ramana',
                service: 'Plumber',
                rating: '4.9 (52)',
                experience: '8 yrs',
                distance: '0.8 km',
                imageUrl: '',
              ),
              const SizedBox(height: 12),
              _buildWorkerListItem(
                context,
                name: 'K. Srinivasa Rao',
                service: 'Carpenter',
                rating: '4.8 (64)',
                experience: '9 yrs',
                distance: '1.1 km',
                imageUrl: '',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, String icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Route to request service screen, passing the selected category
          context.push('/request-service?category=$title');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2541) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBookingsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2541) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Travelling',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _buildProfileAvatar(
                name: 'Rajesh Kumar',
                service: 'Plumber',
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Rajesh Kumar (Plumber)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('ETA: 12 mins • 3.1 KM away', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              PrimaryButton(
                text: 'Track',
                width: 72,
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  context.push('/live-tracking/mock_booking_123');
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWorkerListItem(
    BuildContext context, {
    required String name,
    required String service,
    required String rating,
    required String experience,
    required String distance,
    required String imageUrl,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2541) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          _buildProfileAvatar(
            name: name,
            service: service,
            radius: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text('$service • $experience Exp', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(rating, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(distance, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Available', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // --- HISTORY TAB ---
  Widget _buildHistoryTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Booking History'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHistoryItem(
            context,
            bookingId: 'BK-5896',
            service: 'Electrician',
            worker: 'Karan Sharma',
            date: 'July 01, 2026',
            price: '₹450',
            status: 'Completed',
            canInvoice: true,
            canReview: true,
          ),
          const SizedBox(height: 16),
          _buildHistoryItem(
            context,
            bookingId: 'BK-4112',
            service: 'Plumber',
            worker: 'Rajesh Kumar',
            date: 'June 28, 2026',
            price: '₹350',
            status: 'Cancelled',
            canInvoice: false,
            canReview: false,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context, {
    required String bookingId,
    required String service,
    required String worker,
    required String date,
    required String price,
    required String status,
    required bool canInvoice,
    required bool canReview,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = status == 'Completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2541) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ID: $bookingId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('$service Service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Technician: $worker • $date', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Total Paid: $price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (canInvoice)
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading PDF Invoice for $bookingId (Simulated)')),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Invoice'),
                ),
              const SizedBox(width: 12),
              if (canReview)
                ElevatedButton(
                  onPressed: () => context.push('/reviews/$bookingId'),
                  child: const Text('Write Review'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- NOTIFICATIONS TAB ---
  Widget _buildNotificationsTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNotificationItem(
            context,
            title: 'Quote Received!',
            description: 'Karan Sharma submitted a quotation of ₹450 for your Electrician request.',
            time: '10 mins ago',
            icon: Icons.percent_rounded,
          ),
          const SizedBox(height: 16),
          _buildNotificationItem(
            context,
            title: 'Booking Confirmed',
            description: 'Your Plumber service booking with Rajesh Kumar has been confirmed for today.',
            time: '2 hours ago',
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required String title,
    required String description,
    required String time,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2541) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3)),
                const SizedBox(height: 8),
                Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- PROFILE TAB ---
  Widget _buildProfileTab(BuildContext context, UserModel? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileAvatar(
              name: _profileName,
              service: user?.role ?? 'user',
              radius: 50,
            ),
            const SizedBox(height: 16),
            Text(
              _profileName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _profileEmail,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildProfileMenuItem(
              context,
              icon: Icons.person_outline_rounded,
              title: 'Edit Personal Details',
              onTap: _showEditPersonalDetailsSheet,
            ),
            _buildProfileMenuItem(
              context,
              icon: Icons.map_outlined,
              title: 'Saved Addresses',
              onTap: _showSavedAddressesSheet,
            ),
            _buildProfileMenuItem(
              context,
              icon: Icons.payment_rounded,
              title: 'Payment Methods',
              onTap: _showPaymentMethodsSheet,
            ),
            _buildProfileMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: 'App Settings',
              onTap: _showAppSettingsSheet,
            ),
            _buildProfileMenuItem(
              context,
              icon: Icons.feedback_outlined,
              title: 'Submit Complaint',
              onTap: _showComplaintSheet,
            ),
            _buildProfileMenuItem(
              context, 
              icon: Icons.logout_rounded, 
              title: 'Log Out', 
              color: Colors.red,
              onTap: () async {
                await ref.read(authNotifierProvider.notifier).logout();
                if (mounted) {
                  context.go('/role-selection');
                }
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? color,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      title: Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clicked $title (Simulated)')),
        );
      },
    );
  }

  void _showEditPersonalDetailsSheet() {
    final nameController = TextEditingController(text: _profileName);
    final emailController = TextEditingController(text: _profileEmail);
    final phoneController = TextEditingController(text: _profilePhone);

    _showProfileSheet(
      title: 'Edit Personal Details',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(controller: nameController, labelText: 'Full Name', prefixIcon: Icons.person_outline_rounded),
          const SizedBox(height: 14),
          CustomTextField(
            controller: emailController,
            labelText: 'Email Address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: phoneController,
            labelText: 'Mobile Number',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            text: 'Save Details',
            onPressed: () {
              setState(() {
                _profileName = nameController.text.trim().isEmpty ? _profileName : nameController.text.trim();
                _profileEmail = emailController.text.trim().isEmpty ? _profileEmail : emailController.text.trim();
                _profilePhone = phoneController.text.trim().isEmpty ? _profilePhone : phoneController.text.trim();
              });
              Navigator.pop(context);
              _showSavedSnack('Personal details updated.');
            },
          ),
        ],
      ),
    );
  }

  void _showSavedAddressesSheet() {
    final addressController = TextEditingController(text: _savedAddress);

    _showProfileSheet(
      title: 'Saved Addresses',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: addressController,
            labelText: 'Home Address',
            prefixIcon: Icons.home_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.my_location_rounded, color: Theme.of(context).primaryColor),
            title: const Text('Use Current GPS Location'),
            subtitle: Text(_currentAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () async {
              await _determinePosition();
              addressController.text = _currentAddress;
            },
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            text: 'Save Address',
            onPressed: () {
              setState(() {
                _savedAddress = addressController.text.trim().isEmpty ? _savedAddress : addressController.text.trim();
              });
              Navigator.pop(context);
              _showSavedSnack('Saved address updated.');
            },
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodsSheet() {
    var selected = _paymentMethod.startsWith('Card')
        ? 'Card'
        : _paymentMethod.startsWith('Cash')
            ? 'Cash'
            : 'UPI';
    final upiController = TextEditingController(
      text: selected == 'UPI' ? _paymentMethod.replaceFirst('UPI - ', '') : 'bhanushankar@upi',
    );
    final cardController = TextEditingController(text: '**** **** **** 4242');

    _showProfileSheet(
      title: 'Payment Methods',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          Widget option(String value, IconData icon) {
            final isSelected = selected == value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
              title: Text(value),
              trailing: Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
              onTap: () => setModalState(() => selected = value),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              option('UPI', Icons.qr_code_rounded),
              if (selected == 'UPI') CustomTextField(controller: upiController, labelText: 'UPI ID'),
              option('Card', Icons.credit_card_rounded),
              if (selected == 'Card') CustomTextField(controller: cardController, labelText: 'Card Number'),
              option('Cash', Icons.payments_outlined),
              const SizedBox(height: 18),
              PrimaryButton(
                text: 'Save Payment Method',
                onPressed: () {
                  setState(() {
                    if (selected == 'UPI') {
                      _paymentMethod = 'UPI - ${upiController.text.trim()}';
                    } else if (selected == 'Card') {
                      _paymentMethod = 'Card - ${cardController.text.trim()}';
                    } else {
                      _paymentMethod = 'Cash on service completion';
                    }
                  });
                  Navigator.pop(context);
                  _showSavedSnack('Payment method updated.');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAppSettingsSheet() {
    _showProfileSheet(
      title: 'App Settings',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Push Notifications'),
                subtitle: const Text('Booking, quote, payment, and service alerts'),
                value: _pushAlerts,
                onChanged: (value) {
                  setState(() => _pushAlerts = value);
                  setModalState(() {});
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Prefer Dark Mode'),
                subtitle: const Text('Saved as a profile preference'),
                value: _darkPreference,
                onChanged: (value) {
                  setState(() => _darkPreference = value);
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                text: 'Done',
                onPressed: () {
                  Navigator.pop(context);
                  _showSavedSnack('Settings saved.');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProfileSheet({required String title, required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComplaintSheet() {
    final complaintController = TextEditingController();
    _showProfileSheet(
      title: 'File a Complaint / Feedback',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'We value your feedback. Please submit any complaints or issues below, and the FIXEN support team will get in touch.',
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: complaintController,
            labelText: 'Details of Complaint',
            hintText: 'Enter complaint details here...',
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'Submit Complaint',
            onPressed: () {
              Navigator.pop(context);
              _showSavedSnack('Complaint submitted successfully to FIXEN office.');
            },
          ),
        ],
      ),
    );
  }

  void _showSavedSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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
