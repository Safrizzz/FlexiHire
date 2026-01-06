import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/bottom_nav_bar.dart';
import '../components/main_shell.dart';
import '../models/job.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'student_job_details_page.dart';

class DiscoveryPage extends StatefulWidget {
  final bool showBottomNav;
  
  const DiscoveryPage({super.key, this.showBottomNav = true});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage>
    with TickerProviderStateMixin {
  int _selectedNavIndex = 0;
  final FirestoreService _service = FirestoreService();
  
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter values
  double _distanceRange = 50.0; // km
  double _minPay = 0;
  double _maxPay = 100;
  DateTime? _startDate;
  DateTime? _endDate;

  // User data
  List<String> _userSkills = [];
  String _userLocation = '';
  GeoLocation? _userGeoLocation;

  // Animation controllers
  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnimation;

  // Active filters count
  int get _activeFiltersCount {
    int count = 0;
    if (_distanceRange < 50) count++;
    if (_minPay > 0 || _maxPay < 100) count++;
    if (_startDate != null || _endDate != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _headerAnimController.forward();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _searchController.dispose();
    super.dispose();
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
    } catch (_) {}
  }

  double? _calculateJobDistance(Job job) {
    if (_userGeoLocation == null || !_userGeoLocation!.isValid) return null;
    if (job.geoLocation == null || !job.geoLocation!.isValid) return null;
    return LocationService.calculateDistance(
      _userGeoLocation!,
      job.geoLocation!,
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterBottomSheet(
        distanceRange: _distanceRange,
        minPay: _minPay,
        maxPay: _maxPay,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (distance, minPay, maxPay, start, end) {
          setState(() {
            _distanceRange = distance;
            _minPay = minPay;
            _maxPay = maxPay;
            _startDate = start;
            _endDate = end;
          });
          Navigator.pop(ctx);
        },
        onReset: () {
          setState(() {
            _distanceRange = 50.0;
            _minPay = 0;
            _maxPay = 100;
            _startDate = null;
            _endDate = null;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildQuickFilters()),
          _buildSmartJobSections(),
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
      expandedHeight: 180,
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
              opacity: _headerFadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.explore_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Discover Jobs',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Find your perfect opportunity',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search bar with filter icon
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search job titles...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 22,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear_rounded,
                                          color: Colors.white.withValues(alpha: 0.7),
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() => _searchQuery = value.trim().toLowerCase());
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showFilterBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: _activeFiltersCount > 0
                                  ? const LinearGradient(
                                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                    )
                                  : null,
                              color: _activeFiltersCount > 0
                                  ? null
                                  : Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _activeFiltersCount > 0
                                    ? Colors.transparent
                                    : Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 22,
                                ),
                                if (_activeFiltersCount > 0)
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$_activeFiltersCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickFilterChip(
              icon: Icons.near_me_rounded,
              label: _distanceRange < 50
                  ? '≤${_distanceRange.toInt()}km'
                  : 'Any Distance',
              isActive: _distanceRange < 50,
              color: const Color(0xFF3B82F6),
              onTap: () => _showFilterBottomSheet(),
            ),
            const SizedBox(width: 10),
            _buildQuickFilterChip(
              icon: Icons.payments_rounded,
              label: _minPay > 0 || _maxPay < 100
                  ? 'RM${_minPay.toInt()}-${_maxPay.toInt()}'
                  : 'Any Salary',
              isActive: _minPay > 0 || _maxPay < 100,
              color: const Color(0xFF8B5CF6),
              onTap: () => _showFilterBottomSheet(),
            ),
            const SizedBox(width: 10),
            _buildQuickFilterChip(
              icon: Icons.calendar_month_rounded,
              label: _startDate != null || _endDate != null
                  ? _formatDateRange()
                  : 'Any Date',
              isActive: _startDate != null || _endDate != null,
              color: const Color(0xFF10B981),
              onTap: () => _showFilterBottomSheet(),
            ),
            if (_activeFiltersCount > 0) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _distanceRange = 50.0;
                    _minPay = 0;
                    _maxPay = 100;
                    _startDate = null;
                    _endDate = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.clear_rounded,
                        size: 16,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? color.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? color : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange() {
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
    if (_startDate != null && _endDate != null) {
      return '${_startDate!.day} ${months[_startDate!.month - 1]} - ${_endDate!.day} ${months[_endDate!.month - 1]}';
    } else if (_startDate != null) {
      return 'From ${_startDate!.day} ${months[_startDate!.month - 1]}';
    } else if (_endDate != null) {
      return 'Until ${_endDate!.day} ${months[_endDate!.month - 1]}';
    }
    return 'Any Date';
  }

  // Get overlapping skills between user and job
  List<String> _getMatchingSkills(Job job) {
    if (_userSkills.isEmpty || job.skillsRequired.isEmpty) return [];
    return job.skillsRequired
        .where((skill) => _userSkills.any(
            (userSkill) => userSkill.toLowerCase() == skill.toLowerCase()))
        .toList();
  }

  // Smart job categorization
  Map<String, List<Job>> _categorizeJobs(List<Job> allJobs) {
    final List<Job> recommended = [];
    final List<Job> nearby = [];
    final List<Job> moreJobs = [];
    final Set<String> usedJobIds = {};

    // First pass: Find recommended jobs (jobs with matching skills)
    for (final job in allJobs) {
      final matchingSkills = _getMatchingSkills(job);
      if (matchingSkills.isNotEmpty) {
        recommended.add(job);
        usedJobIds.add(job.id);
      }
    }

    // Sort recommended by number of matching skills (descending)
    recommended.sort((a, b) {
      final aMatches = _getMatchingSkills(a).length;
      final bMatches = _getMatchingSkills(b).length;
      return bMatches.compareTo(aMatches);
    });

    // Second pass: Find nearby jobs (within 15km, not already in recommended)
    for (final job in allJobs) {
      if (usedJobIds.contains(job.id)) continue;
      final distance = _calculateJobDistance(job);
      if (distance != null && distance <= 15) {
        nearby.add(job);
        usedJobIds.add(job.id);
      }
    }

    // Sort nearby by distance (ascending)
    nearby.sort((a, b) {
      final distA = _calculateJobDistance(a) ?? double.infinity;
      final distB = _calculateJobDistance(b) ?? double.infinity;
      return distA.compareTo(distB);
    });

    // Third pass: Remaining jobs go to "More Jobs"
    for (final job in allJobs) {
      if (!usedJobIds.contains(job.id)) {
        moreJobs.add(job);
      }
    }

    // Sort more jobs by match score
    moreJobs.sort((a, b) => _matchScore(b).compareTo(_matchScore(a)));

    return {
      'recommended': recommended,
      'nearby': nearby,
      'more': moreJobs,
    };
  }

  Widget _buildSmartJobSections() {
    return StreamBuilder<List<Job>>(
      stream: _service.streamJobs(
        minPay: _minPay > 0 ? _minPay : null,
        maxPay: _maxPay < 100 ? _maxPay : null,
        startDate: _startDate,
        endDate: _endDate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
          );
        }

        var jobs = snapshot.data ?? [];

        // Apply search filter by job title
        if (_searchQuery.isNotEmpty) {
          jobs = jobs.where((job) {
            return job.title.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        // Apply distance filter client-side (since we need user's location)
        if (_distanceRange < 50 && _userGeoLocation != null) {
          jobs = jobs.where((job) {
            final distance = _calculateJobDistance(job);
            if (distance == null) return true;
            return distance <= _distanceRange;
          }).toList();
        }

        if (jobs.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }

        // Categorize jobs into sections
        final categorized = _categorizeJobs(jobs);
        final recommended = categorized['recommended']!;
        final nearby = categorized['nearby']!;
        final moreJobs = categorized['more']!;

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recommended For You Section
              if (recommended.isNotEmpty) ...[
                _buildSectionTitle(
                  'Recommended For You',
                  Icons.auto_awesome_rounded,
                  const Color(0xFF0A1628),
                  subtitle: 'Based on your skills',
                ),
                const SizedBox(height: 12),
                _buildHorizontalJobCarousel(
                  jobs: recommended,
                  showMatchingSkills: true,
                  cardGradient: const [Color(0xFF0A1628), Color(0xFF1A3A5C)],
                ),
                const SizedBox(height: 28),
              ],

              // Nearby You Section
              if (nearby.isNotEmpty) ...[
                _buildSectionTitle(
                  'Nearby You',
                  Icons.near_me_rounded,
                  const Color(0xFF0A1628),
                  subtitle: 'Within 15km of your location',
                ),
                const SizedBox(height: 12),
                _buildHorizontalJobCarousel(
                  jobs: nearby,
                  showMatchingSkills: false,
                  showDistance: true,
                  cardGradient: const [Color(0xFF0A1628), Color(0xFF1A3A5C)],
                ),
                const SizedBox(height: 28),
              ],

              // More Jobs Section
              if (moreJobs.isNotEmpty) ...[
                _buildSectionTitle(
                  'More Jobs',
                  Icons.work_outline_rounded,
                  const Color(0xFF0A1628),
                  subtitle: 'Explore all opportunities',
                ),
                const SizedBox(height: 12),
                _buildVerticalJobCarousel(moreJobs),
              ],

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalJobCarousel({
    required List<Job> jobs,
    required bool showMatchingSkills,
    bool showDistance = false,
    required List<Color> cardGradient,
  }) {
    return SizedBox(
      height: showMatchingSkills ? 260 : 230,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          final matchingSkills = _getMatchingSkills(job);
          final distance = _calculateJobDistance(job);

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 8 : 4,
              right: index == jobs.length - 1 ? 8 : 4,
            ),
            child: _HorizontalJobCard(
              job: job,
              matchingSkills: showMatchingSkills ? matchingSkills : [],
              distance: distance,
              showDistance: showDistance,
              gradientColors: cardGradient,
              onTap: () {
                if (job.status == 'open') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentJobDetailsPage(
                        job: job,
                        distance: distance,
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalJobCarousel(List<Job> jobs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: jobs.asMap().entries.map((entry) {
          final job = entry.value;
          final distance = _calculateJobDistance(job);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AspectRatio(
              aspectRatio: 1.45,
              child: _HorizontalJobCard(
                job: job,
                matchingSkills: const [],
                distance: distance,
                showDistance: true,
                gradientColors: const [Color(0xFF0A1628), Color(0xFF1A3A5C)],
                onTap: () {
                  if (job.status == 'open') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentJobDetailsPage(
                          job: job,
                          distance: distance,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No jobs found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          if (_activeFiltersCount > 0)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _distanceRange = 50.0;
                  _minPay = 0;
                  _maxPay = 100;
                  _startDate = null;
                  _endDate = null;
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _matchScore(Job job) {
    double score = 0;
    if (_userSkills.isNotEmpty && job.skillsRequired.isNotEmpty) {
      final overlap = job.skillsRequired
          .where((s) => _userSkills.contains(s))
          .length;
      score += overlap / job.skillsRequired.length;
    }

    final distance = _calculateJobDistance(job);
    if (distance != null) {
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

    return score > 1 ? 1 : score;
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
}

// ============================================================================
// FILTER BOTTOM SHEET
// ============================================================================

class _FilterBottomSheet extends StatefulWidget {
  final double distanceRange;
  final double minPay;
  final double maxPay;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(double, double, double, DateTime?, DateTime?) onApply;
  final VoidCallback onReset;

  const _FilterBottomSheet({
    required this.distanceRange,
    required this.minPay,
    required this.maxPay,
    required this.startDate,
    required this.endDate,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late double _distance;
  late double _minPay;
  late double _maxPay;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _distance = widget.distanceRange;
    _minPay = widget.minPay;
    _maxPay = widget.maxPay;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Jobs',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Customize your search',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // Filters content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance Range
                  _buildSectionHeader(
                    icon: Icons.near_me_rounded,
                    title: 'Distance Range',
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 16),
                  _buildDistanceSlider(),
                  const SizedBox(height: 28),

                  // Salary Range
                  _buildSectionHeader(
                    icon: Icons.payments_rounded,
                    title: 'Hourly Rate (RM)',
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 16),
                  _buildSalarySlider(),
                  const SizedBox(height: 28),

                  // Date Range
                  _buildSectionHeader(
                    icon: Icons.calendar_month_rounded,
                    title: 'Date Range',
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  _buildDatePickers(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Bottom actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onReset,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Reset All',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApply(
                            _distance,
                            _minPay,
                            _maxPay,
                            _startDate,
                            _endDate,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceSlider() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Within',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _distance >= 50 ? 'Any distance' : '${_distance.toInt()} km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF3B82F6),
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: const Color(0xFF3B82F6),
              overlayColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight: 6,
            ),
            child: Slider(
              value: _distance,
              min: 5,
              max: 50,
              divisions: 9,
              onChanged: (v) => setState(() => _distance = v),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5 km',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Text(
                '50+ km',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySlider() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hourly rate',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'RM ${_minPay.toInt()} - ${_maxPay >= 100 ? '100+' : _maxPay.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF8B5CF6),
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: const Color(0xFF8B5CF6),
              overlayColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight: 6,
            ),
            child: RangeSlider(
              values: RangeValues(_minPay, _maxPay),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (v) {
                setState(() {
                  _minPay = v.start;
                  _maxPay = v.end;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RM 0',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Text(
                'RM 100+',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickers() {
    return Row(
      children: [
        Expanded(
          child: _buildDateButton(
            label: _startDate != null ? _formatDate(_startDate!) : 'Start Date',
            isSelected: _startDate != null,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF10B981),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Color(0xFF1E293B),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (d != null) setState(() => _startDate = d);
            },
            onClear: _startDate != null
                ? () => setState(() => _startDate = null)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateButton(
            label: _endDate != null ? _formatDate(_endDate!) : 'End Date',
            isSelected: _endDate != null,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _endDate ?? _startDate ?? DateTime.now(),
                firstDate:
                    _startDate ??
                    DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF10B981),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Color(0xFF1E293B),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (d != null) setState(() => _endDate = d);
            },
            onClear: _endDate != null
                ? () => setState(() => _endDate = null)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981).withValues(alpha: 0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: isSelected
                  ? const Color(0xFF10B981)
                  : Colors.grey.shade500,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade600,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
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
}

// ============================================================================
// HORIZONTAL JOB CARD (FOR SWIPEABLE CAROUSEL)
// ============================================================================

class _HorizontalJobCard extends StatelessWidget {
  final Job job;
  final List<String> matchingSkills;
  final double? distance;
  final bool showDistance;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _HorizontalJobCard({
    required this.job,
    required this.matchingSkills,
    required this.distance,
    required this.showDistance,
    required this.gradientColors,
    required this.onTap,
  });

  String _formatDate(DateTime d) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = '${_formatDate(job.startDate)} - ${_formatDate(job.endDate)}';
    String? timeRange;
    if (job.startTime != null && job.endTime != null) {
      timeRange = '${job.startTime} - ${job.endTime}';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient - Title, Location, and Pay Rate
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'RM ${job.pay}/hr',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job.location,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
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
            // Content - Date, Time, Distance, Skills
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              dateRange,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3B82F6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Time and Distance row
                    Row(
                      children: [
                        if (timeRange != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7043).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: Color(0xFFFF7043),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  timeRange,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFFF7043),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (timeRange != null && distance != null)
                          const SizedBox(width: 6),
                        if (distance != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.near_me_rounded,
                                  size: 12,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  LocationService.formatDistance(distance!),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    // Matching skills section
                    if (matchingSkills.isNotEmpty) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981).withValues(alpha: 0.1),
                              const Color(0xFF059669).withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: Color(0xFF059669),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Your matching skills',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: matchingSkills.take(3).map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    skill,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (matchingSkills.length > 3) ...[
                              const SizedBox(height: 4),
                              Text(
                                '+${matchingSkills.length - 3} more',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (matchingSkills.isEmpty) const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// JOB CARD WIDGET
// ============================================================================

class _JobCard extends StatefulWidget {
  final Job job;
  final bool isRecommended;
  final double? distance;
  final int animationDelay;
  final VoidCallback onTap;

  const _JobCard({
    required this.job,
    required this.isRecommended,
    required this.distance,
    required this.animationDelay,
    required this.onTap,
  });

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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

  String _formatDate(DateTime d) {
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
    final job = widget.job;
    final dateRange =
        '${_formatDate(job.startDate)} - ${_formatDate(job.endDate)}';
    String? timeRange;
    if (job.startTime != null && job.endTime != null) {
      timeRange = '${job.startTime} - ${job.endTime}';
    }

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
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A1628).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isRecommended
                        ? [const Color(0xFF059669), const Color(0xFF10B981)]
                        : [const Color(0xFF0A1628), const Color(0xFF1A3A5C)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'RM ${job.pay}/hr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.location,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
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
              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    // Info chips row
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.calendar_today_rounded,
                          label: dateRange,
                          color: const Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                    if (timeRange != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildInfoChip(
                            icon: Icons.access_time_rounded,
                            label: timeRange,
                            color: const Color(0xFFFF7043),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Bottom row with distance and arrow
                    Row(
                      children: [
                        if (widget.distance != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getDistanceColor(widget.distance!),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getDistanceTextColor(
                                  widget.distance!,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.near_me_rounded,
                                  size: 16,
                                  color: _getDistanceTextColor(
                                    widget.distance!,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  LocationService.formatDistance(
                                    widget.distance!,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _getDistanceTextColor(
                                      widget.distance!,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1628),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

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
}
