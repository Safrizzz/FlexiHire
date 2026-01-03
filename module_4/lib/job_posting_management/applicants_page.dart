import 'package:flutter/material.dart';
import 'job_model.dart';
import 'applicant_detail_page.dart';
import '../services/firestore_service.dart';
import '../models/application.dart' as backend;

class ApplicantsPage extends StatefulWidget {
  final Job job;

  const ApplicantsPage({
    super.key,
    required this.job,
  });

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage> {
  final FirestoreService _service = FirestoreService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Applicants – ${widget.job.title}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<backend.Application>>(
        stream: _service.streamJobApplications(widget.job.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final applications = snapshot.data ?? [];
          if (applications.isEmpty) {
            return const Center(
              child: Text(
                'No applicants yet.',
                style: TextStyle(color: Colors.grey),
              ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FutureBuilder(
                  future: _service.getUserProfile(application.applicantId),
                  builder: (context, snap) {
                    final profile = snap.data;
                    final title = profile?.displayName ?? application.applicantId;
                    final subtitle = profile?.email ?? '';
                    return ListTile(
                      title: Text(title),
                      subtitle: Text(subtitle),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ApplicantDetailPage(applicantId: application.applicantId)),
                        );
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            application.status.toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () => _service.updateApplicationStatus(application.id, 'accepted'),
                            child: const Text('Accept', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => _service.updateApplicationStatus(application.id, 'rejected'),
                            child: const Text('Reject', style: TextStyle(color: Colors.white)),
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
