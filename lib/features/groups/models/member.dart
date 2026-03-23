class Member {
  final String email;
  final String? name;
  final String role; // 'admin' or 'member'

  Member({
    required this.email,
    this.name,
    this.role = 'member',
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      email: map['email'] ?? '',
      name: map['name'],
      role: map['role'] ?? 'member',
    );
  }
}
