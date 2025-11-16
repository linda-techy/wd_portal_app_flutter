class TeamMemberSimple {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;

  TeamMemberSimple({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
  });

  factory TeamMemberSimple.fromJson(Map<String, dynamic> json) {
    return TeamMemberSimple(
      id: json['id'] as int,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'email': email,
    };
  }
}
