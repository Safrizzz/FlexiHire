import 'package:flutter/material.dart';
import 'job_model.dart';
import '../payment_rating/employer_review_page.dart';
import '../payment_rating/employer_transfer_page.dart';
import '../services/firestore_service.dart';
import '../models/application.dart' as backend;

class HiresPage extends StatelessWidget {
  final Job job;

  const HiresPage({
    super.key,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Hired – ${job.title}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<backend.Application>>(
        stream: service.streamJobApplications(job.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final applications = (snapshot.data ?? []).where((a) => a.status.toLowerCase() == 'accepted').toList();
          if (applications.isEmpty) {
            return const Center(
              child: Text('No candidates hired yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: FutureBuilder(
                  future: service.getUserProfile(application.applicantId),
                  builder: (context, snap) {
                    final profile = snap.data;
                    final name = profile?.displayName ?? application.applicantId;
                    final email = profile?.email ?? '';
                    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0F1E3C),
                        child: Text(initials, style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(name),
                      subtitle: Text(email),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1E3C)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EmployerReviewPage(employeeId: application.applicantId, jobId: job.id),
                                ),
                              );
                            },
                            child: const Text('Review', style: TextStyle(color: Colors.white)),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EmployerTransferPage(
                                    employeeEmail: email,
                                    employeeName: name,
                                    employeeId: application.applicantId,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Transfer'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
