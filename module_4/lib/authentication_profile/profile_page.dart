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
import '../job_posting_management/jobs_posts.dart';
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
      backgroundColor: const Color.fromARGB(255, 250, 250, 251),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user == null) return const SizedBox.shrink();
              return IconButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Logout',
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) {
            return const AuthTabsPage();
          }
          return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<UserProfile?>(
                stream: _service.streamUserProfile(FirebaseAuth.instance.currentUser!.uid),
                builder: (context, snap) {
                  final p = snap.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(p),
                      const SizedBox(height: 16),
                      _buildInfoCard(p),
                    ],
                  );
                },
              ),
              // Hero summary card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F1E3C), Color(0xFF1D2F4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330F1E3C),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Earnings Overview',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Icon(Icons.info_outline, color: Color(0xFF9FB4FF), size: 18),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _service.streamTransactionsForUser(user.uid),
                        builder: (context, snapshot) {
                          double bal = 0;
                          final items = snapshot.data ?? [];
                          for (final m in items) {
                            final v = m['amount'];
                            if (v is num) bal += v.toDouble();
                            if (v is String) bal += double.tryParse(v) ?? 0;
                          }
                          return _miniStat(
                            title: 'Available',
                            value: 'RM ${bal.toStringAsFixed(2)}',
                            valueColor: const Color(0xFF0F1E3C),
                          );
                        },
                      ),
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<UserProfile?>(
                    stream: _service.streamUserProfile(user.uid),
                    builder: (context, snapRole) {
                      final role = snapRole.data?.role ?? UserRole.student;
                      return _miniStat(
                        title: 'Role',
                        value: role == UserRole.employer ? 'Employer' : 'Student',
                        valueColor: const Color(0xFFE05A1C),
                      );
                    },
                  ),
                ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons in a slim vertical stack
              StreamBuilder<UserProfile?>(
                stream: _service.streamUserProfile(user.uid),
                builder: (context, snapRole) {
                  final role = snapRole.data?.role ?? UserRole.student;
                  return Column(
                    children: [
                      _buildActionButton(
                        label: 'Earnings History',
                        color: const Color(0xFFF6D2B4),
                        textColor: const Color(0xFFCC4A0F),
                        onTap: () => _navigateToPage(0),
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        label: 'Withdraw Earnings',
                        color: const Color(0xFFF6D2B4),
                        textColor: const Color(0xFFCC4A0F),
                        onTap: () => _navigateToPage(1),
                      ),
                      const SizedBox(height: 12),
                      if (role == UserRole.employer)
                        _buildActionButton(
                          label: 'Top Up Balance',
                          color: const Color(0xFFF6D2B4),
                          textColor: const Color(0xFFCC4A0F),
                          onTap: () => Navigator.pushNamed(context, '/employer_topup'),
                        ),
                      if (role == UserRole.employer) const SizedBox(height: 12),
                      _buildActionButton(
                        label: 'Transfer',
                        color: const Color(0xFFC8D4FF),
                        textColor: const Color(0xFF2E3AD6),
                        onTap: () => _navigateToPage(2),
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        label: 'Rating',
                        color: const Color(0xFFC8D4FF),
                        textColor: const Color(0xFF2E3AD6),
                        onTap: () => _navigateToPage(3),
                      ),
                      const SizedBox(height: 12),
                      if (role == UserRole.employer)
                        _buildActionButton(
                          label: 'Employer Dashboard',
                          color: const Color(0xFFC8D4FF),
                          textColor: const Color(0xFF2E3AD6),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const JobPostingPage()));
                          },
                        ),
                      if (role == UserRole.student) ...[
                        const SizedBox(height: 20),
                        _buildRatingsOverview(),
                      ],
                      const SizedBox(height: 12),
                      if (kDebugMode)
                        _buildActionButton(
                          label: 'Seed Demo Data',
                          color: const Color(0xFFF2F4F7),
                          textColor: const Color(0xFF1F2A44),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SeedPage())),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
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

  Widget _buildRatingsOverview() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Ratings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          FutureBuilder<double>(
            future: _service.getEmployeeAverageRating(uid),
            builder: (context, snapshot) {
              final avg = snapshot.data ?? 0;
              return Row(
                children: [
                  Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  _buildStars(avg),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.streamEmployeeRatings(uid),
            builder: (context, snapshot) {
              final ratings = snapshot.data ?? [];
              final displayed = ratings.take(5).toList();
              if (displayed.isEmpty) {
                return const Text('No reviews yet', style: TextStyle(color: Colors.grey));
              }
              return Column(
                children: displayed.map((r) {
                  final avg = (r['average'] as num?)?.toDouble() ?? 0;
                  final comment = r['comment']?.toString() ?? '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        _buildStars(avg),
                        const SizedBox(width: 8),
                        Text(avg.toStringAsFixed(1)),
                      ],
                    ),
                    subtitle: Text(comment),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i + 1 <= rating.round();
        return Icon(filled ? Icons.star : Icons.star_border, color: Colors.amber, size: 20);
      }),
    );
  }

  Widget _buildProfileHeader(UserProfile? p) {
    final initials = (p?.displayName.isNotEmpty == true)
        ? p!.displayName.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : (p?.email.isNotEmpty == true ? p!.email[0].toUpperCase() : '?');
    final roleText = (p?.role == UserRole.employer) ? 'Employer' : 'Student';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF0F1E3C),
            child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p?.displayName ?? 'Your Name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F1E3C))),
                const SizedBox(height: 4),
                Text(p?.email ?? '', style: const TextStyle(color: Color(0xFF4B5563))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                      child: Text(roleText, style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    if ((p?.location ?? '').isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.place, size: 16, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text(p!.location, style: const TextStyle(color: Color(0xFF6B7280))),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () async {
                final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
                if (saved == true) _loadProfile();
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(UserProfile? p) {
    final skills = p?.skills ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone, size: 18, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(p?.phone.isNotEmpty == true ? p!.phone : 'Not set', style: const TextStyle(color: Color(0xFF374151))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place, size: 18, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(p?.location.isNotEmpty == true ? p!.location : 'Not set', style: const TextStyle(color: Color(0xFF374151))),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Skills', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (skills.isEmpty)
            const Text('No skills provided', style: TextStyle(color: Color(0xFF6B7280)))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
                  child: Text(s),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    double height = 72,
  }) {
    return SizedBox(
      height: height,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ).copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF1F2A44),
                  fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        // Earnings History
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EarningsHistoryPage(),
          ),
        );
        break;
      case 1:
        // Withdraw Earnings
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WithdrawEarningPage(),
          ),
        );
        break;
      case 2:
        // Transfer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmployerTransferPage(),
          ),
        );
        break;
      case 3:
        // Rating
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmployerReviewPage(),
          ),
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
