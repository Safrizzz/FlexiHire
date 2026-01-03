import 'package:flutter/material.dart';
import '../components/bottom_nav_bar.dart';
import 'job_model.dart';
import 'create_job_page.dart';
import 'applicants_page.dart';
import '../job_posting_management/hires_page.dart';
import 'completion_page.dart';
import 'job_details_page.dart';
import 'micro_shift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/job.dart' as backend;

class JobPostingPage extends StatefulWidget {
  const JobPostingPage({super.key});

  @override
  State<JobPostingPage> createState() => _JobPostingPageState();
}

class _JobPostingPageState extends State<JobPostingPage> {
  int _selectedNavIndex = 0;
  final FirestoreService _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
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
          final Job? newJob = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateJobPage()),
          );

          if (newJob != null) {
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            if (uid.isEmpty) return;
            final beJob = _toBackendJob(newJob, uid);
            await _service.createJob(beJob);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: _recruiterView(),

      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
          _navigate(index);
        },
      ),
    );
  }

  // ===============================
  // RECRUITER VIEW
  // ===============================
  Widget _recruiterView() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return const Center(child: Text('Please login to manage job postings.'));
    }
    return StreamBuilder<List<backend.Job>>(
      stream: _service.streamEmployerJobs(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final beJobs = snapshot.data ?? [];
        if (beJobs.isEmpty) {
          return const Center(
            child: Text(
              'No job postings yet.\nTap + to create a job.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
            return JobCard(
              job: job,
              onOpenDetails: () async {
                final result = await Navigator.push<JobDetailsResult>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobDetailsPage(job: job),
                  ),
                );
                if (result == null) return;
                if (result.action == JobDetailsAction.updated && result.updatedJob != null) {
                  final updatedBe = _toBackendJob(result.updatedJob!, uid, beId: beJob.id);
                  await _service.updateJob(updatedBe);
                } else if (result.action == JobDetailsAction.deleted) {
                  await _service.deleteJob(beJob.id);
                }
              },
              onApplicants: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ApplicantsPage(job: job)),
                );
              },
              onHires: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HiresPage(job: job)),
                );
              },
              onDelete: () async {
                await _service.deleteJob(beJob.id);
              },
              onSetStatus: (status) async {
                await _service.updateJobStatus(beJob.id, status);
              },
              onComplete: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CompletionPage(jobId: beJob.id, pay: beJob.pay)),
                );
              },
            );
          },
        );
      },
    );
  }

  backend.Job _toBackendJob(Job job, String employerId, {String? beId}) {
    DateTime? earliest;
    DateTime? latest;
    for (final s in job.microShifts) {
      if (earliest == null || s.start.isBefore(earliest)) earliest = s.start;
      if (latest == null || s.end.isAfter(latest)) latest = s.end;
    }
    return backend.Job(
      id: beId ?? '',
      title: job.title,
      description: job.description,
      location: job.location,
      pay: job.payRate,
      startDate: earliest ?? DateTime.now(),
      endDate: latest ?? DateTime.now(),
      skillsRequired: const [],
      employerId: employerId,
      createdAt: DateTime.now(),
      status: job.status,
    );
  }

  Job _toUiJob(backend.Job beJob) {
    return Job(
      id: beJob.id,
      title: beJob.title,
      company: '',
      location: beJob.location,
      payRate: beJob.pay.toDouble(),
      description: beJob.description,
      microShifts: const [],
      status: beJob.status,
      applicants: const [],
      hires: const [],
    );
  }

  void _navigate(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/discovery');
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

// ===============================
// JOB CARD WIDGET
// ===============================
class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onOpenDetails;
  final VoidCallback onApplicants;
  final VoidCallback onHires;
  final VoidCallback onDelete;
  final Future<void> Function(String status)? onSetStatus;
  final VoidCallback? onComplete;

  const JobCard({
    required this.job,
    required this.onOpenDetails,
    required this.onApplicants,
    required this.onHires,
    required this.onDelete,
    this.onSetStatus,
    this.onComplete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpenDetails,
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(job.status.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              Text(job.description, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Text('${job.location} • RM ${job.payRate}/hr',
                style: const TextStyle(color: Colors.black54)),

            if (job.microShifts.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Micro-shifts',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: job.microShifts.map((shift) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      shift.toDisplay(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1E3C), minimumSize: const Size(100, 40)),
                  onPressed: onOpenDetails,
                  child: const Text('Edit', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1E3C), minimumSize: const Size(120, 40)),
                  onPressed: onApplicants,
                  child: const Text('Applicants', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(100, 40)),
                  onPressed: onHires,
                  child: const Text('Hires', style: TextStyle(color: Colors.white)),
                ),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
                if (onComplete != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), minimumSize: const Size(120, 40)),
                    onPressed: onComplete,
                    child: const Text('Complete', style: TextStyle(color: Colors.white)),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) => onSetStatus?.call(value),
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'open', child: Text('Open')),
                    PopupMenuItem(value: 'closed', child: Text('Close')),
                    PopupMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}
