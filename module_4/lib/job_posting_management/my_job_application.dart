import 'job_status.dart';
import 'micro_shift.dart';

class MyJobApplication {
  final String jobTitle;
  final String company;
  final String location;
  final double payRate;
  final String description;
  final JobStatus status;

  final List<MicroShift> microShifts;

  MyJobApplication({
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.payRate,
    required this.description,
    required this.status,
    this.microShifts = const [],
  });
}
