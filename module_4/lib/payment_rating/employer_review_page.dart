import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

// ============================================================================
// THIS IS THE PAGE WIDGET - It tells Flutter this is a page that will change
// ============================================================================
class EmployerReviewPage extends StatefulWidget {
  final String? employeeId;
  final String? employeeName;
  final String? employeeEmail;
  final String? jobId;
  const EmployerReviewPage({super.key, this.employeeId, this.employeeName, this.employeeEmail, this.jobId});

  @override
  State<EmployerReviewPage> createState() => _EmployerReviewPageState();
}

// ============================================================================
// THIS IS THE PAGE STATE - Where all the code and UI happens
// ============================================================================
class _EmployerReviewPageState extends State<EmployerReviewPage> {
  // ========================================================================
  // FORM KEY - This is like a remote control for the entire form
  // ========================================================================
  final _formKey = GlobalKey<FormState>();

  // ========================================================================
  // TEXT CONTROLLERS - Store employee name and review comment
  // ========================================================================
  final _employeeEmailController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _employeeIDController = TextEditingController();
  final _reviewCommentController = TextEditingController();
  final _jobIdController = TextEditingController();

  // ========================================================================
  // RATING VARIABLES - Store the rating for each scale (0 to 5)
  // ========================================================================
  double punctualityRating = 0.0;
  double efficiencyRating = 0.0;
  double communicationRating = 0.0;
  double teamworkRating = 0.0;
  double attitudeRating = 0.0;

  // ========================================================================
  // CALCULATE AVERAGE RATING - Get the average of all 5 ratings
  // ========================================================================
  double getAverageRating() {
    double total =
        punctualityRating +
        efficiencyRating +
        communicationRating +
        teamworkRating +
        attitudeRating;
    double average = total / 5;
    return average;
  }

  // ========================================================================
  // DISPOSE METHOD - Clean up when page closes
  // ========================================================================
  @override
  void dispose() {
    _employeeEmailController.dispose();
    _employeeNameController.dispose();
    _employeeIDController.dispose();
    _reviewCommentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.employeeId != null) {
      _employeeIDController.text = widget.employeeId!;
    }
    if (widget.employeeName != null) {
      _employeeNameController.text = widget.employeeName!;
    }
    if (widget.employeeEmail != null) {
      _employeeEmailController.text = widget.employeeEmail!;
    }
    if (widget.jobId != null) _jobIdController.text = widget.jobId!;
  }

  // ========================================================================
  // SUBMIT REVIEW FUNCTION - Runs when user clicks the Submit button
  // ========================================================================
  void _submitReview() {
    // Check if all form fields are valid
    if (_formKey.currentState!.validate()) {
      // Check if all ratings have been set
      if (punctualityRating == 0.0 ||
          efficiencyRating == 0.0 ||
          communicationRating == 0.0 ||
          teamworkRating == 0.0 ||
          attitudeRating == 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please rate all categories')),
        );
        return;
      }

      FirestoreService()
          .submitEmployerReview(
            employeeId: _employeeIDController.text,
            jobId: _jobIdController.text,
            punctuality: punctualityRating,
            efficiency: efficiencyRating,
            communication: communicationRating,
            teamwork: teamworkRating,
            attitude: attitudeRating,
            comment: _reviewCommentController.text,
          )
          .then((_) {
            if (!mounted) return;
            // Show success dialog and navigate back
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Review Submitted!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F1E3C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Average Rating: ${getAverageRating().toStringAsFixed(1)} / 5.0',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 1; i <= 5; i++)
                          Icon(
                            i <= getAverageRating().round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 28,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context, true); // Go back with result to trigger refresh
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F1E3C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
    }
  }

  // ========================================================================
  // BUILD METHOD - This builds and displays the entire page UI
  // ========================================================================
  @override
  Widget build(BuildContext context) {
    // =====================================================================
    // SCAFFOLD - Basic structure of the Android screen
    // =====================================================================
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 251),

      // ===================================================================
      // APP BAR - The top header of the page
      // ===================================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0,

        // LEFT SIDE - Back arrow button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        // MIDDLE - Title text
        title: const Text(
          'Review Employee',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ===================================================================
      // BODY - Main content area
      // ===================================================================
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================================
                // FIND EMPLOYEE CARD
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
                              Icons.person_search,
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
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _employeeEmailController,
                              decoration: _buildModernInputDecoration(
                                hintText: 'Enter employee email',
                                prefixIcon: Icons.email_outlined,
                              ),
                              style: const TextStyle(
                                color: Color(0xFF0F1E3C),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF0F1E3C), Color(0xFF1A3A5C)],
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
                                  final email = _employeeEmailController.text
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
                                      _employeeIDController.text = profile.id;
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
                                        borderRadius: BorderRadius.circular(10),
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
                      const SizedBox(height: 16),
                      _buildModernLabel('Employee Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _employeeNameController,
                        decoration: _buildModernInputDecoration(
                          hintText: 'Employee name',
                          prefixIcon: Icons.badge_outlined,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF0F1E3C),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        validator: (value) => (value?.isEmpty ?? true)
                            ? 'Please enter employee name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildModernLabel('Employee ID'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _employeeIDController,
                        decoration: _buildModernInputDecoration(
                          hintText: 'Enter employee ID',
                          prefixIcon: Icons.fingerprint,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF0F1E3C),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        validator: (value) => (value?.isEmpty ?? true)
                            ? 'Please enter employee ID'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ============================================================
                // RATING SCALES CARD
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
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Performance Rating',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F1E3C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // SCALE 1 - Punctuality
                      _buildModernRatingScale(
                        title: 'Punctuality',
                        description: 'Arrives on time and meets deadlines',
                        icon: Icons.schedule,
                        iconColor: Colors.blue,
                        currentRating: punctualityRating,
                        onChanged: (rating) =>
                            setState(() => punctualityRating = rating),
                      ),
                      _buildRatingDivider(),

                      // SCALE 2 - Efficiency
                      _buildModernRatingScale(
                        title: 'Efficiency',
                        description:
                            'Completes tasks effectively and productively',
                        icon: Icons.speed,
                        iconColor: Colors.green,
                        currentRating: efficiencyRating,
                        onChanged: (rating) =>
                            setState(() => efficiencyRating = rating),
                      ),
                      _buildRatingDivider(),

                      // SCALE 3 - Communication
                      _buildModernRatingScale(
                        title: 'Communication',
                        description: 'Communicates clearly and listens well',
                        icon: Icons.chat_bubble_outline,
                        iconColor: Colors.purple,
                        currentRating: communicationRating,
                        onChanged: (rating) =>
                            setState(() => communicationRating = rating),
                      ),
                      _buildRatingDivider(),

                      // SCALE 4 - Teamwork
                      _buildModernRatingScale(
                        title: 'Teamwork',
                        description: 'Collaborates well with team members',
                        icon: Icons.groups_outlined,
                        iconColor: Colors.orange,
                        currentRating: teamworkRating,
                        onChanged: (rating) =>
                            setState(() => teamworkRating = rating),
                      ),
                      _buildRatingDivider(),

                      // SCALE 5 - Attitude
                      _buildModernRatingScale(
                        title: 'Attitude',
                        description:
                            'Maintains positive attitude and professionalism',
                        icon: Icons.emoji_emotions_outlined,
                        iconColor: Colors.pink,
                        currentRating: attitudeRating,
                        onChanged: (rating) =>
                            setState(() => attitudeRating = rating),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ============================================================
                // OVERALL RATING CARD
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
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: const Color(0xFF0F1E3C).withValues(alpha: 0.2),
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
                              Icons.analytics_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Overall Rating',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            getAverageRating().toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              ' / 5.0',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _buildModernStarDisplay(getAverageRating()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getRatingColor(
                            getAverageRating(),
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getRatingLabel(getAverageRating()),
                          style: TextStyle(
                            color: _getRatingColor(getAverageRating()),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ============================================================
                // COMMENTS CARD
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
                              Icons.edit_note,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Additional Comments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F1E3C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reviewCommentController,
                        decoration: _buildModernInputDecoration(
                          hintText:
                              'Share your thoughts about the employee\'s performance...',
                          prefixIcon: null,
                        ).copyWith(prefixIcon: null),
                        style: const TextStyle(
                          color: Color(0xFF0F1E3C),
                          fontSize: 15,
                          height: 1.5,
                        ),
                        maxLines: 4,
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
                      onTap: _submitReview,
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rate_review,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Submit Review',
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
      ),
    );
  }

  // ========================================================================
  // HELPER - Modern label
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
  // HELPER - Modern input decoration
  // ========================================================================
  InputDecoration _buildModernInputDecoration({
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F9FC),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
  // HELPER - Rating divider
  // ========================================================================
  Widget _buildRatingDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: Colors.grey.shade100, thickness: 1),
    );
  }

  // ========================================================================
  // HELPER - Modern rating scale
  // ========================================================================
  Widget _buildModernRatingScale({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required double currentRating,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F1E3C),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 1; i <= 5; i++)
              GestureDetector(
                onTap: () => onChanged(i.toDouble()),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      i <= currentRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: i <= currentRating
                          ? Colors.amber
                          : Colors.grey.shade300,
                      size: 36,
                    ),
                  ),
                ),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: currentRating > 0
                    ? Colors.amber.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                currentRating > 0 ? currentRating.toStringAsFixed(1) : '–',
                style: TextStyle(
                  color: currentRating > 0
                      ? Colors.amber.shade700
                      : Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================================
  // HELPER - Modern star display
  // ========================================================================
  Widget _buildModernStarDisplay(double rating) {
    return Row(
      children: [
        for (int i = 1; i <= 5; i++)
          Icon(
            i <= rating.round()
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 28,
          ),
      ],
    );
  }

  // ========================================================================
  // HELPER - Get rating color
  // ========================================================================
  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.lightGreen;
    if (rating >= 2.5) return Colors.amber;
    if (rating >= 1.5) return Colors.orange;
    return Colors.red;
  }

  // ========================================================================
  // HELPER - Get rating label
  // ========================================================================
  String _getRatingLabel(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Below Average';
    if (rating > 0) return 'Poor';
    return 'Not Rated';
  }
}
