import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarningsHistoryPage extends StatefulWidget {
  const EarningsHistoryPage({super.key});

  @override
  State<EarningsHistoryPage> createState() => _EarningsHistoryPageState();
}

class _EarningsHistoryPageState extends State<EarningsHistoryPage> {
  final _service = FirestoreService();
  final Map<String, String> _userNamesCache = {};

  Future<String> _getUserName(String? uid) async {
    if (uid == null || uid.isEmpty) return 'Unknown';
    if (_userNamesCache.containsKey(uid)) return _userNamesCache[uid]!;
    
    try {
      final profile = await _service.getUserProfile(uid);
      final name = profile?.displayName ?? 'User';
      _userNamesCache[uid] = name;
      return name;
    } catch (e) {
      return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            backgroundColor: const Color(0xFF0F1E3C),
            elevation: 0,
            pinned: true,
            expandedHeight: 120,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Earnings History',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F1E3C), Color(0xFF1A3A5C)],
                  ),
                ),
              ),
            ),
          ),
          
          // Transaction List
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.streamTransactionsForUser(
              FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              final items = snapshot.data ?? [];
              
              if (items.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your earnings history will appear here',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return _buildTransactionCardAsync(item);
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCardAsync(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? '';
    final counterparty = item['counterparty']?.toString();
    
    // For credit/debit, fetch counterparty name
    if ((type == 'credit' || type == 'debit') && counterparty != null) {
      return FutureBuilder<String>(
        future: _getUserName(counterparty),
        builder: (context, snapshot) {
          final name = snapshot.data ?? 'Loading...';
          return _buildTransactionCard(item, name);
        },
      );
    }
    
    return _buildTransactionCard(item, null);
  }

  Widget _buildTransactionCard(Map<String, dynamic> item, String? counterpartyName) {
    final amountNum = (item['amount'] as num?)?.toDouble() ?? 0;
    final type = item['type']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';
    
    int toMillis(dynamic v) {
      if (v is String) return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
      if (v is DateTime) return v.millisecondsSinceEpoch;
      return 0;
    }
    
    final ms = toMillis(item['createdAt']);
    final isPositive = amountNum >= 0;
    
    // Determine icon and colors based on transaction type
    IconData icon;
    Color iconBgColor;
    Color iconColor;
    String title;
    String subtitle;
    String? detailLine;
    
    switch (type) {
      case 'withdrawal':
        icon = Icons.account_balance_outlined;
        iconBgColor = Colors.blue.shade50;
        iconColor = Colors.blue.shade600;
        title = 'Withdrawal';
        // Parse bank info from description
        final bankInfo = _parseWithdrawalDescription(description);
        subtitle = 'To ${bankInfo['bank'] ?? 'Bank Account'}';
        detailLine = 'Account: ${bankInfo['account'] ?? '-'}';
        break;
      case 'debit':
        icon = Icons.arrow_upward_rounded;
        iconBgColor = Colors.orange.shade50;
        iconColor = Colors.orange.shade600;
        title = 'Transfer Sent';
        subtitle = 'To ${counterpartyName ?? 'User'}';
        detailLine = description.isNotEmpty ? description : null;
        break;
      case 'credit':
        icon = Icons.arrow_downward_rounded;
        iconBgColor = Colors.green.shade50;
        iconColor = Colors.green.shade600;
        title = 'Transfer Received';
        subtitle = 'From ${counterpartyName ?? 'Employer'}';
        detailLine = description.isNotEmpty ? description : null;
        break;
      case 'topup':
        icon = Icons.add_circle_outline;
        iconBgColor = Colors.blue.shade50;
        iconColor = Colors.blue.shade600;
        title = 'Top Up';
        subtitle = 'Wallet Top Up';
        detailLine = description.isNotEmpty ? description : null;
        break;
      default:
        icon = Icons.swap_horiz;
        iconBgColor = Colors.grey.shade100;
        iconColor = Colors.grey.shade600;
        title = 'Transaction';
        subtitle = description.isNotEmpty ? description : 'No description';
        detailLine = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showTransactionDetails(item, title, subtitle, detailLine, counterpartyName),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    // Transaction Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: iconColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    
                    // Transaction Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF0F1E3C),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                type == 'credit' ? Icons.person_outline : 
                                type == 'debit' ? Icons.person_outline :
                                type == 'withdrawal' ? Icons.account_balance : 
                                Icons.info_outline,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (detailLine != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              detailLine,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Amount
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPositive 
                            ? Colors.green.shade50 
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPositive 
                              ? Colors.green.shade100 
                              : Colors.red.shade100,
                        ),
                      ),
                      child: Text(
                        '${isPositive ? '+' : '-'}RM ${amountNum.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isPositive 
                              ? Colors.green.shade700 
                              : Colors.red.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Date/Time Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(item['createdAt'], ms),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, String?> _parseWithdrawalDescription(String description) {
    // Description format: "Bank: MAYBANK, Account: 1234556733452"
    String? bank;
    String? account;
    
    final bankMatch = RegExp(r'Bank:\s*([^,]+)').firstMatch(description);
    if (bankMatch != null) {
      bank = bankMatch.group(1)?.trim();
    }
    
    final accountMatch = RegExp(r'Account:\s*(\S+)').firstMatch(description);
    if (accountMatch != null) {
      account = accountMatch.group(1)?.trim();
    }
    
    return {'bank': bank, 'account': account};
  }

  void _showTransactionDetails(
    Map<String, dynamic> item, 
    String title, 
    String subtitle, 
    String? detailLine,
    String? counterpartyName,
  ) {
    final amountNum = (item['amount'] as num?)?.toDouble() ?? 0;
    final type = item['type']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';
    final isPositive = amountNum >= 0;
    
    int toMillis(dynamic v) {
      if (v is String) return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
      if (v is DateTime) return v.millisecondsSinceEpoch;
      return 0;
    }
    final ms = toMillis(item['createdAt']);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Amount
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${isPositive ? '+' : '-'}RM ${amountNum.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F1E3C),
              ),
            ),
            const SizedBox(height: 24),
            
            // Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.access_time,
                    label: 'Date & Time',
                    value: _formatDate(item['createdAt'], ms),
                  ),
                  if (type == 'credit' && counterpartyName != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      icon: Icons.person_outline,
                      label: 'From',
                      value: counterpartyName,
                    ),
                  ],
                  if (type == 'debit' && counterpartyName != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      icon: Icons.person_outline,
                      label: 'To',
                      value: counterpartyName,
                    ),
                  ],
                  if (type == 'withdrawal') ...[
                    const Divider(height: 24),
                    () {
                      final bankInfo = _parseWithdrawalDescription(description);
                      return Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.account_balance,
                            label: 'Bank',
                            value: bankInfo['bank'] ?? '-',
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.credit_card,
                            label: 'Account',
                            value: bankInfo['account'] ?? '-',
                          ),
                        ],
                      );
                    }(),
                  ],
                  if (description.isNotEmpty && type != 'withdrawal') ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      icon: Icons.description_outlined,
                      label: 'Description',
                      value: description,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F1E3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F1E3C),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic original, int ms) {
    if (ms > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      final now = DateTime.now();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final isYesterday = dt.year == now.year && 
                          dt.month == now.month && 
                          dt.day == now.day - 1;
      
      final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      
      if (isToday) {
        return 'Today, $time';
      } else if (isYesterday) {
        return 'Yesterday, $time';
      } else {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $time';
      }
    }
    return original?.toString() ?? '';
  }
}
