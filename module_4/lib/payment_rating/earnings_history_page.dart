import 'package:flutter/material.dart';

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
  
  // ========================================================================
  // TRANSACTION DATA - List of all transactions
  // Each transaction is a Map with: type, title, description, amount, date, color
  // ========================================================================
  final List<Map<String, dynamic>> transactions = [
    {
      'type': 'withdrawal_approved',
      'title': 'Withdrawal Approved',
      'description': 'Your Withdrawal Request has been approved.',
      'amount': '-RM 428.47',
      'amountNum': -428.47,
      'date': '14 Oct 2024 11:24:20',
      'color': Colors.green,
    },
    {
      'type': 'withdrawal_requested',
      'title': 'Withdrawal Requested',
      'description': 'Your Withdrawal Request has been received and is currently pending approval.',
      'amount': '-RM 428.47',
      'amountNum': -428.47,
      'date': '10 Oct 2024 16:33:39',
      'color': Colors.blue,
    },
    {
      'type': 'credited',
      'title': 'Credited To Total Earnings',
      'description': 'Thank you for being a Trooper! Your Earnings',
      'amount': '+RM 80.00',
      'amountNum': 80.00,
      'date': '09 Oct 2024 15:20:15',
      'color': Colors.green,
    },
  ];

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
            child: ListView.builder(
              // itemCount = How many items to show in the list
              itemCount: transactions.length,
              padding: const EdgeInsets.all(12),
              // itemBuilder = Builds each item in the list
              itemBuilder: (context, index) {
                // Get the current transaction
                final item = transactions[index];
                
                return _buildTransactionCard(item);
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
            transaction['date'],
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
}