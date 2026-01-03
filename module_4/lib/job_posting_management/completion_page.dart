import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class CompletionPage extends StatefulWidget {
  final String jobId;
  final num pay;
  const CompletionPage({super.key, required this.jobId, required this.pay});

  @override
  State<CompletionPage> createState() => _CompletionPageState();
}

class _CompletionPageState extends State<CompletionPage> {
  final _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Complete Job', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _service.streamJobApplications(widget.jobId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final applications = (snapshot.data ?? []).where((a) => a.status == 'accepted').toList();
          if (applications.isEmpty) {
            return const Center(
              child: Text('No accepted applicants to pay yet.', style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: FutureBuilder(
                    future: _service.getUserProfile(app.applicantId),
                    builder: (context, snap) {
                      final p = snap.data;
                      return Text(p?.displayName ?? app.applicantId);
                    },
                  ),
                  subtitle: Text('Pay RM ${widget.pay.toString()}'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1E3C)),
                    onPressed: () async {
                      await _service.recordTransfer(
                        toIdentifier: app.applicantId,
                        amount: widget.pay.toDouble(),
                        description: 'Job completion payment',
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paid')));
                    },
                    child: const Text('Pay', style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () async {
              await _service.updateJobStatus(widget.jobId, 'completed');
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job marked as completed')));
              Navigator.pop(context);
            },
            child: const Text('Mark Job Completed', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
