import 'package:flutter/material.dart';
import 'models/user_role.dart';
import 'job_posting_management/discovery_page.dart';
import 'job_posting_management/my_jobs_page.dart';
import 'matching_chatting/message_page.dart';
import 'authentication_profile/profile_page.dart';

class NavigationHelper {
  static void navigate(BuildContext context, int index, UserRole role) {
    Widget destination;
    switch (index) {
      case 0:
        destination = const DiscoveryPage();
        break;
      case 1:
        destination = const MyJobsPage();
        break;
      case 2:
        destination = const MessagePage();
        break;
      case 3:
      default:
        destination = const ProfilePage();
        break;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  static void handleFab(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Action unavailable')),
    );
  }
}
