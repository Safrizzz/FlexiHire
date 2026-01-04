import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job.dart';
import '../models/application.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '';

  Future<void> ensureUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    final profile = UserProfile(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
      phone: '',
      location: '',
      skills: const [],
      role: UserRole.student,
    );
    await ref.set(profile.toMap());
  }

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
        // Only show open jobs in discovery
        if (job.status != 'open') {
          return false;
        }
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

  Stream<UserProfile?> streamUserProfile(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.id).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<UserProfile?> getUserByEmail(String email) async {
    final qs = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (qs.docs.isEmpty) return null;
    final d = qs.docs.first;
    return UserProfile.fromMap(d.id, d.data());
  }

  Future<List<UserProfile>> searchUsersByNamePrefix(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    final start = query.trim();
    final end = '$start\uf8ff';
    final qs = await _db
        .collection('users')
        .orderBy('displayName')
        .startAt([start])
        .endAt([end])
        .limit(limit)
        .get();
    return qs.docs.map((d) => UserProfile.fromMap(d.id, d.data())).toList();
  }

  Future<double> getBalance(String userId) async {
    final qs = await _db.collection('transactions').where('userId', isEqualTo: userId).get();
    double sum = 0;
    for (final d in qs.docs) {
      final v = d.data()['amount'];
      if (v is num) sum += v.toDouble();
      if (v is String) sum += double.tryParse(v) ?? 0;
    }
    return sum;
  }

  Stream<List<Map<String, dynamic>>> streamTransactionsForUser(String userId) {
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          list.sort((a, b) {
            int toTime(Map<String, dynamic> m) {
              final v = m['createdAt'];
              if (v is Timestamp) return v.millisecondsSinceEpoch;
              if (v is String) return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
              if (v is DateTime) return v.millisecondsSinceEpoch;
              return 0;
            }
            return toTime(b).compareTo(toTime(a));
          });
          return list;
        });
  }

  Future<void> recordTransfer({
    required String toIdentifier, // email or uid
    required double amount,
    String? description,
  }) async {
    String? toUid;
    if (toIdentifier.contains('@')) {
      final qs = await _db.collection('users').where('email', isEqualTo: toIdentifier).limit(1).get();
      if (qs.docs.isNotEmpty) {
        toUid = qs.docs.first.id;
      }
    } else {
      toUid = toIdentifier;
    }
    final fromUid = uid;
    if (fromUid.isEmpty || toUid == null) {
      throw Exception('Invalid users for transfer');
    }
    final now = DateTime.now().toIso8601String();
    final batch = _db.batch();
    final debitRef = _db.collection('transactions').doc();
    final creditRef = _db.collection('transactions').doc();
    batch.set(debitRef, {
      'userId': fromUid,
      'amount': -amount.abs(),
      'type': 'debit',
      'source': 'employer_transfer',
      'description': description ?? '',
      'counterparty': toUid,
      'createdAt': now,
    });
    batch.set(creditRef, {
      'userId': toUid,
      'amount': amount.abs(),
      'type': 'credit',
      'source': 'employer_transfer',
      'description': description ?? '',
      'counterparty': fromUid,
      'createdAt': now,
    });
    await batch.commit();
  }

  Future<void> recordWithdrawal({
    required double amount,
    String? bankName,
    String? accountNumber,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db.collection('transactions').add({
      'userId': uid,
      'amount': -amount.abs(),
      'type': 'withdrawal',
      'source': 'withdrawal_request',
      'description': 'Bank: ${bankName ?? ''}, Account: ${accountNumber ?? ''}',
      'createdAt': now,
    });
  }

  Future<void> recordTopUp({
    required double amount,
    String? description,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db.collection('transactions').add({
      'userId': uid,
      'amount': amount.abs(),
      'type': 'topup',
      'source': 'top_up',
      'description': description ?? '',
      'createdAt': now,
    });
  }

  Future<String> createJob(Job job) async {
    final ref = await _db.collection('jobs').add(job.toMap());
    return ref.id;
  }

  Future<void> updateJob(Job job) async {
    await _db.collection('jobs').doc(job.id).set(job.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteJob(String jobId) async {
    await _db.collection('jobs').doc(jobId).delete();
  }

  Stream<List<Job>> streamEmployerJobs(String employerId) {
    return _db
        .collection('jobs')
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => Job.fromMap(d.id, d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    await _db.collection('jobs').doc(jobId).update({'status': status});
  }

  Stream<List<Application>> streamJobApplications(String jobId) {
    return _db
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((s) => s.docs.map((d) => Application.fromMap(d.id, d.data())).toList());
  }

  Future<void> updateApplicationStatus(String applicationId, String status) async {
    await _db.collection('applications').doc(applicationId).update({'status': status});
  }

  Future<void> submitEmployerReview({
    required String employeeId,
    required String jobId,
    required double punctuality,
    required double efficiency,
    required double communication,
    required double teamwork,
    required double attitude,
    String? comment,
  }) async {
    final average = (punctuality + efficiency + communication + teamwork + attitude) / 5.0;
    await _db.collection('ratings').add({
      'employeeId': employeeId,
      'employerId': uid,
      'jobId': jobId,
      'punctuality': punctuality,
      'efficiency': efficiency,
      'communication': communication,
      'teamwork': teamwork,
      'attitude': attitude,
      'average': average,
      'comment': comment ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamEmployeeRatings(String employeeId) {
    return _db
        .collection('ratings')
        .where('employeeId', isEqualTo: employeeId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          list.sort((a, b) {
            int toTime(Map<String, dynamic> m) {
              final v = m['createdAt'];
              if (v is Timestamp) return v.millisecondsSinceEpoch;
              if (v is String) return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
              if (v is DateTime) return v.millisecondsSinceEpoch;
              return 0;
            }
            return toTime(b).compareTo(toTime(a));
          });
          return list;
        });
  }

  Future<double> getEmployeeAverageRating(String employeeId) async {
    final qs = await _db.collection('ratings').where('employeeId', isEqualTo: employeeId).get();
    if (qs.docs.isEmpty) return 0;
    double sum = 0;
    for (final d in qs.docs) {
      final v = d.data()['average'];
      if (v is num) sum += v.toDouble();
      if (v is String) sum += double.tryParse(v) ?? 0;
    }
    return sum / qs.docs.length;
  }

  Future<void> submitStudentReview({
    required String employerId,
    required String jobId,
    required double communication,
    required double fairness,
    required double promptPayment,
    required double overall,
    String? comment,
  }) async {
    final average = (communication + fairness + promptPayment + overall) / 4.0;
    await _db.collection('employer_ratings').add({
      'employerId': employerId,
      'studentId': uid,
      'jobId': jobId,
      'communication': communication,
      'fairness': fairness,
      'promptPayment': promptPayment,
      'overall': overall,
      'average': average,
      'comment': comment ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamEmployerRatings(String employerId) {
    return _db
        .collection('employer_ratings')
        .where('employerId', isEqualTo: employerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<double> getEmployerAverageRating(String employerId) async {
    final qs = await _db.collection('employer_ratings').where('employerId', isEqualTo: employerId).get();
    if (qs.docs.isEmpty) return 0;
    double sum = 0;
    for (final d in qs.docs) {
      final v = d.data()['average'];
      if (v is num) sum += v.toDouble();
      if (v is String) sum += double.tryParse(v) ?? 0;
    }
    return sum / qs.docs.length;
  }
}
