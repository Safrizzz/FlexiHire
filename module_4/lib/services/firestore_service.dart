import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job.dart';
import '../models/application.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '';

  Stream<List<Job>> streamJobs({
    String? location,
    num? minPay,
    num? maxPay,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> q = _db.collection('jobs').orderBy('createdAt', descending: true);
    return q.snapshots().map((s) {
      final jobs = s.docs.map((d) => Job.fromMap(d.id, d.data())).toList();
      return jobs.where((job) {
        bool ok = true;
        if (location != null && location.isNotEmpty) {
          final qLoc = location.toLowerCase().trim();
          final jLoc = job.location.toLowerCase().trim();
          ok = ok && jLoc.contains(qLoc);
        }
        if (minPay != null) {
          ok = ok && job.pay >= minPay;
        }
        if (maxPay != null) {
          ok = ok && job.pay <= maxPay;
        }
        if (startDate != null) {
          ok = ok && job.startDate.isAfter(startDate.subtract(const Duration(days: 1)));
        }
        if (endDate != null) {
          ok = ok && job.endDate.isBefore(endDate.add(const Duration(days: 1)));
        }
        return ok;
      }).toList();
    });
  }

  Future<String> applyToJob(Job job) async {
    final doc = await _db
        .collection('applications')
        .where('jobId', isEqualTo: job.id)
        .where('applicantId', isEqualTo: uid)
        .limit(1)
        .get();
    if (doc.docs.isEmpty) {
      await _db.collection('applications').add({
        'jobId': job.id,
        'applicantId': uid,
        'status': 'applied',
        'createdAt': DateTime.now().toIso8601String(),
      });
      return 'applied';
    }
    final existing = doc.docs.first;
    final data = existing.data();
    final status = data['status']?.toString() ?? 'applied';
    if (status == 'withdrawn') {
      await existing.reference.update({
        'status': 'applied',
        'createdAt': DateTime.now().toIso8601String(),
      });
      return 'reapplied';
    }
    return 'already';
  }

  Future<void> withdrawApplication(String applicationId) async {
    await _db.collection('applications').doc(applicationId).update({'status': 'withdrawn'});
  }

  Stream<List<Application>> streamMyApplications() {
    return _db
        .collection('applications')
        .where('applicantId', isEqualTo: uid)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => Application.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<String> createOrOpenChat({required String employerId, required String jobId}) async {
    final participants = [uid, employerId]..sort();
    final existing = await _db
        .collection('chats')
        .where('participants', isEqualTo: participants)
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }
    final ref = await _db.collection('chats').add({
      'participants': participants,
      'jobId': jobId,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return ref.id;
  }

  Future<Job?> getJob(String jobId) async {
    final doc = await _db.collection('jobs').doc(jobId).get();
    if (!doc.exists) return null;
    return Job.fromMap(doc.id, doc.data()!);
  }

  Stream<List<Chat>> streamMyChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => Chat.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<Message>> streamMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Message.fromMap(d.id, d.data())).toList());
  }

  Stream<Message?> streamLastMessage(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : Message.fromMap(s.docs.first.id, s.docs.first.data()));
  }

  Future<void> sendMessage(String chatId, String text) async {
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': uid,
      'text': text,
      'sentAt': DateTime.now().toIso8601String(),
    });
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.id, doc.data()!);
  }
}
