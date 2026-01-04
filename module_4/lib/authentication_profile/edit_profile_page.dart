import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/user_role.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../components/location_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  bool _loading = true;
  bool _saving = false;
  UserRole _role = UserRole.student;

  // Personal Information Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  String _locationAddress = '';
  GeoLocation? _geoLocation;
  String _selectedGender = '';
  String _selectedEthnicity = '';
  DateTime? _dateOfBirth;
  String _selectedLanguage = '';

  // Bank Details Controllers
  final _bankNameCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();

  // Job Experience
  List<JobExperience> _jobExperiences = [];

  // Supporting Documents
  List<SupportingDocument> _documents = [];
  bool _uploadingDocument = false;

  // Dropdown options
  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];
  final List<String> _ethnicityOptions = [
    'Malay',
    'Chinese',
    'Indian',
    'Others',
    'Prefer not to say',
  ];
  final List<String> _languageOptions = [
    'English',
    'Malay',
    'Mandarin',
    'Tamil',
    'English & Malay',
    'English & Mandarin',
    'Multilingual',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final p = await _service.getUserProfile(uid);
    if (p != null) {
      _nameCtrl.text = p.displayName;
      _phoneCtrl.text = p.phone;
      _emailCtrl.text = p.email;
      _locationAddress = p.location;
      _geoLocation = p.geoLocation;
      _skillsCtrl.text = p.skills.join(', ');
      _selectedGender = p.gender;
      _selectedEthnicity = p.ethnicity;
      _dateOfBirth = p.dateOfBirth;
      _selectedLanguage = p.languageProficiency;
      _bankNameCtrl.text = p.bankName;
      _accountHolderCtrl.text = p.accountHolderName;
      _bankAccountCtrl.text = p.bankAccountNumber;
      _jobExperiences = List.from(p.jobExperience);
      _documents = List.from(p.documents);
      _role = p.role;
    } else {
      _emailCtrl.text = FirebaseAuth.instance.currentUser?.email ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      // Navigate to tab with validation error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final profile = UserProfile(
        id: user.uid,
        email: _emailCtrl.text.trim(),
        displayName: _nameCtrl.text.trim(),
        photoUrl: user.photoURL ?? '',
        phone: _phoneCtrl.text.trim(),
        location: _locationAddress.trim(),
        geoLocation: _geoLocation,
        skills: _skillsCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        role: _role,
        gender: _selectedGender,
        ethnicity: _selectedEthnicity,
        dateOfBirth: _dateOfBirth,
        languageProficiency: _selectedLanguage,
        bankName: _bankNameCtrl.text.trim(),
        accountHolderName: _accountHolderCtrl.text.trim(),
        bankAccountNumber: _bankAccountCtrl.text.trim(),
        jobExperience: _jobExperiences,
        documents: _documents,
      );

      await _service.updateUserProfile(profile);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _skillsCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountHolderCtrl.dispose();
    _bankAccountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                      'Edit Profile',
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
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: const Color(0xFF0F1E3C),
                        unselectedLabelColor: Colors.grey.shade500,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        indicatorColor: const Color(0xFF0F1E3C),
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(text: 'Basic Information'),
                          Tab(text: 'Bank Details'),
                          Tab(text: 'Job Experience'),
                          Tab(text: 'Documents'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              body: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPersonalInfoTab(),
                    _buildBankDetailsTab(),
                    _buildJobExperienceTab(),
                    _buildDocumentsTab(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _loading
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F1E3C),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0xFF0F1E3C).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  // ==================== PERSONAL INFORMATION TAB ====================
  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Personal Details',
            icon: Icons.person_outline,
            children: [
              _buildTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'Enter your full name',
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailCtrl,
                label: 'Email Address',
                hint: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Email is read-only
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                hint: 'e.g. 0123456789',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Gender',
                value: _selectedGender.isEmpty ? null : _selectedGender,
                items: _genderOptions,
                prefixIcon: Icons.wc_outlined,
                onChanged: (v) => setState(() => _selectedGender = v ?? ''),
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Ethnicity',
                value: _selectedEthnicity.isEmpty ? null : _selectedEthnicity,
                items: _ethnicityOptions,
                prefixIcon: Icons.groups_outlined,
                onChanged: (v) => setState(() => _selectedEthnicity = v ?? ''),
              ),
              const SizedBox(height: 16),
              _buildDateField(
                label: 'Date of Birth',
                value: _dateOfBirth,
                prefixIcon: Icons.cake_outlined,
                onChanged: (date) => setState(() => _dateOfBirth = date),
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'Language Proficiency',
                value: _selectedLanguage.isEmpty ? null : _selectedLanguage,
                items: _languageOptions,
                prefixIcon: Icons.language_outlined,
                onChanged: (v) => setState(() => _selectedLanguage = v ?? ''),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Location',
            icon: Icons.location_on_outlined,
            children: [
              LocationPickerField(
                initialAddress: _locationAddress,
                initialGeoLocation: _geoLocation,
                labelText: 'Your Location',
                hintText: 'Search for your location...',
                onLocationChanged: (address, geoLocation) {
                  setState(() {
                    _locationAddress = address;
                    _geoLocation = geoLocation;
                  });
                },
              ),
              if (_geoLocation != null && _geoLocation!.isValid) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Location verified - distance calculations enabled',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (_role == UserRole.student) ...[
            const SizedBox(height: 20),
            _buildSectionCard(
              title: 'Skills',
              icon: Icons.psychology_outlined,
              children: [
                _buildTextField(
                  controller: _skillsCtrl,
                  label: 'Your Skills',
                  hint: 'e.g. Python, Flutter, Communication',
                  prefixIcon: Icons.auto_awesome_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Separate multiple skills with commas',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ==================== BANK DETAILS TAB ====================
  Widget _buildBankDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Bank Information',
            icon: Icons.account_balance_outlined,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your bank details are used for receiving payments from completed jobs.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _bankNameCtrl,
                label: 'Bank Name',
                hint: 'e.g. Maybank, CIMB, Public Bank',
                prefixIcon: Icons.business_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _accountHolderCtrl,
                label: 'Account Holder Name',
                hint: 'Name as shown on bank account',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bankAccountCtrl,
                label: 'Bank Account Number',
                hint: 'Enter your account number',
                prefixIcon: Icons.credit_card_outlined,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ==================== JOB EXPERIENCE TAB ====================
  Widget _buildJobExperienceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Work Experience',
            icon: Icons.work_outline,
            headerAction: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E3C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
              onPressed: _showAddJobExperienceDialog,
            ),
            children: [
              if (_jobExperiences.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_off_outlined,
                        size: 60,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No work experience added',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your work experience',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._jobExperiences.asMap().entries.map((entry) {
                  final index = entry.key;
                  final job = entry.value;
                  return _buildJobExperienceCard(job, index);
                }),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildJobExperienceCard(JobExperience job, int index) {
    final dateFormat = DateFormat('MMM yyyy');
    final startStr = dateFormat.format(job.startDate);
    final endStr = job.endDate != null
        ? dateFormat.format(job.endDate!)
        : 'Present';

    return Container(
      margin: EdgeInsets.only(top: index > 0 ? 12 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E3C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.work, color: Color(0xFF0F1E3C), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF0F1E3C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$startStr - $endStr',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
            onPressed: () {
              setState(() {
                _jobExperiences.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  void _showAddJobExperienceDialog() {
    final titleCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Add Work Experience',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F1E3C),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Job Title',
                      hintText: 'e.g. Part-time Tutor',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.work_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() => startDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  startDate != null
                                      ? DateFormat(
                                          'MMM yyyy',
                                        ).format(startDate!)
                                      : 'Start Date',
                                  style: TextStyle(
                                    color: startDate != null
                                        ? Colors.black87
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() => endDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    endDate != null
                                        ? DateFormat(
                                            'MMM yyyy',
                                          ).format(endDate!)
                                        : 'End Date',
                                    style: TextStyle(
                                      color: endDate != null
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leave end date empty for current job',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F1E3C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty ||
                            startDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fill in title and start date',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final newJob = JobExperience(
                          title: titleCtrl.text.trim(),
                          startDate: startDate!,
                          endDate: endDate,
                        );
                        setState(() {
                          _jobExperiences.add(newJob);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Add Experience',
                        style: TextStyle(
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
          );
        },
      ),
    );
  }

  // ==================== DOCUMENTS TAB ====================
  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Supporting Documents',
            icon: Icons.folder_outlined,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Upload your resume/CV and certificates to stand out to employers.',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildUploadButton(
                      icon: Icons.picture_as_pdf,
                      label: 'Upload PDF',
                      color: Colors.red,
                      onTap: _uploadPDF,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildUploadButton(
                      icon: Icons.image,
                      label: 'Upload Image',
                      color: Colors.blue,
                      onTap: _uploadImage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Demo button for testing/emulator
              InkWell(
                onTap: _addDemoDocuments,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Demo Resume & Certificate',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_uploadingDocument) ...[
                const SizedBox(height: 20),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Uploading document...'),
                    ],
                  ),
                ),
              ],
              if (_documents.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Uploaded Documents (${_documents.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F1E3C),
                  ),
                ),
                const SizedBox(height: 12),
                ..._documents.asMap().entries.map((entry) {
                  final index = entry.key;
                  final doc = entry.value;
                  return _buildDocumentCard(doc, index);
                }),
              ],
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _uploadingDocument ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(SupportingDocument doc, int index) {
    final isImage = doc.type == 'image';
    return Container(
      margin: EdgeInsets.only(top: index > 0 ? 10 : 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isImage ? Colors.blue.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isImage ? Icons.image : Icons.picture_as_pdf,
              color: isImage ? Colors.blue : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM dd, yyyy').format(doc.uploadedAt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
            onPressed: () => _deleteDocument(index),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      await _uploadFile(File(file.path!), file.name, 'pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadImage() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (result == null) return;

      final fileName = result.name;
      await _uploadFile(File(result.path), fileName, 'image');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadFile(File file, String fileName, String type) async {
    setState(() => _uploadingDocument = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_documents')
          .child(uid)
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final newDoc = SupportingDocument(
        name: fileName,
        url: downloadUrl,
        type: type,
        uploadedAt: DateTime.now(),
      );

      setState(() {
        _documents.add(newDoc);
        _uploadingDocument = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _uploadingDocument = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteDocument(int index) async {
    final doc = _documents[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${doc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete from Firebase Storage
      final ref = FirebaseStorage.instance.refFromURL(doc.url);
      await ref.delete();

      setState(() {
        _documents.removeAt(index);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // If storage delete fails, still remove from list
      setState(() {
        _documents.removeAt(index);
      });
    }
  }

  /// Add demo documents for testing purposes
  void _addDemoDocuments() {
    // Using publicly accessible sample PDF and image URLs
    final demoResume = SupportingDocument(
      name:
          'Resume_${_nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim().replaceAll(' ', '_') : 'Student'}.pdf',
      url:
          'https://www.w3.org/WAI/WCAG21/Techniques/pdf/img/table-word.jpg', // Demo placeholder
      type: 'pdf',
      uploadedAt: DateTime.now().subtract(const Duration(days: 7)),
    );

    final demoCertificate = SupportingDocument(
      name: 'Certificate_Flutter_Development.pdf',
      url:
          'https://www.w3.org/WAI/WCAG21/Techniques/pdf/img/table-word.jpg', // Demo placeholder
      type: 'pdf',
      uploadedAt: DateTime.now().subtract(const Duration(days: 14)),
    );

    final demoProfilePhoto = SupportingDocument(
      name: 'Profile_Photo.jpg',
      url:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', // Sample profile image
      type: 'image',
      uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
    );

    setState(() {
      // Only add if not already present
      if (!_documents.any((d) => d.name.contains('Resume'))) {
        _documents.add(demoResume);
      }
      if (!_documents.any((d) => d.name.contains('Certificate'))) {
        _documents.add(demoCertificate);
      }
      if (!_documents.any((d) => d.name.contains('Profile_Photo'))) {
        _documents.add(demoProfilePhoto);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo documents added! Click Save to store them.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ==================== REUSABLE WIDGETS ====================
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? headerAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1E3C).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF0F1E3C), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F1E3C),
                    ),
                  ),
                ),
                if (headerAction != null) headerAction,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      style: TextStyle(color: enabled ? Colors.black87 : Colors.grey.shade600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F1E3C), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: !enabled,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    IconData? prefixIcon,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F1E3C), width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    IconData? prefixIcon,
    required Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(2000, 1, 1),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value != null
                  ? DateFormat('dd MMM yyyy').format(value)
                  : 'Select date',
              style: TextStyle(
                color: value != null ? Colors.black87 : Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}
