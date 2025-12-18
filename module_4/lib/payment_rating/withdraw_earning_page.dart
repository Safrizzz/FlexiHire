import 'package:flutter/material.dart';

// ============================================================================
// THIS IS THE PAGE WIDGET - It tells Flutter this is a page that will change
// ============================================================================
class WithdrawEarningPage extends StatefulWidget {
  const WithdrawEarningPage({super.key});

  @override
  State<WithdrawEarningPage> createState() => _WithdrawEarningsPageState();
}

// ============================================================================
// THIS IS THE PAGE STATE - Where all the code and UI happens
// ============================================================================
class _WithdrawEarningsPageState extends State<WithdrawEarningPage> {
  
  // ========================================================================
  // FORM KEY - This is like a remote control for the entire form
  // We use it to validate all fields when user clicks submit
  // ========================================================================
  final _formKey = GlobalKey<FormState>();
  
  // ========================================================================
  // TEXT CONTROLLERS - These catch and store whatever the user types
  // Think of them like mailboxes that hold the user's input
  // ========================================================================
  final _nameController = TextEditingController(text: 'Eyman Safriz Safiruzialman');
  // Stores the name the user types (starts with 'Eyman...')
  
  final _bankController = TextEditingController(text: 'Maybank - Malayan Banking Berhad');
  // Stores the bank name the user types
  
  final _accountController = TextEditingController(text: '16424924393');
  // Stores the account number the user types
  
  final _withdrawalController = TextEditingController(text: '0.00');
  // Shared input text style so all fields match the RM prefix
  final TextStyle _inputTextStyle = const TextStyle(
    color: Color.fromARGB(255, 12, 12, 12),
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  // Stores the withdrawal amount the user types

  // ========================================================================
  // VARIABLE - How much money can be withdrawn
  // double = number with decimals (like 150.50)
  // ========================================================================
  double availableEarnings = 10000.00;

  // ========================================================================
  // DISPOSE METHOD - Clean up when page closes to prevent memory leaks
  // Think of it like turning off the lights before leaving a room
  // ========================================================================
  @override
  void dispose() {
    // Tell each controller to stop listening and free up memory
    _nameController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _withdrawalController.dispose();
    super.dispose();
  }

  // ========================================================================
  // SUBMIT WITHDRAWAL FUNCTION - Runs when user clicks the Submit button
  // ========================================================================
  void _submitWithdrawal() {
    // Check if all form fields are valid (not empty, correct format, etc.)
    if (_formKey.currentState!.validate()) {
      // If everything is valid, show a success message at the bottom
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal request submitted')),
      );
      // In a real app, you would send this data to your backend/database here
    }
    // If validation fails, error messages will show in the text fields automatically
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
      // Set the background color to dark blue
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
          'Withdraw Earnings',
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
                  title: const Text('Withdrawal Info'),
                  content: const Text(
                    'Withdrawal requests are processed immediately. Ensure all information is accurate.',
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
      // AVAILABLE EARNINGS CARD - Shows how much money is available
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
              color: Colors.black.withValues(alpha: 0.4), // Stronger shadow (35% opacity)
              spreadRadius: 0,                          // Subtle spread
              blurRadius: 16,                           // Softer, larger blur
              offset: const Offset(0, 8),               // Slightly lower offset for prominence
            ),
          ],
        ),

        child: Column(
          // Stack items vertically inside the box
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label text
              const Text(
                'Available Earnings',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            const SizedBox(height: 8), // Add 8 pixels of space

            // Amount text - Shows the earnings amount
            Text(
              'RM ${availableEarnings.toStringAsFixed(2)}',
              // toStringAsFixed(2) = Convert number to text with 2 decimals
              // Example: 150.5 becomes "150.50"
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
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
                    
                    // ========================================================
                    // FIELD 1 - Account Holder Name
                    // ========================================================
                    _buildLabel('Account Holder Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      // TextFormField = Input field for text
                      controller: _nameController,
                      // controller connects this field to _nameController
                      // So whatever user types gets stored in _nameController
                      decoration: _buildInputDecoration(),
                      // Use the styling from _buildInputDecoration() method
                      style: _inputTextStyle,
                      // Text color is black
                      
                      // VALIDATOR - Check if this field is valid
                      validator: (value) {
                        // value = what the user typed
                        if (value?.isEmpty ?? true) {
                          // If the field is empty, show error message
                          return 'Please enter account holder name';
                        }
                        // If not empty, return null (no error)
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ========================================================
                    // FIELD 2 - Bank Name
                    // ========================================================
                    _buildLabel('Bank Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bankController,
                      decoration: _buildInputDecoration(),
                      style: _inputTextStyle,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please select a bank';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ========================================================
                    // FIELD 3 - Account Number
                    // ========================================================
                    _buildLabel('Account Number'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _accountController,
                      decoration: _buildInputDecoration(),
                      style: _inputTextStyle,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter account number';
                        }
                        // Also check if the account number is long enough
                        if (value!.length < 10) {
                          return 'Account number must be at least 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ========================================================
                    // FIELD 4 - Withdrawal Amount
                    // ========================================================
                    const Text(
                      'Withdrawal Amount',
                      style: TextStyle(
                          color: Color.fromARGB(255, 21, 36, 69), // First palette color
                        fontSize: 16, // 2 sizes larger than default 14
                        fontWeight: FontWeight.w900, // Bolder
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _withdrawalController,
                      decoration: _buildInputDecoration().copyWith(
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
                          return 'Please enter withdrawal amount';
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
                  onPressed: _submitWithdrawal,
                  // When clicked, run the _submitWithdrawal function
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 39, 39, 215), // Purple color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit Withdrawal',
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
  // HELPER METHOD 1 - Build a label (like "Account Holder Name")
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
  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      filled: true, // Fill the field with a background color
      // Slight light fill so fields read as inputs but not fully white
      // Darker tinted field background to stand out against the page
      fillColor: const Color.fromARGB(255, 141, 143, 145).withValues(alpha: 0.18),
      
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
          color: const Color.fromARGB(255, 107, 106, 106).withValues(alpha: 0.6), // Bright light border when focused
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
      
      // Space inside the field (padding) - increase vertical for easier tapping
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      
      // Style for placeholder text (darker for better readability)
      hintStyle: const TextStyle(color: Color(0xFF333333)),
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
          'Disclaimer:',
          style: TextStyle(
            color: Color.fromARGB(255, 21, 36, 69),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Disclaimer point 1
        _buildDisclaimerPoint(
          'Please ensure that all information provided is accurate.',
        ),
        const SizedBox(height: 3),
        
        // Disclaimer point 2
        _buildDisclaimerPoint(
          'Please ensure that the bank account holder\'s name provided is registered as per the NRIC name.',
        ),
        const SizedBox(height: 3),
        
        // Disclaimer point 3
        _buildDisclaimerPoint(
          'The earnings withdrawal request will be processed according to the information provided here.',
        ),
      ],
    );
  }

  // ========================================================================
  // HELPER METHOD 4 - Build each disclaimer point with a bullet
  // ========================================================================
  Widget _buildDisclaimerPoint(String text) {
    // text = the disclaimer text (passed in as parameter)
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
        // The disclaimer text
        Expanded(
          // Expanded = Take up remaining space
          child: Text(
            text,
            style: TextStyle(
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