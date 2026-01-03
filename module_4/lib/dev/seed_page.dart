import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_role.dart';

class SeedPage extends StatefulWidget {
  const SeedPage({super.key});
  @override
  State<SeedPage> createState() => _SeedPageState();
}

class _SeedPageState extends State<SeedPage> {
  bool _loading = false;

  Future<void> _seed() async {
    setState(() => _loading = true);
    final db = FirebaseFirestore.instance;
    final now = DateTime.now().toIso8601String();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final service = FirestoreService();
    const demoEmployerId = 'demo-employer';
    const demoStudentId = 'demo-student';

    await db.collection('users').doc(demoEmployerId).set({
      'email': 'employer@example.com',
      'displayName': 'Demo Employer',
      'photoUrl': '',
      'phone': '',
      'location': 'Kuala Lumpur',
      'skills': [],
      'role': 'employer',
    }, SetOptions(merge: true));

    await db.collection('users').doc(demoStudentId).set({
      'email': 'student@example.com',
      'displayName': 'Demo Student',
      'photoUrl': '',
      'phone': '',
      'location': 'Kuala Lumpur',
      'skills': ['Barista'],
      'role': 'student',
    }, SetOptions(merge: true));

    if (uid != null) {
      final profile = await service.getUserProfile(uid);
      if (profile?.role == UserRole.employer) {
        final jobRef = await db.collection('jobs').add({
          'title': 'Demo Barista',
          'description': 'Assist at cafe and handle coffee',
          'location': 'Kuala Lumpur',
          'pay': 20,
          'startDate': now,
          'endDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'skillsRequired': ['Barista'],
          'employerId': uid,
          'createdAt': now,
          'status': 'open',
          'source': 'demo_seed',
        });
        await db.collection('applications').add({
          'jobId': jobRef.id,
          'applicantId': demoStudentId,
          'status': 'accepted',
          'createdAt': now,
          'source': 'demo_seed',
        });
        await db.collection('ratings').add({
          'employeeId': demoStudentId,
          'employerId': uid,
          'jobId': jobRef.id,
          'punctuality': 4,
          'efficiency': 5,
          'communication': 4,
          'teamwork': 5,
          'attitude': 5,
          'average': 4.6,
          'comment': 'Great work',
          'createdAt': now,
        });
        await db.collection('transactions').add({
          'userId': uid,
          'amount': -80,
          'type': 'debit',
          'source': 'demo_seed',
          'description': 'Demo payment',
          'createdAt': now,
        });
        await db.collection('transactions').add({
          'userId': demoStudentId,
          'amount': 80,
          'type': 'credit',
          'source': 'demo_seed',
          'description': 'Demo payment',
          'createdAt': now,
        });
      } else {
        final jobRef = await db.collection('jobs').add({
          'title': 'Demo Cashier',
          'description': 'Retail cashier duties',
          'location': 'Kuala Lumpur',
          'pay': 18,
          'startDate': now,
          'endDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'skillsRequired': ['Customer Service'],
          'employerId': demoEmployerId,
          'createdAt': now,
          'status': 'completed',
        });
        await db.collection('applications').add({
          'jobId': jobRef.id,
          'applicantId': uid,
          'status': 'accepted',
          'createdAt': now,
        });
        await db.collection('employer_ratings').add({
          'employerId': demoEmployerId,
          'studentId': uid,
          'jobId': jobRef.id,
          'communication': 5,
          'fairness': 4,
          'promptPayment': 5,
          'overall': 5,
          'average': 4.75,
          'comment': 'Good employer',
          'createdAt': now,
        });
        await db.collection('transactions').add({
          'userId': uid,
          'amount': 50,
          'type': 'credit',
          'source': 'demo_seed',
          'description': 'Demo earning',
          'createdAt': now,
        });
        await db.collection('transactions').add({
          'userId': demoEmployerId,
          'amount': -50,
          'type': 'debit',
          'source': 'demo_seed',
          'description': 'Demo payment',
          'createdAt': now,
        });
      }
    } else {
      await db.collection('jobs').add({
        'title': 'Demo Waiter',
        'description': 'Serve customers',
        'location': 'Kuala Lumpur',
        'pay': 15,
        'startDate': now,
        'endDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'skillsRequired': ['Hospitality'],
        'employerId': demoEmployerId,
        'createdAt': now,
        'status': 'open',
        'source': 'demo_seed',
      });
    }
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo data seeded')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        title: const Text('Seed Demo Data', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1E3C)),
                onPressed: _loading ? null : _seed,
                child: Text(_loading ? 'Seeding...' : 'Seed Based On Role', style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _loading ? null : _seedAllFixtures,
                child: const Text('Seed All Fixtures'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _loading ? null : _seedEmployerFixtures,
                child: const Text('Seed Employer Fixtures'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _loading ? null : _seedStudentFixtures,
                child: const Text('Seed Student Fixtures'),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
                onPressed: _loading ? null : _cleanupDemo,
                child: const Text('Cleanup Demo Data', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedEmployerFixtures() async {
    setState(() => _loading = true);
    final db = FirebaseFirestore.instance;
    final now = DateTime.now().toIso8601String();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo-employer';
    final jobRef = await db.collection('jobs').add({
      'title': 'Employer Fixture Job',
      'description': 'Employer sample job',
      'location': 'Kuala Lumpur',
      'pay': 22,
      'startDate': now,
      'endDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'skillsRequired': ['Sample'],
      'employerId': uid,
      'createdAt': now,
      'status': 'open',
      'source': 'demo_seed',
    });
    await db.collection('applications').add({
      'jobId': jobRef.id,
      'applicantId': 'demo-student',
      'status': 'accepted',
      'createdAt': now,
    });
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employer fixtures seeded')));
  }

  Future<void> _seedStudentFixtures() async {
    setState(() => _loading = true);
    final db = FirebaseFirestore.instance;
    final now = DateTime.now().toIso8601String();
    const employerId = 'demo-employer';
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo-student';
    final jobRef = await db.collection('jobs').add({
      'title': 'Student Fixture Job',
      'description': 'Completed job for rating',
      'location': 'Kuala Lumpur',
      'pay': 19,
      'startDate': now,
      'endDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'skillsRequired': ['Sample'],
      'employerId': employerId,
      'createdAt': now,
      'status': 'completed',
      'source': 'demo_seed',
    });
    await db.collection('applications').add({
      'jobId': jobRef.id,
      'applicantId': uid,
      'status': 'accepted',
      'createdAt': now,
    });
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student fixtures seeded')));
  }

  Future<void> _seedAllFixtures() async {
    await _seedEmployerFixtures();
    await _seedStudentFixtures();
  }

  Future<void> _cleanupDemo() async {
    setState(() => _loading = true);
    final db = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final jobs = await db.collection('jobs').where('employerId', isEqualTo: uid).where('source', isEqualTo: 'demo_seed').get();
      for (final d in jobs.docs) {
        await db.collection('jobs').doc(d.id).delete();
      }
      final appsMine = await db.collection('applications').where('applicantId', isEqualTo: uid).get();
      for (final d in appsMine.docs) {
        await db.collection('applications').doc(d.id).delete();
      }
      final txMine = await db.collection('transactions').where('userId', isEqualTo: uid).where('source', isEqualTo: 'demo_seed').get();
      for (final d in txMine.docs) {
        await db.collection('transactions').doc(d.id).delete();
      }
      final ratingsEmp = await db.collection('ratings').where('employerId', isEqualTo: uid).get();
      for (final d in ratingsEmp.docs) {
        await db.collection('ratings').doc(d.id).delete();
      }
      final ratingsStu = await db.collection('ratings').where('employeeId', isEqualTo: uid).get();
      for (final d in ratingsStu.docs) {
        await db.collection('ratings').doc(d.id).delete();
      }
      final eratingsMine = await db.collection('employer_ratings').where('studentId', isEqualTo: uid).get();
      for (final d in eratingsMine.docs) {
        await db.collection('employer_ratings').doc(d.id).delete();
      }
    }
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleanup done for your demo data')));
  }
}
