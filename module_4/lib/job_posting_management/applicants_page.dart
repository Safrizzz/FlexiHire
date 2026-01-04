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
                  future: Future.wait([
                    _service.getUserProfile(application.applicantId),
                    _service.getEmployeeAverageRating(application.applicantId),
                  ]),
                  builder: (context, snap) {
                    final profile = snap.data?[0] as dynamic;
                    final rating = snap.data?[1] as double? ?? 0.0;
                    final title = profile?.displayName ?? application.applicantId;
                    final subtitle = profile?.email ?? '';
                    final status = application.status;
                    
                    Color statusColor = Colors.grey;
                    if (status == 'accepted') statusColor = Colors.green;
                    if (status == 'rejected') statusColor = Colors.red;
                    
                    return ListTile(
                      title: Text(title),
                      subtitle: Row(
                        children: [
                          Expanded(child: Text(subtitle)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApplicantDetailPage(
                              applicantId: application.applicantId,
                              applicationId: application.id,
                              currentStatus: application.status,
                            ),
                          ),
                        );
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
