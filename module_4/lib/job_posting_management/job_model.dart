import 'job_application.dart';
import 'micro_shift.dart';
import '../services/location_service.dart';

class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final GeoLocation? geoLocation; // Coordinates for distance calculation
  final double payRate;
  final String description;
  final List<MicroShift> microShifts;
  final String status;

  List<JobApplication> applicants;
  List<JobApplication> hires;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    this.geoLocation,
    required this.payRate,
    required this.description,
    this.microShifts = const [],
    this.status = 'open',
    List<JobApplication>? applicants,
    List<JobApplication>? hires,
  })  : applicants = applicants ?? [],
        hires = hires ?? [];
}
