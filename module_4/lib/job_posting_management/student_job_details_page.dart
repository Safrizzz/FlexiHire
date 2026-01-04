import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../authentication_profile/auth_account_page.dart';
import '../components/student_micro_shift_selector.dart';

class StudentJobDetailsPage extends StatefulWidget {
  final Job job;
  final double? distance;

  const StudentJobDetailsPage({super.key, required this.job, this.distance});

  @override
  State<StudentJobDetailsPage> createState() => _StudentJobDetailsPageState();
}

class _StudentJobDetailsPageState extends State<StudentJobDetailsPage> {
  final FirestoreService _service = FirestoreService();
  UserProfile? _employerProfile;
  double? _employerRating;
  bool _isLoading = true;
  bool _isApplying = false;
  UserRole _userRole = UserRole.student;

  @override
  void initState() {
    super.initState();
    _loadEmployerDetails();
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final data = doc.data() ?? {};
        if (mounted) {
          setState(() {
            _userRole = parseUserRole(data['role']?.toString());
          });
        }
      }
    } catch (_) {
      // Default to student
    }
  }

  Future<void> _loadEmployerDetails() async {
    try {
      final profile = await _service.getUserProfile(widget.job.employerId);
      final rating = await _service.getEmployerAverageRating(
        widget.job.employerId,
      );
      if (mounted) {
        setState(() {
          _employerProfile = profile;
          _employerRating = rating;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleApply() async {
    // Check if user is logged in
    if (FirebaseAuth.instance.currentUser == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AuthAccountPage(selectedIndex: 0),
        ),
      );
      if (FirebaseAuth.instance.currentUser == null) {
        return;
      }
    }

    // Show micro-shift selector if the job has micro-shifts
    List<DateTime>? selectedDates;
    if (widget.job.microShifts.isNotEmpty) {
      selectedDates = await StudentMicroShiftSelector.show(context, widget.job);
      if (selectedDates == null || selectedDates.isEmpty) {
        // User cancelled or didn't select any dates
        return;
      }
    }

    setState(() {
      _isApplying = true;
    });

    try {
      final result = await _service.applyToJob(
        widget.job,
        selectedDates: selectedDates,
      );
      if (!mounted) return;

      setState(() {
        _isApplying = false;
      });

      if (result == 'applied') {
        _showSuccessDialog(
          'Application Submitted!',
          selectedDates != null && selectedDates.isNotEmpty
              ? 'Your application for ${selectedDates.length} ${selectedDates.length == 1 ? 'date' : 'dates'} has been sent to the employer. Track your status in "My Jobs".'
              : 'Your application has been sent to the employer. You can track your application status in "My Jobs".',
        );
      } else if (result == 'reapplied') {
        _showSuccessDialog(
          'Re-applied Successfully!',
          'Your application has been re-submitted. Check "My Jobs" for updates.',
        );
      } else {
        _showInfoDialog(
          'Already Applied',
          'You have already applied to this job. Check "My Jobs" for your application status.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Colors.green.shade600,
          ),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F1E3C),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.blue.shade600,
          ),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F1E3C),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF0F1E3C),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F1E3C), Color(0xFF1A3A6E)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Job Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.job.status == 'open'
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.job.status == 'open'
                                ? 'Open for Applications'
                                : widget.job.status.toUpperCase(),
                            style: TextStyle(
                              color: widget.job.status == 'open'
                                  ? Colors.greenAccent
                                  : Colors.grey.shade300,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Job Title
                        Text(
                          widget.job.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Key Info Cards
                      _buildKeyInfoSection(),

                      // Employer Info
                      _buildEmployerSection(),

                      // Job Description
                      _buildDescriptionSection(),

                      // Skills Required
                      _buildSkillsSection(),

                      // Bottom padding for the apply button (only for students)
                      SizedBox(
                        height: _userRole == UserRole.student ? 100 : 20,
                      ),
                    ],
                  ),
          ),
        ],
      ),
      // Fixed Apply Button at Bottom (only for students)
      bottomNavigationBar: _userRole == UserRole.student
          ? _buildApplyButton()
          : null,
    );
  }

  Widget _buildKeyInfoSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            children: [
              // Pay Rate
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFF7B1FA2),
                  bgColor: const Color(0xFFF3E5F5),
                  title: 'Pay Rate',
                  value: 'RM ${widget.job.pay}/hr',
                ),
              ),
              const SizedBox(width: 12),
              // Distance
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.near_me_outlined,
                  iconColor: widget.distance != null
                      ? _getDistanceColor(widget.distance!)
                      : Colors.grey,
                  bgColor: widget.distance != null
                      ? _getDistanceBgColor(widget.distance!)
                      : Colors.grey.shade100,
                  title: 'Distance',
                  value: widget.distance != null
                      ? LocationService.formatDistance(widget.distance!)
                      : 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Location
          _buildDetailRow(
            Icons.location_on_outlined,
            const Color(0xFF5C6BC0),
            'Location',
            widget.job.location,
          ),
          const Divider(height: 24),
          // Date Range
          _buildDetailRow(
            Icons.calendar_today_outlined,
            const Color(0xFF26A69A),
            'Work Period',
            '${_formatShortDate(widget.job.startDate)} - ${_formatShortDate(widget.job.endDate)}',
          ),
          if (widget.job.startTime != null && widget.job.endTime != null) ...[
            const Divider(height: 24),
            _buildDetailRow(
              Icons.access_time_outlined,
              const Color(0xFFFF7043),
              'Working Hours',
              '${widget.job.startTime} - ${widget.job.endTime}',
            ),
          ],
          // Micro-Shifts Available
          if (widget.job.microShifts.isNotEmpty) ...[
            const Divider(height: 24),
            _buildMicroShiftsPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildMicroShiftsPreview() {
    final shifts = widget.job.microShifts;
    final sortedDates = shifts.map((s) => s.date).toSet().toList()..sort();
    final workingHours = shifts.isNotEmpty ? shifts.first.toShortDisplay() : '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Micro-Shifts',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${sortedDates.length} ${sortedDates.length == 1 ? 'date' : 'dates'} • $workingHours',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: const Color(0xFF6366F1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tap "Apply Now" to select specific dates you want to work',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF4338CA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: iconColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployerSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Posted by',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F1E3C),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Employer Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E3C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _employerProfile?.photoUrl.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _employerProfile!.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.business,
                            color: Color(0xFF0F1E3C),
                            size: 28,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.business,
                        color: Color(0xFF0F1E3C),
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _employerProfile?.displayName ?? 'Employer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_employerProfile?.location.isNotEmpty == true)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _employerProfile!.location,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Rating Badge
              if (_employerRating != null && _employerRating! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 18, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        _employerRating!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E3C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF0F1E3C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Job Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F1E3C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.job.description.isNotEmpty
                ? widget.job.description
                : 'No description provided.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    if (widget.job.skillsRequired.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Skills Required',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F1E3C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.job.skillsRequired.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Text(
                  skill,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    final isDisabled = widget.job.status != 'open';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick summary row
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay Rate',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        'RM ${widget.job.pay}/hr',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B1FA2),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        '${widget.job.endDate.difference(widget.job.startDate).inDays + 1} days',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF26A69A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isDisabled || _isApplying ? null : _handleApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F1E3C),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isApplying
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isDisabled ? Icons.block : Icons.send, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            isDisabled ? 'Job Unavailable' : 'Apply Now',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDistanceColor(double distanceKm) {
    if (distanceKm <= 5) {
      return Colors.green.shade700;
    } else if (distanceKm <= 15) {
      return Colors.blue.shade700;
    } else if (distanceKm <= 30) {
      return Colors.orange.shade700;
    } else {
      return Colors.grey.shade700;
    }
  }

  Color _getDistanceBgColor(double distanceKm) {
    if (distanceKm <= 5) {
      return Colors.green.shade50;
    } else if (distanceKm <= 15) {
      return Colors.blue.shade50;
    } else if (distanceKm <= 30) {
      return Colors.orange.shade50;
    } else {
      return Colors.grey.shade100;
    }
  }
}
