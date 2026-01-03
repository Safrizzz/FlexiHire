import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

// ============================================================================
// THIS IS THE PAGE WIDGET - It tells Flutter this is a page that will change
// ============================================================================
class EmployerReviewPage extends StatefulWidget {
  final String? employeeId;
  final String? jobId;
  const EmployerReviewPage({super.key, this.employeeId, this.jobId});

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
    double total = punctualityRating + efficiencyRating + communicationRating + teamworkRating + attitudeRating;
    double average = total / 5;
    return average;
  }

  // ========================================================================
  // DISPOSE METHOD - Clean up when page closes
  // ========================================================================
  @override
  void dispose() {
    _employeeNameController.dispose();
    _employeeIDController.dispose();
    _reviewCommentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.employeeId != null) _employeeIDController.text = widget.employeeId!;
    if (widget.jobId != null) _jobIdController.text = widget.jobId!;
  }

  // ========================================================================
  // SUBMIT REVIEW FUNCTION - Runs when user clicks the Submit button
  // ========================================================================
  void _submitReview() {
    // Check if all form fields are valid
    if (_formKey.currentState!.validate()) {
      // Check if all ratings have been set
      if (punctualityRating == 0.0 || efficiencyRating == 0.0 || 
          communicationRating == 0.0 || teamworkRating == 0.0 || attitudeRating == 0.0) {
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
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review submitted! Average Rating: ${getAverageRating().toStringAsFixed(2)}')),
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
        
        // RIGHT SIDE - Info button
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Review Guidelines'),
                  content: const Text(
                    'Rate the employee on a scale of 1-5 stars for each category. The final rating is the average of all five categories.',
                  ),
                  actions: [
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
      // BODY - Main content area
      // ===================================================================
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // ============================================================
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _employeeNameController,
                        decoration: _buildInputDecoration(hintText: 'Employee name'),
                        style: const TextStyle(color: Color.fromARGB(255, 12, 12, 12), fontSize: 16, fontWeight: FontWeight.w600),
                        validator: (value) => (value?.isEmpty ?? true) ? 'Please enter employee name' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final email = await showDialog<String>(
                          context: context,
                          builder: (ctx) {
                            final ctrl = TextEditingController();
                            return AlertDialog(
                              title: const Text('Find by email'),
                              content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Employee email')),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Find')),
                              ],
                            );
                          },
                        );
                        if (email == null || email.isEmpty) return;
                        final profile = await FirestoreService().getUserByEmail(email);
                        if (!context.mounted) return;
                        if (profile != null) {
                          setState(() {
                            _employeeNameController.text = profile.displayName;
                            _employeeIDController.text = profile.id;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee found')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user with that email')));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F1E3C)),
                      child: const Text('Find', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ============================================================
                // EMPLOYEE ID FIELD
                // ============================================================
                _buildLabel('Employee ID (uid)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _employeeIDController,
                  decoration: _buildInputDecoration(hintText: 'Enter employee ID'),
                  style: const TextStyle(
                    color: Color.fromARGB(255, 12, 12, 12),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  validator: (value) {
                    if ((value?.isEmpty ?? true)) return 'Please enter employee ID';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // (Job ID removed from form; jobId is optional and can be prefilled when opened from Hires)
                const SizedBox(height: 8),
                
                // ============================================================
                // RATING SCALES - 5 Categories with star rating
                // ============================================================
                
                // SCALE 1 - Punctuality
                _buildRatingScale(
                  title: 'Punctuality',
                  description: 'Arrives on time and meets deadlines',
                  currentRating: punctualityRating,
                  onChanged: (rating) {
                    setState(() {
                      punctualityRating = rating;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // SCALE 2 - Efficiency
                _buildRatingScale(
                  title: 'Efficiency',
                  description: 'Completes tasks effectively and productively',
                  currentRating: efficiencyRating,
                  onChanged: (rating) {
                    setState(() {
                      efficiencyRating = rating;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // SCALE 3 - Communication
                _buildRatingScale(
                  title: 'Communication',
                  description: 'Communicates clearly and listens well',
                  currentRating: communicationRating,
                  onChanged: (rating) {
                    setState(() {
                      communicationRating = rating;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // SCALE 4 - Teamwork
                _buildRatingScale(
                  title: 'Teamwork',
                  description: 'Collaborates well with team members',
                  currentRating: teamworkRating,
                  onChanged: (rating) {
                    setState(() {
                      teamworkRating = rating;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // SCALE 5 - Attitude
                _buildRatingScale(
                  title: 'Attitude',
                  description: 'Maintains positive attitude and professionalism',
                  currentRating: attitudeRating,
                  onChanged: (rating) {
                    setState(() {
                      attitudeRating = rating;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // ============================================================
                // AVERAGE RATING DISPLAY
                // ============================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2F5C),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Rating',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            getAverageRating().toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '/ 5.0',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStarDisplay(getAverageRating()),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // ============================================================
                // REVIEW COMMENT FIELD
                // ============================================================
                _buildLabel('Additional Comments'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reviewCommentController,
                  decoration: _buildInputDecoration(hintText: 'Write additional comments (optional)'),
                  style: const TextStyle(
                    color: Color.fromARGB(255, 12, 12, 12),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 32),
                
                // ============================================================
                // SUBMIT BUTTON
                // ============================================================
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 39, 39, 215),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Submit Review',
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
      ),
    );
  }

  // ========================================================================
  // HELPER METHOD 1 - Build a label
  // ========================================================================
  Widget _buildLabel(String label) {
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
  // HELPER METHOD 2 - Build input decoration
  // ========================================================================
  InputDecoration _buildInputDecoration({String? hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color.fromARGB(255, 141, 143, 145).withValues(alpha: 0.18),
      hintText: hintText,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.92),
          width: 1.4,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: const Color.fromARGB(255, 107, 106, 106).withValues(alpha: 0.6),
          width: 2.4,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: Color(0xFF333333)),
    );
  }

  // ========================================================================
  // HELPER METHOD 3 - Build rating scale with stars
  // ========================================================================
  Widget _buildRatingScale({
    required String title,
    required String description,
    required double currentRating,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and description
        Text(
          title,
          style: const TextStyle(
            color: Color.fromARGB(255, 21, 36, 69),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            color: Color.fromARGB(255, 128, 128, 128),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        
        // Star rating row
        Row(
          children: [
            // Build 5 stars
            for (int i = 1; i <= 5; i++)
              GestureDetector(
                onTap: () {
                  // When star is tapped, set the rating to that number
                  onChanged(i.toDouble());
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    // If i <= current rating, show filled star, else show empty star
                    i <= currentRating ? Icons.star : Icons.star_border,
                    color: i <= currentRating ? Colors.amber : Colors.grey,
                    size: 32,
                  ),
                ),
              ),
            const SizedBox(width: 16),
            // Show the rating number
            Text(
              currentRating > 0 ? currentRating.toStringAsFixed(1) : 'Not rated',
              style: TextStyle(
                color: currentRating > 0 ? Colors.amber : Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================================
  // HELPER METHOD 4 - Build star display for overall rating
  // ========================================================================
  Widget _buildStarDisplay(double rating) {
    return Row(
      children: [
        // Build 5 stars based on rating
        for (int i = 1; i <= 5; i++)
          Icon(
            i <= rating.toInt() ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 24,
          ),
      ],
    );
  }
}
