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
  const EmployerTransferPage({super.key, this.employeeEmail, this.employeeName, this.employeeId});

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
    if (widget.employeeEmail != null) _employeeEmailController.text = widget.employeeEmail!;
    if (widget.employeeName != null) _employeeNameController.text = widget.employeeName!;
    if (widget.employeeId != null) _employeeIDController.text = widget.employeeId!;
  }

  // ========================================================================
  // SUBMIT TRANSFER FUNCTION - Runs when user clicks the Submit button
  // ========================================================================
  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    final toIdRaw = _employeeEmailController.text.isNotEmpty ? _employeeEmailController.text : _employeeIDController.text;
    if (toIdRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide employee email or ID')));
      return;
    }
    final amount = double.tryParse(_transferAmountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount must be greater than 0')));
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bal = uid.isEmpty ? 0 : await FirestoreService().getBalance(uid);
    if (!mounted) return;
    if (amount > bal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance for this transfer')));
      return;
    }
    await FirestoreService().recordTransfer(
      toIdentifier: toIdRaw,
      amount: amount,
      description: _descriptionController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer submitted success')));
    Navigator.pop(context);
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // Column = Stack everything vertically (top to bottom)
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // ============================================================
              // ACCOUNT BALANCE CARD - Shows employer's available balance
              // ============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20), // Space inside the box
                // The styling of the box
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2F5C), // Darker blue color
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                  border: Border.all(
                    color: const Color(0xFF1A2F5C), // Border color
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4), // Shadow with 40% opacity
                      spreadRadius: 0,
                      blurRadius: 16,
                      offset: const Offset(0, 8), // Slightly lower offset
                    ),
                  ],
                ),
                child: Column(
                  // Stack items vertically inside the box
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label text
                    const Text(
                      'Account Balance',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8), // Add 8 pixels of space
                    
                    FutureBuilder<double>(
                      future: FirestoreService().getBalance(FirebaseAuth.instance.currentUser?.uid ?? ''),
                      builder: (context, snapshot) {
                        final bal = snapshot.data ?? accountBalance;
                        return Text(
                          'RM ${bal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ],
                ),
          ),
          const SizedBox(height: 24), // Add space after the card
          
          // ============================================================
          // FORM - Container for all the input fields
          // ============================================================
          Form(
            // key = Use this to validate the entire form
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _employeeEmailController,
                        decoration: _buildInputDecoration(hintText: 'Employee email (preferred)'),
                        style: _inputTextStyle,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if ((value?.isEmpty ?? true) && (_employeeIDController.text.isEmpty)) {
                            return 'Enter email or ID';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final email = _employeeEmailController.text.trim();
                        if (email.isEmpty) return;
                        final profile = await FirestoreService().getUserByEmail(email);
                        if (!mounted) return;
                        final found = profile != null;
                        if (found) {
                          setState(() {
                            _employeeNameController.text = profile.displayName;
                            _employeeIDController.text = profile.id;
                          });
                        }
                        messenger.showSnackBar(
                          SnackBar(content: Text(found ? 'Employee found' : 'No user with that email')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1E3C)),
                      child: const Text('Find', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                    
                    // ========================================================
                    // FIELD 1 - Employee Name
                    // ========================================================
                    _buildLabel('Employee Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      // TextFormField = Input field for text
                      controller: _employeeNameController,
                      // controller connects this field to _employeeNameController
                      // So whatever user types gets stored in _employeeNameController
                      decoration: _buildInputDecoration(hintText: 'Enter employee full name'),
                      // Use the styling from _buildInputDecoration() method
                      style: _inputTextStyle,
                      
                      // VALIDATOR - Check if this field is valid
                      validator: (value) {
                        // value = what the user typed
                        if (value?.isEmpty ?? true) {
                          // If the field is empty, show error message
                          return 'Please enter employee name';
                        }
                        // If not empty, return null (no error)
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ========================================================
                    // FIELD 2 - Employee Email
                    // ========================================================
                    _buildLabel('Employee Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _employeeNameController,
                      decoration: _buildInputDecoration(hintText: 'Enter employee full name'),
                      style: _inputTextStyle,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter employee name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ========================================================
                    // FIELD 3 - Employee ID
                    // ========================================================
                    _buildLabel('Employee ID (uid)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _employeeIDController,
                      decoration: _buildInputDecoration(hintText: 'Enter employee ID'),
                      style: _inputTextStyle,
                      validator: (value) {
                        if ((value?.isEmpty ?? true) && (_employeeEmailController.text.isEmpty)) {
                          return 'Please enter employee ID or email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ========================================================
                    // FIELD 4 - Employee Account Number
                    // ========================================================
                    _buildLabel('Account Number'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _employeeAccountController,
                      decoration: _buildInputDecoration(hintText: 'Enter account number'),
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

                    // ========================================================
                    // FIELD 5 - Bank Name
                    // ========================================================
                    _buildLabel('Bank Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _employeeBankController,
                      decoration: _buildInputDecoration(hintText: 'Enter bank name'),
                      style: _inputTextStyle,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter bank name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ========================================================
                    // FIELD 4 - Transfer Amount
                    // ========================================================
                    const Text(
                      'Transfer Amount',
                      style: TextStyle(
                        color: Color.fromARGB(255, 21, 36, 69),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _transferAmountController,
                      decoration: _buildInputDecoration(hintText: '0.00').copyWith(
                        // use prefixIcon so the RM label remains visible at all times
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 20.0, right: 8.0),
                          child: Text('RM', style: _inputTextStyle),
                        ),
                        // reduce default left padding introduced by prefixIcon
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      ),
                      style: _inputTextStyle,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter transfer amount';
                        }
                        // Try to convert to number
                        double? amount = double.tryParse(value!);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount (greater than 0)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ========================================================
                    // FIELD 5 - Transfer Description/Reason
                    // ========================================================
                    _buildLabel('Transfer Description'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _buildInputDecoration(hintText: 'e.g., Salary, Bonus, Reimbursement'),
                      style: _inputTextStyle,
                      maxLines: 3, // Allow multiple lines for description
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter transfer description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ========================================================
                    // DISCLAIMER SECTION
                    // ========================================================
                    _buildDisclaimerSection(),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ============================================================
              // SUBMIT BUTTON
              // ============================================================
              SizedBox(
                // SizedBox = A box with a specific size
                width: double.infinity, // Take full width
                height: 50, // Height of 50 pixels
                child: ElevatedButton(
                  // ElevatedButton = A button with elevation (3D effect)
                  onPressed: _submitTransfer,
                  // When clicked, run the _submitTransfer function
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 39, 39, 215), // Purple color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit Transfer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // HELPER METHOD 1 - Build a label (like "Employee Name")
  // This method is reused multiple times to avoid repeating code
  // ========================================================================
  Widget _buildLabel(String label) {
    // label = the text to display (passed in as parameter)
    return Text(
      label,
      style: const TextStyle(
        color: Color.fromARGB(255, 53, 53, 53),
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  // ========================================================================
  // HELPER METHOD 2 - Build the styling for all input fields
  // This makes all text fields look the same
  // ========================================================================
  InputDecoration _buildInputDecoration({String? hintText}) {
    return InputDecoration(
      filled: true, // Fill the field with a background color
      // Slight light fill so fields read as inputs but not fully white
      fillColor: const Color.fromARGB(255, 141, 143, 145).withValues(alpha: 0.18),
      
      // Hint text that appears when field is empty
      hintText: hintText,
      
      // Border when the field is enabled (ready to type)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.92),
          width: 1.4,
        ),
      ),
      
      // Border when the field is focused (user is typing)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: const Color.fromARGB(255, 107, 106, 106).withValues(alpha: 0.6),
          width: 2.4,
        ),
      ),
      
      // Border when there's an error
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.8,
        ),
      ),
      
      // Space inside the field (padding)
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      
      // Style for placeholder text (darker for better readability)
      hintStyle: const TextStyle(color: Color.fromARGB(255, 105, 104, 104)),
    );
  }

  // ========================================================================
  // HELPER METHOD 3 - Build the disclaimer section
  // This shows all the disclaimer text with bullet points
  // ========================================================================
  Widget _buildDisclaimerSection() {
    return Column(
      // Stack items vertically
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Disclaimer title
        const Text(
          'Important Notice:',
          style: TextStyle(
            color: Color.fromARGB(255, 21, 36, 69),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Notice point 1
        _buildDisclaimerPoint(
          'Ensure the employee details are correct before submitting.',
        ),
        const SizedBox(height: 3),
        
        // Notice point 2
        _buildDisclaimerPoint(
          'Transfers are processed immediately and cannot be reversed.',
        ),
        const SizedBox(height: 3),
        
        // Notice point 3
        _buildDisclaimerPoint(
          'Employee will receive email and in-app notification of the transfer.',
        ),
      ],
    );
  }

  // ========================================================================
  // HELPER METHOD 4 - Build each disclaimer point with a bullet
  // ========================================================================
  Widget _buildDisclaimerPoint(String text) {
    // text = the notice text (passed in as parameter)
    return Row(
      // Row = Arrange items horizontally (left to right)
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The bullet point (a small circle)
        const Padding(
          padding: EdgeInsets.only(right: 12, top: 4),
          child: Icon(
            Icons.circle,
            size: 6, // Very small circle
            color: Color.fromARGB(255, 21, 36, 69),
          ),
        ),
        // The notice text
        Expanded(
          // Expanded = Take up remaining space
          child: Text(
            text,
            style: const TextStyle(
              color: Color.fromARGB(255, 21, 36, 69),
              fontSize: 14,
              height: 1.5, // Line height for better readability
            ),
          ),
        ),
      ],
    );
  }
}
