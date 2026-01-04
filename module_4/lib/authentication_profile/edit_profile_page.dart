import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  UserRole _role = UserRole.student;
  bool _loading = true;

  // Location fields
  String _locationAddress = '';
  GeoLocation? _geoLocation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final p = await _service.getUserProfile(uid);
    _nameCtrl.text = p?.displayName ?? '';
    _phoneCtrl.text = p?.phone ?? '';
    _locationAddress = p?.location ?? '';
    _geoLocation = p?.geoLocation;
    _skillsCtrl.text = (p?.skills ?? []).join(', ');
    _role = p?.role ?? UserRole.student;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = UserProfile(
      id: user.uid,
      email: user.email ?? '',
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
    );
    await _service.updateUserProfile(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Please enter your name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Please enter phone'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Location picker with geo-coding
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
                                  'Location verified - distance calculations enabled',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade700,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Add your location to see job distances',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _skillsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Skills (comma-separated)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F1E3C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _save,
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
