import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  final String id;
  final String jobId;
  final String applicantId;
  final String status;
  final DateTime createdAt;

  Application({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.status,
    required this.createdAt,
  });

  factory Application.fromMap(String id, Map<String, dynamic> data) {
    DateTime toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }
    return Application(
      id: id,
      jobId: data['jobId'] ?? '',
      applicantId: data['applicantId'] ?? '',
      status: data['status'] ?? 'applied',
      createdAt: toDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'applicantId': applicantId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
