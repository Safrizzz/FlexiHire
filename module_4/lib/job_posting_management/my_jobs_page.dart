import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import '../models/application.dart';
import '../components/bottom_nav_bar.dart';
import '../components/main_shell.dart';
import '../models/job.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authentication_profile/auth_tabs_page.dart';
import '../matching_chatting/message_page.dart';
import '../payment_rating/student_review_page.dart';
import 'student_job_details_page.dart';
import '../models/user_role.dart';
import 'job_model.dart' as ui;
import 'create_job_page.dart';
import 'applicants_page.dart';
import 'hires_page.dart';
import 'completion_page.dart';
import 'job_details_page.dart';

class MyJobsPage extends StatefulWidget {
  final bool showBottomNav;

  const MyJobsPage({super.key, this.showBottomNav = true});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> with TickerProviderStateMixin {
  int _selectedNavIndex = 1;
  final FirestoreService _service = FirestoreService();
  final Map<String, Job> _jobCache = {};
  String _selectedFilter = 'all';
  UserRole? _userRole;
  bool _loadingRole = true;

  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerController.forward();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingRole = false);
      return;
    }
    final profile = await _service.getUserProfile(uid);
    if (profile != null && mounted) {
      setState(() {
        _userRole = profile.role;
        _loadingRole = false;
      });
    } else {
      setState(() => _loadingRole = false);
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A1628),
          elevation: 0,
          title: const Text('Login', style: TextStyle(color: Colors.white)),
        ),
        body: const AuthTabsPage(),
        bottomNavigationBar: widget.showBottomNav
            ? CustomBottomNavBar(
                selectedIndex: _selectedNavIndex,
                onTap: (index) {
                  setState(() => _selectedNavIndex = index);
                  _navigateToPage(index);
                },
              )
            : null,
      );
    }

    // Show loading while fetching user role
    if (_loadingRole) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
        bottomNavigationBar: widget.showBottomNav
            ? CustomBottomNavBar(
                selectedIndex: _selectedNavIndex,
                onTap: (index) {
                  setState(() => _selectedNavIndex = index);
                  _navigateToPage(index);
                },
              )
            : null,
      );
    }

    // Show employer view if user is an employer
    if (_userRole == UserRole.employer) {
      return _buildEmployerView();
    }

    // Student view (default)
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildFilterChips()),
          _buildApplicationsList(),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav
          ? CustomBottomNavBar(
              selectedIndex: _selectedNavIndex,
              onTap: (index) {
                setState(() => _selectedNavIndex = index);
                _navigateToPage(index);
              },
            )
          : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A1628),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1628), Color(0xFF1A3A5C), Color(0xFF0F2847)],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _headerAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.work_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Applications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Track your job applications',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All', Icons.apps_rounded),
            const SizedBox(width: 8),
            _buildFilterChip('applied', 'Applied', Icons.send_rounded),
            const SizedBox(width: 8),
            _buildFilterChip(
              'accepted',
              'Accepted',
              Icons.check_circle_outline,
            ),
            const SizedBox(width: 8),
            _buildFilterChip('completed', 'Completed', Icons.task_alt_rounded),
            const SizedBox(width: 8),
            _buildFilterChip('rejected', 'Rejected', Icons.cancel_outlined),
            const SizedBox(width: 8),
            _buildFilterChip('withdrawn', 'Cancelled', Icons.close_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsList() {
    return StreamBuilder<List<Application>>(
      stream: _service.streamMyApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            ),
          );
        }

        var apps = snapshot.data ?? [];

        // Filter applications
        if (_selectedFilter != 'all') {
          if (_selectedFilter == 'completed') {
            // Show both completed and paid when filtering for completed
            apps = apps
                .where((a) => a.status == 'completed' || a.status == 'paid')
                .toList();
          } else {
            apps = apps.where((a) => a.status == _selectedFilter).toList();
          }
        }

        if (apps.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final app = apps[index];
              return FutureBuilder<Job?>(
                future: _fetchJob(app.jobId),
                builder: (context, jobSnap) {
                  // Show loading shimmer while job is being fetched
                  if (jobSnap.connectionState == ConnectionState.waiting) {
                    return _buildLoadingCard(index);
                  }
                  
                  final job = jobSnap.data;
                  // If job is null after loading, skip this card
                  if (job == null) {
                    return const SizedBox.shrink();
                  }
                  
                  return _ApplicationCard(
                    application: app,
                    job: job,
                    animationDelay: index * 80,
                    onChat: () => _openChat(job, app.jobId),
                    onWithdraw: app.status == 'applied'
                        ? () => _withdrawApplication(app.id)
                        : null,
                    onRate: (app.status == 'completed' || app.status == 'paid')
                        ? () => _rateEmployer(job, app.jobId)
                        : null,
                    onTap: () => _viewJobDetails(job),
                  );
                },
              );
            }, childCount: apps.length),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.work_off_rounded,
              size: 40,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'No applications yet'
                : 'No $_selectedFilter applications',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start exploring jobs to apply!',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/discovery'),
            icon: const Icon(Icons.explore_rounded, size: 18),
            label: const Text('Discover Jobs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(Job job, String jobId) async {
    final chatId = await _service.createOrOpenChat(
      employerId: job.employerId,
      jobId: jobId,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MessagePage(chatId: chatId)),
    );
  }

  Future<void> _withdrawApplication(String appId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Cancel Application?',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this application? You can re-apply later.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.withdrawApplication(appId);
    }
  }

  void _rateEmployer(Job job, String jobId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StudentReviewPage(employerId: job.employerId, jobId: jobId),
      ),
    );
  }

  void _viewJobDetails(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StudentJobDetailsPage(job: job)),
    );
  }

  void _navigateToPage(int index) {
    // If we're inside MainShell, use smooth navigation
    final shellState = MainShellState.shellKey.currentState;
    if (shellState != null && !widget.showBottomNav) {
      shellState.navigateToTab(index);
      return;
    }

    // Fallback to traditional navigation
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/discovery');
        break;
      case 1:
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/message');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

  Widget _buildLoadingCard(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 12,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Job?> _fetchJob(String jobId) async {
    if (_jobCache.containsKey(jobId)) return _jobCache[jobId];
    final job = await _service.getJob(jobId);
    if (job != null) _jobCache[jobId] = job;
    return job;
  }

  // ============================================================================
  // ============================================================================
  // EMPLOYER VIEW
  // ============================================================================

  Widget _buildEmployerView() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [_buildEmployerAppBar(), _buildEmployerJobsList(uid)],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0A1628),
        onPressed: () async {
          final ui.Job? newJob = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateJobPage()),
          );

          if (newJob != null) {
            if (uid.isEmpty) return;
            final beJob = _toBackendJob(newJob, uid);
            await _service.createJob(beJob);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? CustomBottomNavBar(
              selectedIndex: _selectedNavIndex,
              onTap: (index) {
                setState(() => _selectedNavIndex = index);
                _navigateToPage(index);
              },
            )
          : null,
    );
  }

  Widget _buildEmployerAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A1628),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1628), Color(0xFF1A3A5C), Color(0xFF0F2847)],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _headerAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.business_center_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Job Postings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage your job listings',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployerJobsList(String uid) {
    if (uid.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('Please login to manage job postings.')),
      );
    }

    return StreamBuilder<List<Job>>(
      stream: _service.streamEmployerJobs(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            ),
          );
        }

        final beJobs = snapshot.data ?? [];
        if (beJobs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.work_off_rounded,
                      size: 40,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No job postings yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap + to create a new job',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final beJob = beJobs[index];
              final uiJob = _toUiJob(beJob);
              return _EmployerJobCard(
                job: uiJob,
                animationDelay: index * 80,
                onOpenDetails: () async {
                  final result = await Navigator.push<JobDetailsResult>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobDetailsPage(job: uiJob),
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
                onApplicants: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApplicantsPage(job: uiJob),
                    ),
                  );
                },
                onHires: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HiresPage(job: uiJob),
                    ),
                  );
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Delete Job?'),
                      content: const Text(
                        'Are you sure you want to delete this job posting?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _service.deleteJob(beJob.id);
                  }
                },
                onSetStatus: (status) async {
                  await _service.updateJobStatus(beJob.id, status);
                },
                onComplete: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CompletionPage(jobId: beJob.id, pay: beJob.pay),
                    ),
                  );
                },
              );
            }, childCount: beJobs.length),
          ),
        );
      },
    );
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
      skillsRequired: job.skillsRequired,
      employerId: employerId,
      createdAt: DateTime.now(),
      status: job.status,
      microShifts: job.microShifts,
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
      microShifts: beJob.microShifts,
      status: beJob.status,
      skillsRequired: beJob.skillsRequired,
      applicants: const [],
      hires: const [],
    );
  }
}

// ============================================================================
// APPLICATION CARD WIDGET
// ============================================================================

class _ApplicationCard extends StatefulWidget {
  final Application application;
  final Job? job;
  final int animationDelay;
  final VoidCallback? onChat;
  final VoidCallback? onWithdraw;
  final VoidCallback? onRate;
  final VoidCallback? onTap;

  const _ApplicationCard({
    required this.application,
    required this.job,
    required this.animationDelay,
    this.onChat,
    this.onWithdraw,
    this.onRate,
    this.onTap,
  });

  @override
  State<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<_ApplicationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final job = widget.job;
    final title = job?.title ?? 'Loading...';
    final location = job?.location ?? '';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _getStatusColor(app.status).withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Status bar at top
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _getStatusColor(app.status),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF0A1628),
                                const Color(0xFF1A3A5C),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              title.isNotEmpty ? title[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title and location
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      location.isNotEmpty
                                          ? location
                                          : 'Unknown location',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Status chip
                        _buildStatusChip(app.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Info row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          // Date range
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 12,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    job != null ? _formatDateRange(job) : '--',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (job?.startTime != null) ...[
                            Container(
                              width: 1,
                              height: 20,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(width: 10),
                            // Time
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF7043,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: Color(0xFFFF7043),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${job!.startTime}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Action buttons
                    Row(
                      children: [
                        // Chat button
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Chat',
                            color: const Color(0xFF3B82F6),
                            onTap: widget.onChat,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Cancel button
                        if (widget.onWithdraw != null)
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.close_rounded,
                              label: 'Cancel',
                              color: Colors.red.shade500,
                              onTap: widget.onWithdraw,
                            ),
                          ),
                        // Rate button
                        if (widget.onRate != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.star_outline_rounded,
                              label: 'Rate',
                              color: const Color(0xFFD97706),
                              onTap: widget.onRate,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade100 : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDisabled ? Colors.grey.shade200 : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isDisabled ? Colors.grey.shade400 : color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDisabled ? Colors.grey.shade400 : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    // For paid status, show both COMPLETED and PAID badges
    if (status == 'paid') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSingleStatusChip('completed'),
          const SizedBox(height: 4),
          _buildSingleStatusChip('paid'),
        ],
      );
    }
    return _buildSingleStatusChip(status);
  }

  Widget _buildSingleStatusChip(String status) {
    final color = _getStatusColor(status);
    final bgColor = _getStatusBgColor(status);
    final icon = _getStatusIcon(status);
    final displayText = status == 'withdrawn'
        ? 'CANCELLED'
        : status.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(Job job) {
    final months = [
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
    final start = job.startDate;
    final end = job.endDate;
    return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]} ${end.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'applied':
        return const Color(0xFF3B82F6);
      case 'accepted':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF8B5CF6);
      case 'paid':
        return const Color(0xFF059669);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'withdrawn':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'applied':
        return const Color(0xFFEFF6FF);
      case 'accepted':
        return const Color(0xFFECFDF5);
      case 'completed':
        return const Color(0xFFF5F3FF);
      case 'paid':
        return const Color(0xFFD1FAE5);
      case 'rejected':
        return const Color(0xFFFEF2F2);
      case 'withdrawn':
        return const Color(0xFFF3F4F6);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'applied':
        return Icons.send_rounded;
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'paid':
        return Icons.payments_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'withdrawn':
        return Icons.undo_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

// ============================================================================
// EMPLOYER JOB CARD WIDGET
// ============================================================================

class _EmployerJobCard extends StatefulWidget {
  final ui.Job job;
  final int animationDelay;
  final VoidCallback onOpenDetails;
  final VoidCallback onApplicants;
  final VoidCallback onHires;
  final VoidCallback onDelete;
  final Future<void> Function(String status)? onSetStatus;
  final VoidCallback? onComplete;

  const _EmployerJobCard({
    required this.job,
    required this.animationDelay,
    required this.onOpenDetails,
    required this.onApplicants,
    required this.onHires,
    required this.onDelete,
    this.onSetStatus,
    this.onComplete,
  });

  @override
  State<_EmployerJobCard> createState() => _EmployerJobCardState();
}

class _EmployerJobCardState extends State<_EmployerJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A1628).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onOpenDetails,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            widget.job.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildJobStatusChip(widget.job.status),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Location and Pay
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.job.location,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'RM${widget.job.payRate.toStringAsFixed(0)}/hr',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Action Buttons - 2 rows for cleaner look
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Edit',
                            Icons.edit_outlined,
                            const Color(0xFF3B82F6),
                            widget.onOpenDetails,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionButton(
                            'Applicants',
                            Icons.people_outline,
                            const Color(0xFF8B5CF6),
                            widget.onApplicants,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Hires',
                            Icons.how_to_reg_outlined,
                            const Color(0xFF10B981),
                            widget.onHires,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionButton(
                            'Complete',
                            Icons.check_circle_outline,
                            const Color(0xFF059669),
                            widget.onComplete ?? () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobStatusChip(String status) {
    Color color;
    Color bgColor;
    IconData icon;

    switch (status) {
      case 'open':
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        icon = Icons.check_circle_outline;
        break;
      case 'closed':
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEF2F2);
        icon = Icons.cancel_outlined;
        break;
      case 'completed':
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFEFF6FF);
        icon = Icons.verified_outlined;
        break;
      default:
        color = const Color(0xFF6B7280);
        bgColor = const Color(0xFFF3F4F6);
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
