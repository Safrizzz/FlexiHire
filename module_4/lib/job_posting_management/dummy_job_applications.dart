import 'job_application.dart';
import 'applicant.dart';
import 'job_status.dart';

final List<JobApplication> dummyJobApplications = [
  JobApplication(
    applicant: Applicant(
      name: 'Alice Tan',
      email: 'alice@example.com',
    ),
    status: JobStatus.applied,
  ),
  JobApplication(
    applicant: Applicant(
      name: 'Bob Lee',
      email: 'bob@example.com',
    ),
    status: JobStatus.hired,
  ),
  JobApplication(
    applicant: Applicant(
      name: 'Charlie Lim',
      email: 'charlie@example.com',
    ),
    status: JobStatus.rejected,
  ),
];
