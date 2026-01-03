import 'job_status.dart';
import 'my_job_application.dart';
import 'micro_shift.dart';

final List<MyJobApplication> myJobsDummy = [
  MyJobApplication(
    jobTitle: 'Cafe Assistant',
    company: 'Kopi Penang',
    location: 'George Town',
    payRate: 8.0,
    description: 'Assist cafe operations',
    status: JobStatus.applied,
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
  ),
  MyJobApplication(
    jobTitle: 'Retail Associate',
    company: 'ShopEasy',
    location: 'Kuala Lumpur',
    payRate: 10.0,
    description: 'Assist customers and manage inventory',
    status: JobStatus.hired,
    microShifts: [
      MicroShift(
        start: DateTime(2026, 1, 15, 11, 0),
        end: DateTime(2026, 1, 15, 17, 0),
      ),
      MicroShift(
        start: DateTime(2026, 1, 17, 12, 0),
        end: DateTime(2026, 1, 17, 18, 0),
      ),
    ],
  ),
  MyJobApplication(
    jobTitle: 'Event Staff',
    company: 'EventPro',
    location: 'Petaling Jaya',
    payRate: 12.0,
    description: 'Support event setup and guest services',
    status: JobStatus.rejected,
  ),
];
