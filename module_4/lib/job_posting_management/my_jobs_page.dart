import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/application.dart';
import '../components/bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authentication_profile/auth_tabs_page.dart';
import '../matching_chatting/message_page.dart';
import '../payment_rating/student_review_page.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  int _selectedNavIndex = 1; // My Jobs tab
  final FirestoreService _service = FirestoreService();
  final Map<String, Job> _jobCache = {};

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 250, 250, 251),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1E3C),
          elevation: 0,
          title: const Text(
            'Login',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const AuthTabsPage(),
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 251),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0,
        title: const Text(
          'My Jobs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<List<Application>>(
        stream: _service.streamMyApplications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final apps = snapshot.data ?? [];
          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('No applications yet', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return FutureBuilder<Job?>(
                future: _service.getJob(app.jobId),
                builder: (context, jobSnap) {
                  final job = jobSnap.data;
                  final title = job?.title ?? 'Job';
                  final location = job?.location ?? '';
                  final payText = job?.pay != null ? 'RM ${job!.pay}' : '';
                  final dateText = job == null
                      ? ''
                      : '${job.startDate.toLocal().toIso8601String().split('T').first} - ${job.endDate.toLocal().toIso8601String().split('T').first}';
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF0F1E3C),
                            child: Text(title.isNotEmpty ? title[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Row(
                            children: [
                              Icon(Icons.place, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(payText),
                            ],
                          ),
                          trailing: _statusChip(app.status),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  dateText,
                                  style: TextStyle(color: Colors.grey[700]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: (job?.status == 'open')
                                      ? () async {
                                          final chatId = await _service.createOrOpenChat(
                                            employerId: job?.employerId ?? '',
                                            jobId: app.jobId,
                                          );
                                          if (!mounted) return;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => MessagePage(chatId: chatId)),
                                          );
                                        }
                                      : null,
                                  child: Text(job?.status == 'open' ? 'Chat' : 'Chat Disabled'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: app.status == 'applied'
                                      ? () async {
                                          await _service.withdrawApplication(app.id);
                                        }
                                      : null,
                                  child: const Text('Withdraw'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (job?.status == 'completed')
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StudentReviewPage(
                                            employerId: job!.employerId,
                                            jobId: app.jobId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Rate Employer'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
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
        Navigator.of(context).pushReplacementNamed('/discovery');
        break;
      case 1:
        // Already on My Jobs
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/message');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

  Future<Job?> _fetchJob(String jobId) async {
    if (_jobCache.containsKey(jobId)) return _jobCache[jobId];
    final job = await _service.getJob(jobId);
    if (job != null) _jobCache[jobId] = job;
    return job;
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'applied':
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1976D2);
        break;
      case 'withdrawn':
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF616161);
        break;
      case 'accepted':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        break;
      default:
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF616161);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
