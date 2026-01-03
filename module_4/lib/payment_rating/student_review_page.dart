import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class StudentReviewPage extends StatefulWidget {
  final String employerId;
  final String jobId;
  const StudentReviewPage({super.key, required this.employerId, required this.jobId});

  @override
  State<StudentReviewPage> createState() => _StudentReviewPageState();
}

class _StudentReviewPageState extends State<StudentReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double communication = 0;
  double fairness = 0;
  double promptPayment = 0;
  double overall = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (communication == 0 || fairness == 0 || promptPayment == 0 || overall == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please rate all categories')));
        return;
      }
      FirestoreService()
          .submitStudentReview(
            employerId: widget.employerId,
            jobId: widget.jobId,
            communication: communication,
            fairness: fairness,
            promptPayment: promptPayment,
            overall: overall,
            comment: _commentController.text,
          )
          .then((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted')));
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        title: const Text('Rate Employer', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _scale('Communication', 'Responsiveness and clarity', (v) => setState(() => communication = v), communication),
                const SizedBox(height: 16),
                _scale('Fairness', 'Fair treatment and expectations', (v) => setState(() => fairness = v), fairness),
                const SizedBox(height: 16),
                _scale('Prompt Payment', 'Pays on time after completion', (v) => setState(() => promptPayment = v), promptPayment),
                const SizedBox(height: 16),
                _scale('Overall', 'Overall satisfaction', (v) => setState(() => overall = v), overall),
                const SizedBox(height: 20),
                const Text('Comments'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Optional feedback',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1E3C)),
                    onPressed: _submit,
                    child: const Text('Submit', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scale(String title, String desc, void Function(double) onChanged, double current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 1; i <= 5; i++)
              GestureDetector(
                onTap: () => onChanged(i.toDouble()),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(i <= current ? Icons.star : Icons.star_border, color: Colors.amber, size: 28),
                ),
              ),
            const SizedBox(width: 12),
            Text(current > 0 ? current.toStringAsFixed(1) : 'Not rated', style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ],
    );
  }
}
