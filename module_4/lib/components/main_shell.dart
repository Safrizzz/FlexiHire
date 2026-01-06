import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

/// A main shell that provides persistent bottom navigation with smooth page transitions.
/// Uses PageView so all pages are side-by-side and slide smoothly like a carousel.
class MainShell extends StatefulWidget {
  final int initialIndex;
  final Widget discoveryPage;
  final Widget myJobsPage;
  final Widget messagePage;
  final Widget profilePage;

  const MainShell({
    super.key,
    this.initialIndex = 0,
    required this.discoveryPage,
    required this.myJobsPage,
    required this.messagePage,
    required this.profilePage,
  });

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  PageController? _pageController;

  // Global key to access MainShellState from anywhere
  static final GlobalKey<MainShellState> shellKey = GlobalKey<MainShellState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void navigateToTab(int index) {
    if (_currentIndex == index) return;
    if (_pageController == null) return;

    HapticFeedback.selectionClick();

    setState(() {
      _currentIndex = index;
    });

    // Smooth animated scroll to the page
    _pageController!.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pageController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      body: PageView(
        controller: _pageController!,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe, only nav bar controls
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          // Wrap each page in a KeepAlive widget to preserve state
          _KeepAlivePage(child: widget.discoveryPage),
          _KeepAlivePage(child: widget.myJobsPage),
          _KeepAlivePage(child: widget.messagePage),
          _KeepAlivePage(child: widget.profilePage),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    const double radius = 24;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0F1E3C).withValues(alpha: 0.95),
                const Color(0xFF1A2D5A).withValues(alpha: 0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F1E3C).withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, CupertinoIcons.search, 'Discover'),
                  _buildNavItem(1, CupertinoIcons.briefcase_fill, 'My Jobs'),
                  _buildNavItem(2, CupertinoIcons.chat_bubble_text_fill, 'Messages'),
                  _buildNavItem(3, CupertinoIcons.person_fill, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => navigateToTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: isSelected 
            ? Border.all(color: Colors.white.withValues(alpha: 0.2))
            : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 22 : 20,
              color: isSelected 
                ? Colors.white 
                : Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected 
                  ? Colors.white 
                  : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget that keeps its child alive when scrolling in PageView
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
