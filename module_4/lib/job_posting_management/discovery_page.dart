import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/bottom_nav_bar.dart';
import '../models/job.dart';
import '../services/firestore_service.dart';
import '../matching_chatting/message_page.dart';
import '../authentication_profile/auth_account_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data() ?? {};
        setState(() {
          _userSkills = List<String>.from((data['skills'] ?? []).map((e) => e.toString()));
          _userLocation = data['location']?.toString() ?? '';
        });
      } else {
        setState(() {});
      }
    } catch (_) {
      setState(() {});
    }
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
                location: _locationCtrl.text.isEmpty ? null : _locationCtrl.text,
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
                final scored = jobs
                    .map((j) => MapEntry(j, _matchScore(j)))
                    .toList()
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _minPayCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min Pay',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _maxPayCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Pay',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
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
                  child: Text(
                    _startDate == null
                        ? 'Start Date'
                        : _startDate!.toLocal().toIso8601String().split('T').first,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
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
                  child: Text(
                    _endDate == null
                        ? 'End Date'
                        : _endDate!.toLocal().toIso8601String().split('T').first,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _jobTile(Job job, bool recommended) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.status.toUpperCase(),
                    style: const TextStyle(color: Color(0xFF616161), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                FutureBuilder<double>(
                  future: _service.getEmployerAverageRating(job.employerId),
                  builder: (context, snapshot) {
                    final avg = snapshot.data ?? 0;
                    return Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
                      ],
                    );
                  },
                ),
                if (recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Recommended',
                      style: TextStyle(color: Color(0xFF00796B), fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(job.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.place, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(job.location),
                const SizedBox(width: 12),
                Text('RM ${job.pay}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: job.skillsRequired
                        .map((s) => Chip(label: Text(s), visualDensity: VisualDensity.compact))
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: job.status != 'open'
                        ? null
                        : () async {
                      if (FirebaseAuth.instance.currentUser == null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthAccountPage(selectedIndex: 0)),
                        );
                        if (FirebaseAuth.instance.currentUser == null) return;
                      }
                      final result = await _service.applyToJob(job);
                      if (!mounted) return;
                      if (result == 'applied') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Applied')),
                        );
                      } else if (result == 'reapplied') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Re-applied')),
                        );
                      } else {
                        await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Already Applied'),
                            content: const Text('You have already applied to this job. Check My Jobs for status.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: Text(job.status != 'open' ? 'Unavailable' : 'Apply'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: job.status != 'open'
                        ? null
                        : () async {
                      if (FirebaseAuth.instance.currentUser == null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthAccountPage(selectedIndex: 0)),
                        );
                        if (FirebaseAuth.instance.currentUser == null) return;
                      }
                      final chatId = await _service.createOrOpenChat(
                        employerId: job.employerId,
                        jobId: job.id,
                      );
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessagePage(chatId: chatId),
                        ),
                      );
                    },
                    child: const Text('Chat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      final overlap = job.skillsRequired.where((s) => _userSkills.contains(s)).length;
      score += overlap / job.skillsRequired.length;
    }
    if (_userLocation.isNotEmpty && job.location.isNotEmpty) {
      if (_userLocation.toLowerCase().trim() == job.location.toLowerCase().trim()) {
        score += 0.3;
      }
    }
    if (_startDate != null && _endDate != null) {
      final overlaps =
          !(job.endDate.isBefore(_startDate!) || job.startDate.isAfter(_endDate!));
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
