import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class AuthTabsPage extends StatelessWidget {
  const AuthTabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1E3C),
          elevation: 0,
          title: const Text('Account', style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xCCFFFFFF),
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Login'),
              Tab(text: 'Register'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ColoredBox(color: Colors.white, child: SingleChildScrollView(child: LoginPage())),
            ColoredBox(color: Colors.white, child: SingleChildScrollView(child: RegisterPage())),
          ],
        ),
      ),
    );
  }
}
