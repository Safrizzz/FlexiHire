import 'package:flutter/material.dart';
import '../components/bottom_nav_bar.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  int _selectedNavIndex = 0; // Discovery tab

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 251),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0,
        title: const Text(
          'Discovery',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Discover Job Opportunities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse and find jobs that match your skills',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
          _navigateToPage(index);
        },
      ),
    );
  }

  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        // Already on Discovery
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/my_jobs');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/message');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }
}
