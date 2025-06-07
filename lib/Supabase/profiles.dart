class Profile {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final bool isApproved;

  Profile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isApproved,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['name'],
      email: json['email'],
      role: json['role'],
      isApproved: json['is_approved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': fullName,
      'email': email,
      'role': role,
      'is_approved': isApproved,
    };
  }
}
