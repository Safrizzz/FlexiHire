import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/application.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../components/bottom_nav_bar.dart';
import '../models/job.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authentication_profile/auth_tabs_page.dart';
import '../matching_chatting/message_page.dart';
import '../payment_rating/student_review_page.dart';
import 'job_model.dart' as ui;
import 'create_job_page.dart';
import 'applicants_page.dart';
import 'hires_page.dart';
import 'completion_page.dart';
import 'job_details_page.dart';

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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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

    // Check user role to show appropriate view
    return StreamBuilder<UserProfile?>(
      stream: _service.streamUserProfile(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
            body: const Center(child: CircularProgressIndicator()),
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

        final role = snapshot.data?.role ?? UserRole.student;

        if (role == UserRole.employer) {
          return _buildEmployerView(user.uid);
        } else {
          return _buildStudentView();
        }
      },
    );
  }

  // ===============================
  // EMPLOYER VIEW - Job Postings
  // ===============================
  Widget _buildEmployerView(String uid) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 251),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0,
        title: const Text(
          'My Job Postings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F1E3C),
        onPressed: () async {
          final ui.Job? newJob = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateJobPage()),
          );

          if (newJob != null) {
            final beJob = _toBackendJob(newJob, uid);
            await _service.createJob(beJob);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Job>>(
        stream: _service.streamEmployerJobs(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final beJobs = snapshot.data ?? [];
          if (beJobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No job postings yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create a job',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }
          final uiJobs = beJobs.map(_toUiJob).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: uiJobs.length,
            itemBuilder: (context, index) {
              final job = uiJobs[index];
              final beJob = beJobs[index];
              return _buildJobCard(job: job, beJob: beJob, uid: uid);
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

  Widget _buildJobCard({
    required ui.Job job,
    required Job beJob,
    required String uid,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F1E3C),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(job.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    job.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusTextColor(job.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              job.description,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job.location,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'RM ${job.payRate}/hr',
                    style: const TextStyle(
                      color: Color(0xFF7B1FA2),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF0F1E3C),
                    onPressed: () async {
                      final result = await Navigator.push<JobDetailsResult>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailsPage(job: job),
                        ),
                      );
                      if (result == null) return;
                      if (result.action == JobDetailsAction.updated &&
                          result.updatedJob != null) {
                        final updatedBe = _toBackendJob(
                          result.updatedJob!,
                          uid,
                          beId: beJob.id,
                        );
                        await _service.updateJob(updatedBe);
                      } else if (result.action == JobDetailsAction.deleted) {
                        await _service.deleteJob(beJob.id);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    label: 'Applicants',
                    icon: Icons.people_outline,
                    color: const Color(0xFF1565C0),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ApplicantsPage(job: job),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Hires',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF2E7D32),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HiresPage(job: job),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    label: 'Complete',
                    icon: Icons.done_all,
                    color: const Color(0xFF00695C),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CompletionPage(jobId: beJob.id, pay: beJob.pay),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Job'),
                        content: const Text(
                          'Are you sure you want to delete this job posting?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _service.deleteJob(beJob.id);
                    }
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFFE8F5E9);
      case 'closed':
        return const Color(0xFFFFEBEE);
      case 'completed':
        return const Color(0xFFE3F2FD);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFF2E7D32);
      case 'closed':
        return const Color(0xFFC62828);
      case 'completed':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF616161);
    }
  }

  Job _toBackendJob(ui.Job job, String employerId, {String? beId}) {
    DateTime? earliest;
    DateTime? latest;
    String? startTimeStr;
    String? endTimeStr;
    for (final s in job.microShifts) {
      if (earliest == null || s.start.isBefore(earliest)) {
        earliest = s.start;
        startTimeStr =
            '${s.start.hour.toString().padLeft(2, '0')}:${s.start.minute.toString().padLeft(2, '0')}';
      }
      if (latest == null || s.end.isAfter(latest)) {
        latest = s.end;
        endTimeStr =
            '${s.end.hour.toString().padLeft(2, '0')}:${s.end.minute.toString().padLeft(2, '0')}';
      }
    }
    return Job(
      id: beId ?? '',
      title: job.title,
      description: job.description,
      location: job.location,
      geoLocation: job.geoLocation,
      pay: job.payRate,
      startDate: earliest ?? DateTime.now(),
      endDate: latest ?? DateTime.now(),
      startTime: startTimeStr,
      endTime: endTimeStr,
      skillsRequired: const [],
      employerId: employerId,
      createdAt: DateTime.now(),
      status: job.status,
    );
  }

  ui.Job _toUiJob(Job beJob) {
    return ui.Job(
      id: beJob.id,
      title: beJob.title,
      company: '',
      location: beJob.location,
      geoLocation: beJob.geoLocation,
      payRate: beJob.pay.toDouble(),
      description: beJob.description,
      microShifts: const [],
      status: beJob.status,
      applicants: const [],
      hires: const [],
    );
  }

  // ===============================
  // STUDENT VIEW - Applications
  // ===============================
  Widget _buildStudentView() {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 251),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0,
        title: const Text(
          'My Applications',
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
                  Text(
                    'No applications yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore jobs in Discovery',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return FutureBuilder<Job?>(
                future: _fetchJob(app.jobId),
                builder: (context, jobSnap) {
                  final job = jobSnap.data;
                  return _buildApplicationCard(app, job);
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

  Widget _buildApplicationCard(Application app, Job? job) {
    final title = job?.title ?? 'Job';
    final location = job?.location ?? '';

    String formatDate(DateTime d) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    }

    String formatTime(String? time) {
      if (time == null) return '';
      // Convert 24h to 12h format
      final parts = time.split(':');
      if (parts.length != 2) return time;
      int hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:$minute $period';
    }

    final dateText = job == null
        ? ''
        : '${formatDate(job.startDate)} - ${formatDate(job.endDate)}';

    final timeText = (job?.startTime != null && job?.endTime != null)
        ? '(${formatTime(job!.startTime)} To ${formatTime(job.endTime)})'
        : '';

    // Determine display status
    String displayStatus;
    Color statusBgColor;
    Color statusTextColor;

    if (job?.status == 'completed') {
      displayStatus = 'JOB COMPLETED';
      statusBgColor = const Color(0xFF9E9E9E);
      statusTextColor = Colors.white;
    } else if (app.status == 'accepted') {
      displayStatus = 'HIRED';
      statusBgColor = const Color(0xFF2E7D32);
      statusTextColor = Colors.white;
    } else if (app.status == 'rejected') {
      displayStatus = 'REJECTED';
      statusBgColor = const Color(0xFFE53935);
      statusTextColor = Colors.white;
    } else if (app.status == 'withdrawn') {
      displayStatus = 'WITHDRAWN';
      statusBgColor = const Color(0xFF757575);
      statusTextColor = Colors.white;
    } else {
      displayStatus = 'APPLIED';
      statusBgColor = const Color(0xFF1976D2);
      statusTextColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F1E3C),
                  ),
                ),
                const SizedBox(height: 16),

                // Location Row
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        location.isNotEmpty ? location : 'Not specified',
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Date Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateText,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                          ),
                          if (timeText.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              timeText,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Button (Full Width)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Center(
              child: Text(
                displayStatus,
                style: TextStyle(
                  color: statusTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
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
}
