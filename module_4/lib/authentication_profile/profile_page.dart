import 'package:flutter/material.dart';
import '../components/bottom_nav_bar.dart';
import '../payment_rating/withdraw_earning_page.dart';
import '../payment_rating/employer_transfer_page.dart';
import '../payment_rating/earnings_history_page.dart';
import '../payment_rating/employer_review_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedNavIndex = 3; // Profile tab

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 251),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          child: _miniStat(
                            title: 'Total Earnings',
                            value: 'RM 0.00',
                            valueColor: const Color(0xFF0F1E3C),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _miniStat(
                            title: 'Available',
                            value: 'RM 0.00',
                            valueColor: const Color(0xFFE05A1C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons in a slim vertical stack
              Column(
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
                ],
              ),
            ],
          ),
        ),
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
