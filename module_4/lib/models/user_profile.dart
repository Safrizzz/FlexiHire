import 'user_role.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final String phone;
  final String location;
  final List<String> skills;
  final UserRole role;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.phone,
    required this.location,
    required this.skills,
    required this.role,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      email: data['email']?.toString() ?? '',
      displayName: data['displayName']?.toString() ?? '',
      photoUrl: data['photoUrl']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      skills: List<String>.from((data['skills'] ?? []).map((e) => e.toString())),
      role: parseUserRole(data['role']?.toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phone': phone,
      'location': location,
      'skills': skills,
      'role': userRoleToString(role),
    };
  }
}
