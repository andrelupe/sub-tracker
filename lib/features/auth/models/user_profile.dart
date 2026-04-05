/// User profile returned by the API.
///
/// Contains the user's identity and role information.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }

  final String id;
  final String email;
  final String role;

  /// Whether this user has the Admin role.
  bool get isAdmin => role == 'Admin';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
    };
  }
}
