import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/bottom_nav_bar.dart';
import '../payment_rating/withdraw_earning_page.dart';
import '../payment_rating/employer_transfer_page.dart';
import '../payment_rating/earnings_history_page.dart';
import '../payment_rating/employer_review_page.dart';
import 'auth_tabs_page.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../dev/seed_page.dart';
import 'edit_profile_page.dart';
import 'package:flutter/foundation.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedNavIndex = 3; // Profile tab
  final _service = FirestoreService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final p = await _service.getUserProfile(uid);
    setState(() {
      _nameCtrl.text = p?.displayName ?? '';
      _phoneCtrl.text = p?.phone ?? '';
      _locationCtrl.text = p?.location ?? '';
      _skillsCtrl.text = (p?.skills ?? []).join(', ');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) {
            return const AuthTabsPage();
          }
          return CustomScrollView(
            slivers: [
              // Modern App Bar with gradient
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: const Color(0xFF0F1E3C),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F1E3C), Color(0xFF1A3A5C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  title: const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  centerTitle: true,
                ),
                actions: [
                  IconButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white70,
                    ),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Card
                      StreamBuilder<UserProfile?>(
                        stream: _service.streamUserProfile(user.uid),
                        builder: (context, snap) {
                          final p = snap.data;
                          return _buildModernProfileCard(p);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Balance Card
                      StreamBuilder<UserProfile?>(
                        stream: _service.streamUserProfile(user.uid),
                        builder: (context, snapRole) {
                          final role = snapRole.data?.role ?? UserRole.student;
                          return _buildBalanceCard(user.uid, role);
                        },
                      ),
                      const SizedBox(height: 28),

                      // Quick Actions Section
                      StreamBuilder<UserProfile?>(
                        stream: _service.streamUserProfile(user.uid),
                        builder: (context, snapRole) {
                          final role = snapRole.data?.role ?? UserRole.student;
                          return _buildQuickActions(role);
                        },
                      ),

                      // Ratings section for students
                      StreamBuilder<UserProfile?>(
                        stream: _service.streamUserProfile(user.uid),
                        builder: (context, snapRole) {
                          final role = snapRole.data?.role ?? UserRole.student;
                          if (role == UserRole.student) {
                            return Column(
                              children: [
                                const SizedBox(height: 28),
                                _buildModernRatingsCard(),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Debug section
                      if (kDebugMode) ...[
                        const SizedBox(height: 20),
                        _buildMinimalActionTile(
                          icon: Icons.developer_mode,
                          label: 'Seed Demo Data',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SeedPage()),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
          _navigateBottomTab(index);
        },
      ),
    );
  }

  Widget _buildModernProfileCard(UserProfile? p) {
    final initials = (p?.displayName.isNotEmpty == true)
        ? p!.displayName
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
              .take(2)
              .join()
        : (p?.email.isNotEmpty == true ? p!.email[0].toUpperCase() : '?');
    final roleText = (p?.role == UserRole.employer) ? 'Employer' : 'Student';
    final roleColor = (p?.role == UserRole.employer)
        ? const Color(0xFF7C3AED)
        : const Color(0xFF0891B2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with gradient border
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [roleColor, roleColor.withOpacity(0.5)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF0F1E3C),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p?.displayName ?? 'Your Name',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p?.email ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleText,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Edit Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final saved = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
                if (saved == true) _loadProfile();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String uid, UserRole role) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1E3C), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1E3C).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                role == UserRole.employer
                    ? 'Wallet Balance'
                    : 'Available Earnings',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.streamTransactionsForUser(uid),
            builder: (context, snapshot) {
              double bal = 0;
              final items = snapshot.data ?? [];
              for (final m in items) {
                final v = m['amount'];
                if (v is num) bal += v.toDouble();
                if (v is String) bal += double.tryParse(v) ?? 0;
              }
              return Text(
                'RM ${bal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(UserRole role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        if (role == UserRole.student) ...[
          _buildMinimalActionTile(
            icon: Icons.history_rounded,
            label: 'Earnings History',
            subtitle: 'View your earning records',
            onTap: () => _navigateToPage(0),
          ),
          const SizedBox(height: 12),
          _buildMinimalActionTile(
            icon: Icons.account_balance_outlined,
            label: 'Withdraw Earnings',
            subtitle: 'Transfer to your bank',
            onTap: () => _navigateToPage(1),
          ),
        ],
        if (role == UserRole.employer) ...[
          _buildMinimalActionTile(
            icon: Icons.send_rounded,
            label: 'Transfer Payment',
            subtitle: 'Pay your workers',
            onTap: () => _navigateToPage(2),
          ),
          const SizedBox(height: 12),
          _buildMinimalActionTile(
            icon: Icons.star_outline_rounded,
            label: 'Rate Workers',
            subtitle: 'Give feedback to employees',
            onTap: () => _navigateToPage(3),
          ),
        ],
      ],
    );
  }

  Widget _buildMinimalActionTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E3C).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF0F1E3C), size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernRatingsCard() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Ratings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<double>(
                future: _service.getEmployeeAverageRating(uid),
                builder: (context, snapshot) {
                  final avg = snapshot.data ?? 0;
                  return Row(
                    children: [
                      Text(
                        avg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStars(avg),
                          const SizedBox(height: 4),
                          Text(
                            'Average rating',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade100),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _service.streamEmployeeRatings(uid),
                builder: (context, snapshot) {
                  final ratings = snapshot.data ?? [];
                  final displayed = ratings.take(3).toList();
                  if (displayed.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No reviews yet',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: displayed.map((r) {
                      final avg = (r['average'] as num?)?.toDouble() ?? 0;
                      final comment = r['comment']?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    avg.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                comment.isNotEmpty ? comment : 'No comment',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i + 1 <= rating.round();
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        // Earnings History
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EarningsHistoryPage()),
        );
        break;
      case 1:
        // Withdraw Earnings
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WithdrawEarningPage()),
        );
        break;
      case 2:
        // Transfer
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EmployerTransferPage()),
        );
        break;
      case 3:
        // Rating
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EmployerReviewPage()),
        );
        break;
    }
  }

  void _navigateBottomTab(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/discovery');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/my_jobs');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/message');
        break;
      case 3:
        // Already on Profile
        break;
    }
  }
}
