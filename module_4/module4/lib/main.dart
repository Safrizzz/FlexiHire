import 'package:flutter/material.dart';
import 'pages/withdraw_earning_page.dart';
import 'pages/employer_transfer_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // Changed home from withdraw_earning_page to HomePage
      // HomePage is a new page with two buttons to navigate to both pages
      home: HomePage()
    );
  }
}

// ============================================================================
// HOME PAGE - This is the first page that shows when app launches
// It has two buttons to navigate to Employee Withdrawal or Employer Transfer
// ============================================================================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background color to light gray/white
      backgroundColor: const Color.fromARGB(255, 250, 250, 251),
      
      // ===================================================================
      // APP BAR - The top header of the page
      // ===================================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0,
        title: const Text(
          'Job Seeking App',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true, // Center the title
      ),
      
      // ===================================================================
      // BODY - Main content area
      // ===================================================================
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ============================================================
              // WELCOME TEXT
              // ============================================================
              const Text(
                'Welcome!',
                style: TextStyle(
                  color: Color.fromARGB(255, 21, 36, 69),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Select an option below',
                style: TextStyle(
                  color: Color.fromARGB(255, 53, 53, 53),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 50),
              
              // ============================================================
              // BUTTON 1 - Employee Withdrawal Button
              // ============================================================
              SizedBox(
                // Make the button full width with some padding
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  // onPressed = What happens when you tap this button
                  onPressed: () {
                    // Navigator.push = Go to a new page
                    // MaterialPageRoute = How to navigate (slide animation)
                    // builder = Create the new page (withdraw_earning_page)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const withdraw_earning_page(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 39, 39, 215), // Purple
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4, // Shadow effect
                  ),
                  child: const Text(
                    'Employee - Withdraw Earnings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Space between buttons
              
              // ============================================================
              // BUTTON 2 - Employer Transfer Button
              // ============================================================
              SizedBox(
                // Make the button full width with some padding
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  // onPressed = What happens when you tap this button
                  onPressed: () {
                    // Navigator.push = Go to a new page
                    // MaterialPageRoute = How to navigate (slide animation)
                    // builder = Create the new page (employer_transfer_page)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const employer_transfer_page(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 138, 80), // Orange
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4, // Shadow effect
                  ),
                  child: const Text(
                    'Employer - Transfer to Employee',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}