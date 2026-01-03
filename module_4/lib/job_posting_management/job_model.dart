import 'job_application.dart';
import 'micro_shift.dart';

class Job {
  final String id;
  final String title;
  final String company;
  final String location;
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
    required this.payRate,
    required this.description,
    this.microShifts = const [],
    this.status = 'open',
    List<JobApplication>? applicants,
    List<JobApplication>? hires,
  })  : applicants = applicants ?? [],
        hires = hires ?? [];
}
