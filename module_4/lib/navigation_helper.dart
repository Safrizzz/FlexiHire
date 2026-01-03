import 'package:flutter/material.dart';
import 'user_role.dart';

class NavigationHelper {
  static void navigateBottomTab(BuildContext context, int index, UserRole role) {
    if (role == UserRole.employee) {
      switch (index) {
        case 0: Navigator.pushReplacementNamed(context, '/discovery'); break;
        case 1: Navigator.pushReplacementNamed(context, '/my_jobs'); break;
        case 2: Navigator.pushReplacementNamed(context, '/messages'); break;
        case 3: Navigator.pushReplacementNamed(context, '/profile'); break;
      }
    } else {
      switch (index) {
        case 0: Navigator.pushReplacementNamed(context, '/jobs'); break;
        case 1: Navigator.pushReplacementNamed(context, '/company'); break;
        case 2: return; // FAB
        case 3: Navigator.pushReplacementNamed(context, '/messages'); break;
        case 4: Navigator.pushReplacementNamed(context, '/profile'); break;
      }
    }
  }

  static void onMiddlePressed(BuildContext context, UserRole role) {
    if (role == UserRole.recruiter) {
      Navigator.pushNamed(context, '/create_job');
    }
  }

  static void navigate(BuildContext context, int index, UserRole role) {
    navigateBottomTab(context, index, role);
  }

  static void handleFab(BuildContext context) {
    Navigator.pushNamed(context, '/create_job');
  }

  static int initialIndexForRole(UserRole role) {
    if (role == UserRole.employee) {
      return 0; // Discovery
    } else {
      return 0; // Jobs
    }
  }
}
