import 'user_role.dart';
import '../services/location_service.dart';

/// Model for job experience entry
class JobExperience {
  final String title;
  final DateTime startDate;
  final DateTime? endDate;

  JobExperience({required this.title, required this.startDate, this.endDate});

  factory JobExperience.fromMap(Map<String, dynamic> data) {
    return JobExperience(
      title: data['title']?.toString() ?? '',
      startDate: data['startDate'] != null
          ? DateTime.parse(data['startDate'].toString())
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? DateTime.parse(data['endDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
    };
  }
}

/// Model for supporting document
class SupportingDocument {
  final String name;
  final String url;
  final String type; // 'pdf' or 'image'
  final DateTime uploadedAt;

  SupportingDocument({
    required this.name,
    required this.url,
    required this.type,
    required this.uploadedAt,
  });

  factory SupportingDocument.fromMap(Map<String, dynamic> data) {
    return SupportingDocument(
      name: data['name']?.toString() ?? '',
      url: data['url']?.toString() ?? '',
      type: data['type']?.toString() ?? 'pdf',
      uploadedAt: data['uploadedAt'] != null
          ? DateTime.parse(data['uploadedAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'type': type,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

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
  final String bankAccountNumber; // For student payment transfers
  final String bankName; // Bank name for payment transfers
  final String accountHolderName; // Account holder name for bank

  // New personal information fields
  final String gender;
  final String ethnicity;
  final DateTime? dateOfBirth;
  final String languageProficiency;

  // Job experience
  final List<JobExperience> jobExperience;

  // Supporting documents
  final List<SupportingDocument> documents;

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
    this.bankAccountNumber = '',
    this.bankName = '',
    this.accountHolderName = '',
    this.gender = '',
    this.ethnicity = '',
    this.dateOfBirth,
    this.languageProficiency = '',
    this.jobExperience = const [],
    this.documents = const [],
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

    // Parse job experience
    List<JobExperience> jobExp = [];
    if (data['jobExperience'] != null && data['jobExperience'] is List) {
      jobExp = (data['jobExperience'] as List)
          .map((e) => JobExperience.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    // Parse documents
    List<SupportingDocument> docs = [];
    if (data['documents'] != null && data['documents'] is List) {
      docs = (data['documents'] as List)
          .map((e) => SupportingDocument.fromMap(Map<String, dynamic>.from(e)))
          .toList();
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
      bankAccountNumber: data['bankAccountNumber']?.toString() ?? '',
      bankName: data['bankName']?.toString() ?? '',
      accountHolderName: data['accountHolderName']?.toString() ?? '',
      gender: data['gender']?.toString() ?? '',
      ethnicity: data['ethnicity']?.toString() ?? '',
      dateOfBirth: data['dateOfBirth'] != null
          ? DateTime.tryParse(data['dateOfBirth'].toString())
          : null,
      languageProficiency: data['languageProficiency']?.toString() ?? '',
      jobExperience: jobExp,
      documents: docs,
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
      'bankAccountNumber': bankAccountNumber,
      'bankName': bankName,
      'accountHolderName': accountHolderName,
      'gender': gender,
      'ethnicity': ethnicity,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      'languageProficiency': languageProficiency,
      'jobExperience': jobExperience.map((e) => e.toMap()).toList(),
      'documents': documents.map((e) => e.toMap()).toList(),
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
    String? bankAccountNumber,
    String? bankName,
    String? accountHolderName,
    String? gender,
    String? ethnicity,
    DateTime? dateOfBirth,
    String? languageProficiency,
    List<JobExperience>? jobExperience,
    List<SupportingDocument>? documents,
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
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      gender: gender ?? this.gender,
      ethnicity: ethnicity ?? this.ethnicity,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      languageProficiency: languageProficiency ?? this.languageProficiency,
      jobExperience: jobExperience ?? this.jobExperience,
      documents: documents ?? this.documents,
    );
  }
}
