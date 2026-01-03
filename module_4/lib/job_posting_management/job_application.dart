import 'applicant.dart';
import 'job_status.dart';

class JobApplication {
  final Applicant applicant;
  JobStatus status;

  JobApplication({
    required this.applicant,
    this.status = JobStatus.applied,
  });
}
