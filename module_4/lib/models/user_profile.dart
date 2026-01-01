class UserProfile {
  final String id;
  final String displayName;
  final String photoUrl;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.photoUrl,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      displayName: data['displayName']?.toString() ?? '',
      photoUrl: data['photoUrl']?.toString() ?? '',
    );
  }
}
