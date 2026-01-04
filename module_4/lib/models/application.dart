import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  final String id;
  final String jobId;
  final String applicantId;
  final String status;
  final DateTime createdAt;
  final List<DateTime> selectedDates; // Dates the student wants to work

  Application({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.status,
    required this.createdAt,
    this.selectedDates = const [],
  });

  factory Application.fromMap(String id, Map<String, dynamic> data) {
    DateTime toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    // Parse selected dates
    List<DateTime> dates = [];
    if (data['selectedDates'] != null && data['selectedDates'] is List) {
      dates = (data['selectedDates'] as List)
          .map((d) => toDate(d))
          .toList();
    }

    return Application(
      id: id,
      jobId: data['jobId'] ?? '',
      applicantId: data['applicantId'] ?? '',
      status: data['status'] ?? 'applied',
      createdAt: toDate(data['createdAt']),
      selectedDates: dates,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'applicantId': applicantId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'selectedDates': selectedDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  Application copyWith({
    String? id,
    String? jobId,
    String? applicantId,
    String? status,
    DateTime? createdAt,
    List<DateTime>? selectedDates,
  }) {
    return Application(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      applicantId: applicantId ?? this.applicantId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      selectedDates: selectedDates ?? this.selectedDates,
    );
  }
}
