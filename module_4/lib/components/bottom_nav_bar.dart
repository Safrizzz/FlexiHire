import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/user_role.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onTap;
  final UserRole? role;
  final VoidCallback? onMiddleButtonPressed;
  
  const CustomBottomNavBar({
    super.key,
    this.selectedIndex = 0,
    this.onTap,
    this.role,
    this.onMiddleButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    const double radius = 18;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000), // stronger shadow
            blurRadius: 16,
            spreadRadius: 0,
            offset: Offset(0, -4),
          ),
          BoxShadow(
            color: Color(0x0D000000), // additional soft shadow
            blurRadius: 32,
            spreadRadius: 2,
            offset: Offset(0, -8),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF000000).withValues(alpha: 0.06),
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
              final bool selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.black : Colors.black45,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
              final bool selected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: selected ? 22 : 20,
                color: selected ? Colors.black : Colors.black45,
              );
            }),
          ),
          child: NavigationBar(
            height: 58,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: selectedIndex,
            onDestinationSelected: onTap,
            destinations: const [
              NavigationDestination(
                icon: Icon(CupertinoIcons.search),
                selectedIcon: Icon(CupertinoIcons.search),
                label: 'Discovery',
              ),
              NavigationDestination(
                icon: Icon(CupertinoIcons.briefcase),
                selectedIcon: Icon(CupertinoIcons.briefcase_fill),
                label: 'My Jobs',
              ),
              NavigationDestination(
                icon: Icon(CupertinoIcons.chat_bubble_text),
                selectedIcon: Icon(CupertinoIcons.chat_bubble_text_fill),
                label: 'Message',
              ),
              NavigationDestination(
                icon: Icon(CupertinoIcons.person),
                selectedIcon: Icon(CupertinoIcons.person_fill),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
