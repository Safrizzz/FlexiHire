import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/bottom_nav_bar.dart';
import '../models/job.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../matching_chatting/message_page.dart';
import '../authentication_profile/auth_account_page.dart';
import 'student_job_details_page.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  int _selectedNavIndex = 0; // Discovery tab
  final FirestoreService _service = FirestoreService();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _minPayCtrl = TextEditingController();
  final TextEditingController _maxPayCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _userSkills = [];
  String _userLocation = '';
  GeoLocation?
  _userGeoLocation; // User's geo coordinates for distance calculation

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final data = doc.data() ?? {};

        // Parse geo location
        GeoLocation? geoLoc;
        if (data['geoLocation'] != null && data['geoLocation'] is Map) {
          geoLoc = GeoLocation.fromMap(
            Map<String, dynamic>.from(data['geoLocation']),
          );
        }

        setState(() {
          _userSkills = List<String>.from(
            (data['skills'] ?? []).map((e) => e.toString()),
          );
          _userLocation = data['location']?.toString() ?? '';
          _userGeoLocation = geoLoc;
        });
      }
    } catch (_) {
      // Handle error silently
    }
  }

  /// Calculate distance between user and job location
  double? _calculateJobDistance(Job job) {
    if (_userGeoLocation == null || !_userGeoLocation!.isValid) return null;
    if (job.geoLocation == null || !job.geoLocation!.isValid) return null;

    return LocationService.calculateDistance(
      _userGeoLocation!,
      job.geoLocation!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 251),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0,
        title: const Text(
          'Discovery',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<Job>>(
              stream: _service.streamJobs(
                location: _locationCtrl.text.isEmpty
                    ? null
                    : _locationCtrl.text,
                minPay: _parseNum(_minPayCtrl.text),
                maxPay: _parseNum(_maxPayCtrl.text),
                startDate: _startDate,
                endDate: _endDate,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final jobs = snapshot.data ?? [];
                if (jobs.isEmpty) {
                  return Center(
                    child: Text(
                      'No jobs found',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                final scored =
                    jobs.map((j) => MapEntry(j, _matchScore(j))).toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                return ListView.builder(
                  itemCount: scored.length,
                  itemBuilder: (context, index) {
                    final job = scored[index].key;
                    final score = scored[index].value;
                    final recommended = score >= 0.6;
                    return _jobTile(job, recommended);
                  },
                );
              },
            ),
          ),
        ],
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

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Location and Pay filters
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildFilterField(
                  controller: _locationCtrl,
                  hint: 'Location',
                  icon: Icons.location_on_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFilterField(
                  controller: _minPayCtrl,
                  hint: 'Min Pay',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFilterField(
                  controller: _maxPayCtrl,
                  hint: 'Max Pay',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date filters
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: _startDate == null
                      ? 'Start Date'
                      : _formatFilterDate(_startDate!),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    setState(() {
                      _startDate = d;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDateButton(
                  label: _endDate == null
                      ? 'End Date'
                      : _formatFilterDate(_endDate!),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    setState(() {
                      _endDate = d;
                    });
                  },
                ),
              ),
              if (_startDate != null || _endDate != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = !label.contains('Date');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: isSelected
                  ? const Color(0xFF1565C0)
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF1565C0)
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFilterDate(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]}';
  }

  Widget _jobTile(Job job, bool recommended) {
    final distance = _calculateJobDistance(job);

    // Format date range
    String formatDate(DateTime d) {
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

    final dateRange =
        '${formatDate(job.startDate)} - ${formatDate(job.endDate)}';

    // Format time range
    String? timeRange;
    if (job.startTime != null && job.endTime != null) {
      timeRange = '${job.startTime} - ${job.endTime}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            // Header: Title and Recommended badge
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
                if (recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Recommended',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Info rows
            _buildInfoRow(
              Icons.location_on_outlined,
              job.location,
              const Color(0xFF5C6BC0),
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              dateRange,
              const Color(0xFF26A69A),
            ),
            if (timeRange != null) ...[
              const SizedBox(height: 10),
              _buildInfoRow(
                Icons.access_time_outlined,
                timeRange,
                const Color(0xFFFF7043),
              ),
            ],
            const SizedBox(height: 16),

            // Salary and Distance row
            Row(
              children: [
                // Salary chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: Color(0xFF7B1FA2),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'RM ${job.pay}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7B1FA2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Distance chip
                if (distance != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getDistanceColor(distance),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.near_me_outlined,
                          size: 16,
                          color: _getDistanceTextColor(distance),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          LocationService.formatDistance(distance),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getDistanceTextColor(distance),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: job.status != 'open'
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentJobDetailsPage(
                                  job: job,
                                  distance: distance,
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F1E3C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          job.status != 'open'
                              ? Icons.block
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          job.status != 'open' ? 'Unavailable' : 'View Details',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget to build info rows with icon and text
  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF424242),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Get background color for distance badge based on distance
  Color _getDistanceColor(double distanceKm) {
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

  /// Get text color for distance badge based on distance
  Color _getDistanceTextColor(double distanceKm) {
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

  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        // Already on Discovery
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/my_jobs');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/message');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

  double _matchScore(Job job) {
    double score = 0;
    if (_userSkills.isNotEmpty && job.skillsRequired.isNotEmpty) {
      final overlap = job.skillsRequired
          .where((s) => _userSkills.contains(s))
          .length;
      score += overlap / job.skillsRequired.length;
    }

    // Location matching - use distance if geo data available
    final distance = _calculateJobDistance(job);
    if (distance != null) {
      // Closer jobs get higher scores
      // Within 5km: +0.4, 5-15km: +0.3, 15-30km: +0.2, 30-50km: +0.1
      if (distance <= 5) {
        score += 0.4;
      } else if (distance <= 15) {
        score += 0.3;
      } else if (distance <= 30) {
        score += 0.2;
      } else if (distance <= 50) {
        score += 0.1;
      }
    } else if (_userLocation.isNotEmpty && job.location.isNotEmpty) {
      // Fallback to text matching if no geo data
      if (_userLocation.toLowerCase().trim() ==
          job.location.toLowerCase().trim()) {
        score += 0.3;
      }
    }

    if (_startDate != null && _endDate != null) {
      final overlaps =
          !(job.endDate.isBefore(_startDate!) ||
              job.startDate.isAfter(_endDate!));
      if (overlaps) score += 0.2;
    }
    if (score > 1) score = 1;
    return score;
  }

  num? _parseNum(String s) {
    if (s.isEmpty) return null;
    final v = num.tryParse(s);
    return v;
  }
}
