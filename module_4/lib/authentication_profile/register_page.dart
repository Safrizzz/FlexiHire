import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  UserRole _selectedRole = UserRole.student;
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      _showDialog('Invalid Input', 'Please complete all fields correctly.');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      _showDialog('Password Mismatch', 'Password and Confirm Password do not match.');
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'displayName': user.email?.split('@').first ?? '',
          'photoUrl': user.photoURL ?? '',
          'phone': '',
          'location': '',
          'skills': [],
          'role': userRoleToString(_selectedRole),
        }, SetOptions(merge: true));
      }
      _showDialog('Registration Successful', 'Your account has been created. You can now login.', onOk: () {
        Navigator.of(context).maybePop();
      });
    } on FirebaseAuthException catch (e) {
      _showDialog('Registration Failed', e.message ?? 'Unknown error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDialog(String title, String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onOk?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = const InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: Color(0xFF1F2A44)),
      hintStyle: TextStyle(color: Color(0xFF6B7280)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF7C3AED), width: 2),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    );
    const fieldTextStyle = TextStyle(color: Color(0xFF0F1E3C), fontSize: 16);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Register', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F1E3C))),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  items: const [
                    DropdownMenuItem(value: UserRole.student, child: Text('Student')),
                    DropdownMenuItem(value: UserRole.employer, child: Text('Employer')),
                  ],
                  onChanged: (v) => setState(() => _selectedRole = v ?? UserRole.student),
                  decoration: inputDecoration.copyWith(labelText: 'Role'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: fieldTextStyle,
                  decoration: inputDecoration.copyWith(labelText: 'Email'),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Please enter email';
                    final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
                    if (!emailOk) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  style: fieldTextStyle,
                  decoration: inputDecoration.copyWith(labelText: 'Password'),
                  validator: (v) {
                    final s = v ?? '';
                    if (s.isEmpty) return 'Please enter password';
                    if (s.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  style: fieldTextStyle,
                  decoration: inputDecoration.copyWith(labelText: 'Confirm Password'),
                  validator: (v) {
                    final s = v ?? '';
                    if (s.isEmpty) return 'Please confirm password';
                    if (s != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
