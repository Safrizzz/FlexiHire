import 'package:cloud_firestore/cloud_firestore.dart';

class MicroShift {
  final DateTime start;
  final DateTime end;

  final int capacity; // default 1 staff per shift
  int filled;         // how many already hired

  MicroShift({
    required this.start,
    required this.end,
    this.capacity = 1,
    this.filled = 0,
  });

  bool get isFull => filled >= capacity;

  /// Returns just the date (without time) for comparison
  DateTime get date => DateTime(start.year, start.month, start.day);

  String toDisplay() {
    final date =
        '${start.day.toString().padLeft(2, '0')} ${_m(start.month)} ${start.year}';
    final s =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final e =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$date • $s–$e';
  }

  String toShortDisplay() {
    final s =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final e =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$s–$e';
  }

  static String _m(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }

  /// Convert to a Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'capacity': capacity,
      'filled': filled,
    };
  }

  /// Create a MicroShift from Firebase data
  factory MicroShift.fromMap(Map<String, dynamic> data) {
    DateTime toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return MicroShift(
      start: toDate(data['start']),
      end: toDate(data['end']),
      capacity: (data['capacity'] as num?)?.toInt() ?? 1,
      filled: (data['filled'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MicroShift &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
