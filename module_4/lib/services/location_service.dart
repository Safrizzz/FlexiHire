import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// A simple class to hold latitude and longitude coordinates
class GeoLocation {
  final double latitude;
  final double longitude;

  const GeoLocation({required this.latitude, required this.longitude});

  factory GeoLocation.fromMap(Map<String, dynamic> data) {
    return GeoLocation(
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  bool get isValid => latitude != 0.0 || longitude != 0.0;

  @override
  String toString() => 'GeoLocation($latitude, $longitude)';
}

/// Service for handling location-related operations
class LocationService {
  // Using OpenStreetMap Nominatim API for free geocoding (no API key required)
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(GeoLocation from, GeoLocation to) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double lat1Rad = _toRadians(from.latitude);
    final double lat2Rad = _toRadians(to.latitude);
    final double deltaLat = _toRadians(to.latitude - from.latitude);
    final double deltaLon = _toRadians(to.longitude - from.longitude);

    final double a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Convert an address string to coordinates using OpenStreetMap Nominatim
  /// Returns null if geocoding fails
  static Future<GeoLocation?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;

    try {
      final encodedAddress = Uri.encodeComponent(address.trim());
      final url = Uri.parse(
        '$_nominatimBaseUrl/search?q=$encodedAddress&format=json&limit=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FlexiHire App', // Required by Nominatim ToS
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (results.isNotEmpty) {
          final result = results[0];
          final lat = double.tryParse(result['lat']?.toString() ?? '');
          final lon = double.tryParse(result['lon']?.toString() ?? '');

          if (lat != null && lon != null) {
            return GeoLocation(latitude: lat, longitude: lon);
          }
        }
      }
    } catch (e) {
      // Handle network errors silently
      print('Geocoding error: $e');
    }

    return null;
  }

  /// Convert coordinates to an address string (reverse geocoding)
  /// Returns null if reverse geocoding fails
  static Future<String?> reverseGeocode(GeoLocation location) async {
    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FlexiHire App', // Required by Nominatim ToS
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['display_name']?.toString();
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }

    return null;
  }

  /// Search for places matching a query
  /// Returns a list of place suggestions
  static Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (query.trim().length < 3) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      final url = Uri.parse(
        '$_nominatimBaseUrl/search?q=$encodedQuery&format=json&limit=5&countrycodes=my', // Limit to Malaysia
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlexiHire App'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        return results.map((r) => PlaceSuggestion.fromJson(r)).toList();
      }
    } catch (e) {
      print('Place search error: $e');
    }

    return [];
  }
}

/// A place suggestion from the geocoding API
class PlaceSuggestion {
  final String displayName;
  final GeoLocation location;

  PlaceSuggestion({required this.displayName, required this.location});

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      displayName: json['display_name']?.toString() ?? '',
      location: GeoLocation(
        latitude: double.tryParse(json['lat']?.toString() ?? '') ?? 0.0,
        longitude: double.tryParse(json['lon']?.toString() ?? '') ?? 0.0,
      ),
    );
  }
}
