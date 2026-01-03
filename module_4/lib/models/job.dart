import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String title;
  final String description;
  final String location;
  final num pay;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> skillsRequired;
  final String employerId;
  final DateTime createdAt;
  final String status;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.pay,
    required this.startDate,
    required this.endDate,
    required this.skillsRequired,
    required this.employerId,
    required this.createdAt,
    this.status = 'open',
  });

  factory Job.fromMap(String id, Map<String, dynamic> data) {
    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }
    num _toNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
      return 0;
    }

    return Job(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      pay: _toNum(data['pay']),
      startDate: _toDate(data['startDate']),
      endDate: _toDate(data['endDate']),
      skillsRequired:
          List<String>.from((data['skillsRequired'] ?? []).map((e) => e.toString())),
      employerId: data['employerId'] ?? '',
      createdAt: _toDate(data['createdAt']),
      status: data['status']?.toString() ?? 'open',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'pay': pay,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'skillsRequired': skillsRequired,
      'employerId': employerId,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
