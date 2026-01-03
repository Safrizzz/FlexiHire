import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';

class ApplicantDetailPage extends StatelessWidget {
  final String applicantId;
  const ApplicantDetailPage({super.key, required this.applicantId});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0,
        title: const Text('Applicant Detail', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<UserProfile?>(
                future: service.getUserProfile(applicantId),
                builder: (context, snap) {
                  final p = snap.data;
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (p == null) {
                    return const Text('Applicant not found', style: TextStyle(color: Colors.red));
                  }
                  final initials = (p.displayName.isNotEmpty)
                      ? p.displayName.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
                      : (p.email.isNotEmpty ? p.email[0].toUpperCase() : '?');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 28, backgroundColor: const Color(0xFF0F1E3C), child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.displayName.isNotEmpty ? p.displayName : 'No name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(p.email, style: const TextStyle(color: Color(0xFF4B5563))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _infoRow('Phone', p.phone.isNotEmpty ? p.phone : 'Not set'),
                      const SizedBox(height: 8),
                      _infoRow('Location', p.location.isNotEmpty ? p.location : 'Not set'),
                      const SizedBox(height: 12),
                      const Text('Skills', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (p.skills.isEmpty)
                        const Text('No skills provided', style: TextStyle(color: Color(0xFF6B7280)))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: p.skills.map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
                              child: Text(s),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text('Recent Ratings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              FutureBuilder<double>(
                future: service.getEmployeeAverageRating(applicantId),
                builder: (context, avgSnap) {
                  final avg = avgSnap.data ?? 0;
                  return Row(
                    children: [
                      Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      _stars(avg),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: service.streamEmployeeRatings(applicantId),
                builder: (context, ratingsSnap) {
                  final ratings = ratingsSnap.data ?? [];
                  final displayed = ratings.take(5).toList();
                  if (displayed.isEmpty) {
                    return const Text('No reviews yet', style: TextStyle(color: Colors.grey));
                  }
                  return Column(
                    children: displayed.map((r) {
                      final avg = (r['average'] as num?)?.toDouble() ?? 0;
                      final comment = r['comment']?.toString() ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Row(children: [ _stars(avg), const SizedBox(width: 8), Text(avg.toStringAsFixed(1)) ]),
                        subtitle: Text(comment),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _stars(double rating) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i + 1 <= rating.round();
        return Icon(filled ? Icons.star : Icons.star_border, color: Colors.amber, size: 20);
      }),
    );
  }
}

