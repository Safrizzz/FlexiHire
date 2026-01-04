import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'job_model.dart';
import 'micro_shift.dart';
import '../services/location_service.dart';
import '../components/location_picker.dart';

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

  final List<MicroShift> _microShifts = [];
  DateTime? _selectedDate;
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
      _microShifts.addAll(job.microShifts);
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 13, minute: 0),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  String _fmt(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool _isValidRange(TimeOfDay start, TimeOfDay end) {
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    return e > s;
  }

  void _addMicroShift() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date.')));
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end time.')),
      );
      return;
    }

    if (!_isValidRange(_startTime!, _endTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    final d = _selectedDate!;
    final start = DateTime(
      d.year,
      d.month,
      d.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final end = DateTime(
      d.year,
      d.month,
      d.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    final shift = MicroShift(start: start, end: end);

    setState(() {
      // prevent exact duplicates
      final exists = _microShifts.any(
        (s) => s.start == shift.start && s.end == shift.end,
      );
      if (!exists) _microShifts.add(shift);
      _selectedDate = null;
      _startTime = null;
      _endTime = null;
    });
  }

  void _removeMicroShift(MicroShift shift) {
    setState(() => _microShifts.remove(shift));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: Text(
          isEdit ? 'Edit Job' : 'Create Job',
          style: const TextStyle(color: Color.fromARGB(255, 21, 36, 69)),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 21, 36, 69)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_titleController, 'Job Title'),
              const SizedBox(height: 16),
              _buildTextField(_companyController, 'Company'),
              const SizedBox(height: 16),

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location verified: ${_geoLocation!.latitude.toStringAsFixed(4)}, ${_geoLocation!.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              TextFormField(
                controller: _payRateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Pay Rate (RM/hr)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pay rate';
                  }
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ✅ Micro-shift selection UI
              _microShiftSection(),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Job Description',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F1E3C),
                  ),
                  onPressed: _saveJob,
                  child: Text(
                    isEdit ? 'Save Changes' : 'Create Job',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _microShiftSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Micro-Shift Selection',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickDate,
                  child: Text(
                    _selectedDate == null
                        ? 'Pick date'
                        : _fmtDate(_selectedDate!),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickStartTime,
                  child: Text(
                    _startTime == null ? 'Start time' : _fmt(_startTime!),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickEndTime,
                  child: Text(_endTime == null ? 'End time' : _fmt(_endTime!)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F1E3C),
              ),
              onPressed: _addMicroShift,
              child: const Text(
                'Add Micro-Shift',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          if (_microShifts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _microShifts.map((shift) {
                return Chip(
                  label: Text(shift.toDisplay()),
                  onDeleted: () => _removeMicroShift(shift),
                );
              }).toList(),
            ),
          ],
        ],
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

    final double parsedPayRate =
        double.tryParse(_payRateController.text) ?? 0.0;

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
      microShifts: List<MicroShift>.from(_microShifts),
      applicants: widget.existingJob?.applicants ?? [],
      hires: widget.existingJob?.hires ?? [],
    );

    Navigator.pop(context, jobToReturn);
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter $label';
        return null;
      },
    );
  }
}
