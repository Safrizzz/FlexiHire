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
  final List<String> skillsRequired; // Required skills for the job

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
    this.skillsRequired = const [],
    List<JobApplication>? applicants,
    List<JobApplication>? hires,
  })  : applicants = applicants ?? [],
        hires = hires ?? [];
}
