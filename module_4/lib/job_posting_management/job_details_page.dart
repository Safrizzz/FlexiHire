import 'package:flutter/material.dart';
import 'job_model.dart';
import 'create_job_page.dart';

enum JobDetailsAction { updated, deleted, none }

class JobDetailsResult {
  final JobDetailsAction action;
  final Job? updatedJob;
  JobDetailsResult(this.action, {this.updatedJob});
}

class JobDetailsPage extends StatelessWidget {
  final Job job;
  const JobDetailsPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 251),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        title: const Text('Job Details', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Status: ', style: TextStyle(color: Colors.grey)),
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
                const SizedBox(height: 8),

                _infoRow('Location', job.location),
                const SizedBox(height: 8),
                _infoRow('Pay Rate', 'RM ${job.payRate.toStringAsFixed(2)}/hr'),
                const SizedBox(height: 14),

                const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(job.description, style: const TextStyle(color: Colors.black87)),

                const SizedBox(height: 16),

                const Text('Micro-shifts', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),

                job.microShifts.isEmpty
                    ? const Text(
                        'No micro-shifts set.',
                        style: TextStyle(color: Colors.grey),
                      )
                    : Wrap(
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
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F1E3C),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          // EDIT -> reuse CreateJobPage
                          final updated = await Navigator.push<Job?>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateJobPage(existingJob: job),
                            ),
                          );

                          if (updated != null && context.mounted) {
                            Navigator.pop(
                              context,
                              JobDetailsResult(JobDetailsAction.updated, updatedJob: updated),
                            );
                          }
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text('Edit', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(context, JobDetailsResult(JobDetailsAction.deleted));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
  }
}
