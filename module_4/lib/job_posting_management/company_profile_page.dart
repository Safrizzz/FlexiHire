import 'package:flutter/material.dart';
import '../components/bottom_nav_bar.dart';
import '../user_role.dart';
import '../navigation_helper.dart';
import 'company_model.dart';

class CompanyProfilePage extends StatefulWidget {
  final Company company;

  const CompanyProfilePage({super.key, required this.company});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  int _selectedNavIndex = 2; // Profile tab

  @override
  Widget build(BuildContext context) {
    final company = widget.company;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 251),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0,
        title: Text(
          company.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero summary card with logo & description
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(company.logoUrl),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    company.name,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    company.description,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mini stats (example)
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    title: 'Jobs Posted',
                    value: '12',
                    valueColor: const Color(0xFF0F1E3C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _miniStat(
                    title: 'Active Hiring',
                    value: '3',
                    valueColor: const Color(0xFFE05A1C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action buttons
            Column(
              children: [
                _buildActionButton(
                  label: 'View Jobs',
                  color: const Color(0xFFC8D4FF),
                  textColor: const Color(0xFF2E3AD6),
                  onTap: () {
                    // Navigate to jobs page
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  label: 'Contact Company',
                  color: const Color(0xFFF6D2B4),
                  textColor: const Color(0xFFCC4A0F),
                  onTap: () {
                    // Navigate to contact page or email
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  label: 'Company Reviews',
                  color: const Color(0xFFC8D4FF),
                  textColor: const Color(0xFF2E3AD6),
                  onTap: () {
                    // Navigate to reviews page
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedNavIndex,
        role: currentUserRole,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
          NavigationHelper.navigate(context, index, currentUserRole);
        },
        onMiddleButtonPressed: () {
          NavigationHelper.handleFab(context);
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
                color: Colors.black.withAlpha((0.14 * 255).round()),
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
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF1F2A44), fontWeight: FontWeight.w700),
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
}
