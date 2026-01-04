import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'job_model.dart';
import 'micro_shift.dart';
import '../services/location_service.dart';
import '../components/location_picker.dart';
import '../components/micro_shift_calendar.dart';

class CreateJobPage extends StatefulWidget {
  final Job? existingJob;

  const CreateJobPage({super.key, this.existingJob});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _payRateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Location fields
  String _locationAddress = '';
  GeoLocation? _geoLocation;

  // Micro-shift calendar selection
  Set<DateTime> _selectedDates = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool get isEdit => widget.existingJob != null;

  @override
  void initState() {
    super.initState();

    final job = widget.existingJob;
    if (job != null) {
      _titleController.text = job.title;
      _companyController.text = job.company;
      _locationAddress = job.location;
      _geoLocation = job.geoLocation;
      _payRateController.text = job.payRate.toString();
      _descriptionController.text = job.description;

      // Load existing micro-shifts into calendar selection
      if (job.microShifts.isNotEmpty) {
        _selectedDates = job.microShifts.map((s) => s.date).toSet();
        // Get the time from first shift (all shifts have same time)
        final firstShift = job.microShifts.first;
        _startTime = TimeOfDay(
          hour: firstShift.start.hour,
          minute: firstShift.start.minute,
        );
        _endTime = TimeOfDay(
          hour: firstShift.end.hour,
          minute: firstShift.end.minute,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _payRateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isValidRange(TimeOfDay start, TimeOfDay end) {
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    return e > s;
  }

  List<MicroShift> _buildMicroShifts() {
    if (_selectedDates.isEmpty || _startTime == null || _endTime == null) {
      return [];
    }

    return _selectedDates.map((date) {
      final start = DateTime(
        date.year,
        date.month,
        date.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final end = DateTime(
        date.year,
        date.month,
        date.day,
        _endTime!.hour,
        _endTime!.minute,
      );
      return MicroShift(start: start, end: end);
    }).toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Job' : 'Create Job',
          style: const TextStyle(
            color: Color(0xFF0F1E3C),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF0F1E3C)),
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Details Section
              _buildSectionHeader('Job Details', Icons.work_outline),
              const SizedBox(height: 12),
              _buildModernTextField(_titleController, 'Job Title', Icons.title),
              const SizedBox(height: 12),
              _buildModernTextField(
                _companyController,
                'Company',
                Icons.business,
              ),
              const SizedBox(height: 12),

              // Location picker with geo-coding
              LocationPickerField(
                initialAddress: _locationAddress,
                initialGeoLocation: _geoLocation,
                labelText: 'Job Location',
                hintText: 'Search for job location...',
                onLocationChanged: (address, geoLocation) {
                  setState(() {
                    _locationAddress = address;
                    _geoLocation = geoLocation;
                  });
                },
              ),
              if (_geoLocation != null && _geoLocation!.isValid) ...[
                const SizedBox(height: 8),
                _buildLocationVerifiedBadge(),
              ],
              const SizedBox(height: 12),

              _buildModernPayRateField(),

              const SizedBox(height: 24),

              // Micro-Shift Section - THE STAR FEATURE
              _buildSectionHeader('Micro-Shift Schedule', Icons.calendar_month),
              const SizedBox(height: 8),
              Text(
                'Select the dates you need workers and set the working hours',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Beautiful Calendar
              MicroShiftCalendar(
                selectedDates: _selectedDates,
                onSelectionChanged: (dates) {
                  setState(() => _selectedDates = dates);
                },
                multiSelect: true,
                selectedColor: const Color(0xFF0F1E3C),
              ),

              const SizedBox(height: 16),

              // Time Selection
              MicroShiftTimeSelector(
                startTime: _startTime,
                endTime: _endTime,
                onStartTimeChanged: (time) => setState(() => _startTime = time),
                onEndTimeChanged: (time) => setState(() => _endTime = time),
              ),

              // Validation message
              if (_selectedDates.isNotEmpty &&
                  (_startTime == null || _endTime == null)) ...[
                const SizedBox(height: 12),
                _buildWarningMessage(
                  'Please set working hours for the selected dates',
                ),
              ],

              if (_startTime != null &&
                  _endTime != null &&
                  !_isValidRange(_startTime!, _endTime!)) ...[
                const SizedBox(height: 12),
                _buildWarningMessage('End time must be after start time'),
              ],

              const SizedBox(height: 24),

              // Description Section
              _buildSectionHeader(
                'Job Description',
                Icons.description_outlined,
              ),
              const SizedBox(height: 12),
              _buildModernDescriptionField(),

              const SizedBox(height: 32),

              // Save Button
              _buildSaveButton(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F1E3C), Color(0xFF1A3A6E)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F1E3C).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F1E3C),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          return null;
        },
      ),
    );
  }

  Widget _buildModernPayRateField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _payRateController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: 'Pay Rate (RM/hr)',
          prefixIcon: const Icon(
            Icons.payments_outlined,
            color: Color(0xFF10B981),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter pay rate';
          if (double.tryParse(value) == null) return 'Invalid number';
          return null;
        },
      ),
    );
  }

  Widget _buildModernDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 5,
        decoration: InputDecoration(
          labelText: 'Description',
          alignLabelWithHint: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildLocationVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Location verified • ${_geoLocation!.latitude.toStringAsFixed(4)}, ${_geoLocation!.longitude.toStringAsFixed(4)}',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final bool canSave =
        _selectedDates.isNotEmpty &&
        _startTime != null &&
        _endTime != null &&
        _isValidRange(_startTime!, _endTime!);

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: canSave
            ? const LinearGradient(
                colors: [Color(0xFF0F1E3C), Color(0xFF1A3A6E)],
              )
            : null,
        color: canSave ? null : Colors.grey.shade300,
        boxShadow: canSave
            ? [
                BoxShadow(
                  color: const Color(0xFF0F1E3C).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: canSave ? _saveJob : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEdit ? Icons.save : Icons.rocket_launch,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              isEdit ? 'Save Changes' : 'Create Job',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveJob() {
    if (!_formKey.currentState!.validate()) return;

    // Validate location
    if (_locationAddress.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a job location.')),
      );
      return;
    }

    // Validate micro-shifts
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one work date.')),
      );
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set working hours.')),
      );
      return;
    }

    if (!_isValidRange(_startTime!, _endTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    final double parsedPayRate =
        double.tryParse(_payRateController.text) ?? 0.0;
    final microShifts = _buildMicroShifts();

    final Job jobToReturn = Job(
      id:
          widget.existingJob?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      company: _companyController.text,
      location: _locationAddress,
      geoLocation: _geoLocation,
      payRate: parsedPayRate,
      description: _descriptionController.text,
      microShifts: microShifts,
      applicants: widget.existingJob?.applicants ?? [],
      hires: widget.existingJob?.hires ?? [],
    );

    Navigator.pop(context, jobToReturn);
  }
}
