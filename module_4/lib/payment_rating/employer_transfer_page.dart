import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ============================================================================
// THIS IS THE PAGE WIDGET - It tells Flutter this is a page that will change
// ============================================================================
class EmployerTransferPage extends StatefulWidget {
  final String? employeeEmail;
  final String? employeeName;
  final String? employeeId;
  final double? transferAmount;
  final String? applicationId; // For updating application status after payment
  final String? jobId;
  const EmployerTransferPage({
    super.key,
    this.employeeEmail,
    this.employeeName,
    this.employeeId,
    this.transferAmount,
    this.applicationId,
    this.jobId,
  });

  @override
  State<EmployerTransferPage> createState() => _EmployerTransferPageState();
}

// ============================================================================
// THIS IS THE PAGE STATE - Where all the code and UI happens
// ============================================================================
class _EmployerTransferPageState extends State<EmployerTransferPage> {
  // ========================================================================
  // FORM KEY - This is like a remote control for the entire form
  // We use it to validate all fields when user clicks submit
  // ========================================================================
  final _formKey = GlobalKey<FormState>();

  // ========================================================================
  // TEXT CONTROLLERS - These catch and store whatever the user types
  // Think of them like mailboxes that hold the user's input
  // ========================================================================
  final _employeeNameController = TextEditingController();
  // Stores the employee name the user types

  final _employeeEmailController = TextEditingController();
  // Stores the employee email the user types

  final _employeeIDController = TextEditingController();
  // Stores the employee ID the user types

  final _employeeAccountController = TextEditingController();
  // Stores the employee account number the user types

  final _employeeBankController = TextEditingController();
  // Stores the employee bank name the user types

  final _transferAmountController = TextEditingController(text: '0.00');
  // Stores the transfer amount the user types

  final _descriptionController = TextEditingController();
  // Stores the transfer description/reason

  // Shared input text style so all fields match
  final TextStyle _inputTextStyle = const TextStyle(
    color: Color.fromARGB(255, 12, 12, 12),
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  // ========================================================================
  // VARIABLE - Account balance available to transfer
  // double = number with decimals (like 5000.50)
  // ========================================================================
  double accountBalance = 5000.00;

  // ========================================================================
  // DISPOSE METHOD - Clean up when page closes to prevent memory leaks
  // Think of it like turning off the lights before leaving a room
  // ========================================================================
  @override
  void dispose() {
    // Tell each controller to stop listening and free up memory
    _employeeNameController.dispose();
    _employeeEmailController.dispose();
    _employeeIDController.dispose();
    _employeeAccountController.dispose();
    _employeeBankController.dispose();
    _transferAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.employeeEmail != null) {
      _employeeEmailController.text = widget.employeeEmail!;
    }
    if (widget.employeeName != null) {
      _employeeNameController.text = widget.employeeName!;
    }
    if (widget.employeeId != null) {
      _employeeIDController.text = widget.employeeId!;
      // Auto-fetch bank details when employee ID is provided
      _fetchEmployeeDetails();
    }
    if (widget.transferAmount != null) {
      _transferAmountController.text = widget.transferAmount!.toStringAsFixed(
        2,
      );
    }
    if (widget.jobId != null) {
      _descriptionController.text = 'Job completion payment';
    }
  }

  Future<void> _fetchEmployeeDetails() async {
    if (widget.employeeId == null) return;
    final profile = await FirestoreService().getUserProfile(widget.employeeId!);
    if (!mounted || profile == null) return;
    setState(() {
      if (_employeeNameController.text.isEmpty) {
        _employeeNameController.text = profile.displayName;
      }
      if (_employeeEmailController.text.isEmpty) {
        _employeeEmailController.text = profile.email;
      }
      _employeeAccountController.text = profile.bankAccountNumber;
      _employeeBankController.text = profile.bankName;
    });
  }

  // ========================================================================
  // SUBMIT TRANSFER FUNCTION - Runs when user clicks the Submit button
  // ========================================================================
  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    final toIdRaw = _employeeEmailController.text.isNotEmpty
        ? _employeeEmailController.text
        : _employeeIDController.text;
    if (toIdRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide employee email or ID')),
      );
      return;
    }
    final amount = double.tryParse(_transferAmountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than 0')),
      );
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bal = uid.isEmpty ? 0 : await FirestoreService().getBalance(uid);
    if (!mounted) return;
    if (amount > bal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance for this transfer')),
      );
      return;
    }
    await FirestoreService().recordTransfer(
      toIdentifier: toIdRaw,
      amount: amount,
      description: _descriptionController.text,
    );

    // Update application status to 'paid' if this is a job payment
    if (widget.applicationId != null) {
      await FirestoreService().updateApplicationStatus(
        widget.applicationId!,
        'paid',
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('RM ${amount.toStringAsFixed(2)} paid successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.pop(context, true); // Return true to indicate successful payment
  }

  // ========================================================================
  // BUILD METHOD - This builds and displays the entire page UI
  // This runs every time the page needs to redraw
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
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0, // No shadow under the app bar
        // LEFT SIDE - Back arrow button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          // When clicked, go back to the previous page
          onPressed: () => Navigator.pop(context),
        ),

        // MIDDLE - Title text
        title: const Text(
          'Transfer to Employee',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        // RIGHT SIDE - Info button
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            // When clicked, show a popup dialog with info
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Transfer Info'),
                  content: const Text(
                    'Transfers are processed immediately. Employee will receive notification. Make sure all information is correct before submitting.',
                  ),
                  actions: [
                    // OK button to close the dialog
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      // ===================================================================
      // BODY - Main content area of the page
      // ===================================================================
      body: SingleChildScrollView(
        // SingleChildScrollView = Makes the page scrollable if content is too long
        child: Padding(
          // Padding = Add space around everything (16 pixels)
          padding: const EdgeInsets.all(20.0),
          child: Column(
            // Column = Stack everything vertically (top to bottom)
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================================
              // ACCOUNT BALANCE CARD - Shows employer's available balance
              // ============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F1E3C), Color(0xFF1A3A5C)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F1E3C).withValues(alpha: 0.4),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: const Color(0xFF0F1E3C).withValues(alpha: 0.2),
                      spreadRadius: 0,
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Account Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<double>(
                      future: FirestoreService().getBalance(
                        FirebaseAuth.instance.currentUser?.uid ?? '',
                      ),
                      builder: (context, snapshot) {
                        final bal = snapshot.data ?? accountBalance;
                        return Text(
                          'RM ${bal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ============================================================
              // SEARCH EMPLOYEE CARD
              // ============================================================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0F1E3C,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.search,
                            color: Color(0xFF0F1E3C),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Find Employee',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F1E3C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _employeeEmailController,
                                  decoration: _buildModernInputDecoration(
                                    hintText: 'Enter employee email',
                                    prefixIcon: Icons.email_outlined,
                                  ),
                                  style: _inputTextStyle,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if ((value?.isEmpty ?? true) &&
                                        (_employeeIDController.text.isEmpty)) {
                                      return 'Enter email or ID';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF0F1E3C),
                                      Color(0xFF1A3A5C),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF0F1E3C,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final email = _employeeEmailController
                                          .text
                                          .trim();
                                      if (email.isEmpty) return;
                                      final profile = await FirestoreService()
                                          .getUserByEmail(email);
                                      if (!mounted) return;
                                      final found = profile != null;
                                      if (found) {
                                        setState(() {
                                          _employeeNameController.text =
                                              profile.displayName;
                                          _employeeIDController.text =
                                              profile.id;
                                          _employeeAccountController.text =
                                              profile.bankAccountNumber;
                                          _employeeBankController.text =
                                              profile.bankName;
                                        });
                                      }
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            found
                                                ? 'Employee found!'
                                                : 'No user with that email',
                                          ),
                                          backgroundColor: found
                                              ? Colors.green
                                              : Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      child: Text(
                                        'Find',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ============================================================
              // EMPLOYEE DETAILS CARD
              // ============================================================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Employee Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F1E3C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Employee Name
                    _buildModernLabel('Employee Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _employeeNameController,
                      decoration: _buildModernInputDecoration(
                        hintText: 'Enter employee full name',
                        prefixIcon: Icons.badge_outlined,
                      ),
                      style: _inputTextStyle,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter employee name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Employee ID
                    _buildModernLabel('Employee ID'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _employeeIDController,
                      decoration: _buildModernInputDecoration(
                        hintText: 'Enter employee ID',
                        prefixIcon: Icons.fingerprint,
                      ),
                      style: _inputTextStyle,
                      validator: (value) {
                        if ((value?.isEmpty ?? true) &&
                            (_employeeEmailController.text.isEmpty)) {
                          return 'Please enter employee ID or email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ============================================================
              // BANK DETAILS CARD
              // ============================================================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_outlined,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Bank Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F1E3C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Account Number
                    _buildModernLabel('Account Number'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _employeeAccountController,
                      decoration: _buildModernInputDecoration(
                        hintText: 'Enter account number',
                        prefixIcon: Icons.credit_card_outlined,
                      ),
                      style: _inputTextStyle,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter account number';
                        }
                        if (value != null && value.length < 6) {
                          return 'Account number seems too short';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bank Name
                    _buildModernLabel('Bank Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _employeeBankController,
                      decoration: _buildModernInputDecoration(
                        hintText: 'Enter bank name',
                        prefixIcon: Icons.business_outlined,
                      ),
                      style: _inputTextStyle,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter bank name';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ============================================================
              // TRANSFER AMOUNT CARD
              // ============================================================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: Colors.purple,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Transfer Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F1E3C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextFormField(
                        controller: _transferAmountController,
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            padding: const EdgeInsets.only(left: 20, right: 8),
                            child: Text(
                              'RM',
                              style: TextStyle(
                                color: const Color(
                                  0xFF0F1E3C,
                                ).withValues(alpha: 0.6),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF0F1E3C),
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.left,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter transfer amount';
                          }
                          double? amount = double.tryParse(value!);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildModernLabel('Transfer Description'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _buildModernInputDecoration(
                        hintText: 'e.g., Salary, Bonus, Reimbursement',
                        prefixIcon: Icons.description_outlined,
                      ),
                      style: _inputTextStyle,
                      maxLines: 2,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter transfer description';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ============================================================
              // DISCLAIMER CARD
              // ============================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Important Notice',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildModernDisclaimerPoint(
                      'Verify employee details before submitting',
                    ),
                    _buildModernDisclaimerPoint(
                      'Transfers are instant and non-reversible',
                    ),
                    _buildModernDisclaimerPoint(
                      'Employee will be notified immediately',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ============================================================
              // SUBMIT BUTTON
              // ============================================================
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _submitTransfer,
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Submit Transfer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // HELPER METHOD - Build modern label
  // ========================================================================
  Widget _buildModernLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  // ========================================================================
  // HELPER METHOD - Build modern input decoration
  // ========================================================================
  InputDecoration _buildModernInputDecoration({
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F9FC),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(prefixIcon, color: Colors.grey.shade500, size: 22),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F1E3C), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // ========================================================================
  // HELPER METHOD - Build modern disclaimer point
  // ========================================================================
  Widget _buildModernDisclaimerPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.amber.shade900,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
