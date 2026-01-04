import 'user_role.dart';
import '../services/location_service.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final String phone;
  final String location;
  final GeoLocation? geoLocation; // Coordinates for distance calculation
  final List<String> skills;
  final UserRole role;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.phone,
    required this.location,
    this.geoLocation,
    required this.skills,
    required this.role,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    // Parse geo location if available
    GeoLocation? geoLoc;
    if (data['geoLocation'] != null && data['geoLocation'] is Map) {
      geoLoc = GeoLocation.fromMap(
        Map<String, dynamic>.from(data['geoLocation']),
      );
    } else if (data['latitude'] != null && data['longitude'] != null) {
      // Fallback for flat structure
      geoLoc = GeoLocation(
        latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      );
    }

    return UserProfile(
      id: id,
      email: data['email']?.toString() ?? '',
      displayName: data['displayName']?.toString() ?? '',
      photoUrl: data['photoUrl']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      geoLocation: geoLoc,
      skills: List<String>.from(
        (data['skills'] ?? []).map((e) => e.toString()),
      ),
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
      if (geoLocation != null) 'geoLocation': geoLocation!.toMap(),
      'skills': skills,
      'role': userRoleToString(role),
    };
  }

  /// Create a copy of this profile with updated fields
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phone,
    String? location,
    GeoLocation? geoLocation,
    List<String>? skills,
    UserRole? role,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      geoLocation: geoLocation ?? this.geoLocation,
      skills: skills ?? this.skills,
      role: role ?? this.role,
    );
  }
}
