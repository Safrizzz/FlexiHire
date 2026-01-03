import 'job_model.dart';
import 'job_application.dart';
import 'applicant.dart';
import 'job_status.dart';
import 'micro_shift.dart';

List<Job> dummyJobs = [
  Job(
    id: '1',
    title: 'Software Developer',
    company: 'TechNova Sdn Bhd',
    description: 'Develop and maintain mobile and web applications.',
    location: 'Kuala Lumpur',
    payRate: 7.0,

    microShifts: [
      MicroShift(
        start: DateTime(2026, 1, 12, 9, 0),
        end: DateTime(2026, 1, 12, 13, 0),
      ),
      MicroShift(
        start: DateTime(2026, 1, 14, 14, 0),
        end: DateTime(2026, 1, 14, 18, 0),
      ),
      MicroShift(
        start: DateTime(2026, 1, 16, 10, 0),
        end: DateTime(2026, 1, 16, 16, 0),
      ),
    ],

    applicants: [
      JobApplication(
        applicant: Applicant(
          name: 'Aina Sofea',
          email: 'aina@gmail.com',
        ),
        status: JobStatus.applied,
      ),
      JobApplication(
        applicant: Applicant(
          name: 'Haziq Firdaus',
          email: 'haziq@gmail.com',
        ),
        status: JobStatus.applied,
      ),
    ],
  ),
];
