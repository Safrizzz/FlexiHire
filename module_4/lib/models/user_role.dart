enum UserRole { student, employer }

UserRole parseUserRole(String? value) {
  switch (value) {
    case 'employer':
      return UserRole.employer;
    case 'student':
    default:
      return UserRole.student;
  }
}

String userRoleToString(UserRole role) {
  return role == UserRole.employer ? 'employer' : 'student';
}

