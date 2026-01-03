import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ============================================================================
// THIS IS THE PAGE WIDGET - It tells Flutter this is a page that will change
// ============================================================================
class EarningsHistoryPage extends StatefulWidget {
  const EarningsHistoryPage({super.key});

  @override
  State<EarningsHistoryPage> createState() => _EarningsHistoryPageState();
}

// ============================================================================
// THIS IS THE PAGE STATE - Where all the code and UI happens
// ============================================================================
class _EarningsHistoryPageState extends State<EarningsHistoryPage> {
  final _service = FirestoreService();

  // ========================================================================
  // BUILD METHOD - This builds and displays the entire page UI
  // ========================================================================
  @override
  Widget build(BuildContext context) {
    // =====================================================================
    // SCAFFOLD - Basic structure of the Android screen
    // =====================================================================
    return Scaffold(
      // Set the background color to light gray/white
      backgroundColor: const Color.fromARGB(255, 250, 250, 251),
      
      // ===================================================================
      // APP BAR - The top header of the page
      // ===================================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        
        // LEFT SIDE - Back arrow button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 21, 36, 69)),
          // When clicked, go back to the previous page
          onPressed: () => Navigator.pop(context),
        ),
        
        // MIDDLE - Title text
        title: const Text(
          'Earnings History',
          style: TextStyle(
            color: Color.fromARGB(255, 21, 36, 69),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        
      ),
      
      // ===================================================================
      // BODY - Main content area
      // ===================================================================
      body: Column(
        children: [
          
          // ============================================================
          // TRANSACTION LIST - Shows list of transactions
          // ============================================================
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.streamTransactionsForUser(FirebaseAuth.instance.currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('No transactions yet'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final amountNum = (item['amount'] as num?)?.toDouble() ?? 0;
                    final title = _titleFor(item['type']?.toString() ?? '');
                    int toMillis(dynamic v) {
                      if (v is String) return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
                      if (v is DateTime) return v.millisecondsSinceEpoch;
                      return 0;
                    }
                    final tx = {
                      'type': item['type'],
                      'title': title,
                      'description': item['description'] ?? '',
                      'amount': (amountNum >= 0 ? '+RM ' : '-RM ') + amountNum.abs().toStringAsFixed(2),
                      'amountNum': amountNum,
                      'date': item['createdAt'] ?? '',
                      'ms': toMillis(item['createdAt']),
                      'color': amountNum >= 0 ? Colors.green : Colors.red,
                    };
                    return _buildTransactionCard(tx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // HELPER METHOD - Build each transaction card
  // ========================================================================
  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    return Container(
      // Card styling
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================================
          // ROW 1 - Title and Amount
          // ============================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title with colored text
              Expanded(
                child: Text(
                  transaction['title'],
                  style: TextStyle(
                    color: transaction['color'],
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Amount with sign (+ or -)
              Text(
                transaction['amount'],
                style: TextStyle(
                  color: transaction['amountNum'] < 0 ? Colors.red : Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // ============================================================
          // ROW 2 - Description
          // ============================================================
          Text(
            transaction['description'],
            style: const TextStyle(
              color: Color.fromARGB(255, 53, 53, 53),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          
          // ============================================================
          // ROW 3 - Date and Time
          // ============================================================
          Text(
            _formatDate(transaction['date'], transaction['ms']),
            style: const TextStyle(
              color: Color.fromARGB(255, 128, 128, 128),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(String type) {
    switch (type) {
      case 'withdrawal':
        return 'Withdrawal';
      case 'debit':
        return 'Transfer Sent';
      case 'credit':
        return 'Transfer Received';
      case 'topup':
        return 'Top Up';
      default:
        return 'Transaction';
    }
  }

  String _formatDate(dynamic original, int ms) {
    if (ms > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$date $time';
    }
    return original?.toString() ?? '';
  }
}
