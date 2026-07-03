import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/glass_container.dart';
import '../../../../common/widgets/primary_button.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock list of workers pending verification
  List<Map<String, dynamic>> _pendingWorkers = [
    {
      'id': 'w_pending_1',
      'name': 'Rahul Verma',
      'service': 'Electrician',
      'phone': '+919988776655',
      'govId': 'GOV-E-45892',
      'experience': 5,
    },
    {
      'id': 'w_pending_2',
      'name': 'Subhash Pal',
      'service': 'Carpenter',
      'phone': '+918877665544',
      'govId': 'GOV-C-89745',
      'experience': 8,
    }
  ];

  // Mock list of user complaints/reports
  List<Map<String, dynamic>> _userReports = [
    {
      'id': 'rep_1',
      'userName': 'Anita Desai',
      'workerName': 'T. Sai Kumar',
      'reason': 'Overcharged price',
      'description': 'Technician Sai Kumar quoted 450 but forced to pay 700 at completion pointing to extra materials which were never bought.',
      'bookingRef': 'BK-5896',
      'status': 'Pending',
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _verifyWorker(String id, String action) {
    setState(() {
      _pendingWorkers.removeWhere((w) => w['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Worker status updated: $action'),
        backgroundColor: action == 'Approved' ? Colors.green : Colors.red,
      ),
    );
  }

  void _resolveReport(String id, String action) {
    setState(() {
      _userReports.removeWhere((r) => r['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report action taken: $action'),
        backgroundColor: action == 'Suspended Worker' ? Colors.redAccent : Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FIXEN Office Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.go('/role-selection'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Analytics'),
            Tab(icon: Icon(Icons.verified_user_rounded), text: 'Worker Approvals'),
            Tab(icon: Icon(Icons.gavel_rounded), text: 'User Disputes'),
            Tab(icon: Icon(Icons.category_rounded), text: 'Categories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalyticsTab(),
          _buildApprovalsTab(),
          _buildDisputesTab(),
          _buildCategoriesTab(),
        ],
      ),
    );
  }

  // --- ANALYTICS TAB ---
  Widget _buildAnalyticsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Daily Performance Metrics 📈',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard("Daily Users", "1,204", "+12%", Colors.teal),
              const SizedBox(width: 16),
              _buildMetricCard("Bookings", "482", "+8%", Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard("Gross Revenue", "₹1,48,200", "+15%", Colors.amber),
              const SizedBox(width: 16),
              _buildMetricCard("Office Commission", "₹14,820", "+15%", Colors.green),
            ],
          ),
          const SizedBox(height: 28),
          
          Text(
            'Service Category Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 16),
          _buildProgressIndicatorTile("Electrician (⚡)", 0.45, "45% of jobs", Colors.amber),
          const SizedBox(height: 12),
          _buildProgressIndicatorTile("Plumber (🚰)", 0.35, "35% of jobs", Colors.blue),
          const SizedBox(height: 12),
          _buildProgressIndicatorTile("Carpenter (🪚)", 0.20, "20% of jobs", Colors.green),
          const SizedBox(height: 28),

          // Growth stats card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C2541) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Quality Indicators', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 12),
                Text('•  Average Tech Rating: 4.84 ★', style: TextStyle(fontSize: 13, height: 1.5)),
                Text('•  Cancellation rate: 2.1%', style: TextStyle(fontSize: 13, height: 1.5)),
                Text('•  Average ETA: 14 mins', style: TextStyle(fontSize: 13, height: 1.5)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, String change, Color color) {
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
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              val,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicatorTile(String service, double value, String desc, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(service, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
        )
      ],
    );
  }

  // --- APPROVALS TAB ---
  Widget _buildApprovalsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_pendingWorkers.isEmpty) {
      return const Center(child: Text('No workers pending verification.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _pendingWorkers.length,
      itemBuilder: (context, index) {
        final worker = _pendingWorkers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2541) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(worker['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      worker['service'],
                      style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text('•  Phone: ${worker['phone']}', style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5)),
              Text('•  Government ID: ${worker['govId']}', style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5)),
              Text('•  Experience Claimed: ${worker['experience']} years', style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _verifyWorker(worker['id'], 'Rejected'),
                      child: const Text('Reject ID'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _verifyWorker(worker['id'], 'Approved'),
                      child: const Text('Approve Worker'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DISPUTES TAB ---
  Widget _buildDisputesTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_userReports.isEmpty) {
      return const Center(child: Text('No active user complaints.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _userReports.length,
      itemBuilder: (context, index) {
        final report = _userReports[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2541) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dispute Ref: ${report['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Unresolved',
                      style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text('User: ${report['userName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text('Reported Worker: ${report['workerName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Booking Ref: ${report['bookingRef']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              Text('Reason: ${report['reason']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.redAccent)),
              const SizedBox(height: 6),
              Text(
                report['description'],
                style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _resolveReport(report['id'], 'Rejected Report'),
                      child: const Text('Dismiss Dispute'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _resolveReport(report['id'], 'Suspended Worker'),
                      child: const Text('Suspend Worker'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- CATEGORIES TAB ---
  Widget _buildCategoriesTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Supported Service Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 8),
          const Text(
            'FIXEN platform operates exclusively for the following categories. Dynamic creation of other services is disabled for quality control.',
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 24),
          _buildFixedCategoryTile("⚡ Electrician"),
          const SizedBox(height: 12),
          _buildFixedCategoryTile("🚰 Plumber"),
          const SizedBox(height: 12),
          _buildFixedCategoryTile("🪚 Carpenter"),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Administrative rules dictate that no other service types may be added to ensure the strict Government Verification process can be carried out.',
                    style: TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFixedCategoryTile(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2541) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Icon(Icons.lock_rounded, color: Colors.grey, size: 18),
        ],
      ),
    );
  }
}
