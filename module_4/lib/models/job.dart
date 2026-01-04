import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';

class Job {
  final String id;
  final String title;
  final String description;
  final String location;
  final GeoLocation? geoLocation; // Coordinates for distance calculation
  final num pay;
  final DateTime startDate;
  final DateTime endDate;
  final String? startTime; // Format: "HH:mm"
  final String? endTime; // Format: "HH:mm"
  final List<String> skillsRequired;
  final String employerId;
  final DateTime createdAt;
  final String status;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    this.geoLocation,
    required this.pay,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    required this.skillsRequired,
    required this.employerId,
    required this.createdAt,
    this.status = 'open',
  });

  factory Job.fromMap(String id, Map<String, dynamic> data) {
    DateTime toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    num toNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
      return 0;
    }

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

    return Job(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      geoLocation: geoLoc,
      pay: toNum(data['pay']),
      startDate: toDate(data['startDate']),
      endDate: toDate(data['endDate']),
      startTime: data['startTime']?.toString(),
      endTime: data['endTime']?.toString(),
      skillsRequired: List<String>.from(
        (data['skillsRequired'] ?? []).map((e) => e.toString()),
      ),
      employerId: data['employerId'] ?? '',
      createdAt: toDate(data['createdAt']),
      status: data['status']?.toString() ?? 'open',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      if (geoLocation != null) 'geoLocation': geoLocation!.toMap(),
      'pay': pay,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      'skillsRequired': skillsRequired,
      'employerId': employerId,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  /// Create a copy of this job with updated fields
  Job copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    GeoLocation? geoLocation,
    num? pay,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    List<String>? skillsRequired,
    String? employerId,
    DateTime? createdAt,
    String? status,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      geoLocation: geoLocation ?? this.geoLocation,
      pay: pay ?? this.pay,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      skillsRequired: skillsRequired ?? this.skillsRequired,
      employerId: employerId ?? this.employerId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
