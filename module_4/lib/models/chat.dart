import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants;
  final String jobId;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.participants,
    required this.jobId,
    required this.createdAt,
  });

  factory Chat.fromMap(String id, Map<String, dynamic> data) {
    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }
    return Chat(
      id: id,
      participants: List<String>.from((data['participants'] ?? []).map((e) => e.toString())),
      jobId: data['jobId'] ?? '',
      createdAt: _toDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'jobId': jobId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
