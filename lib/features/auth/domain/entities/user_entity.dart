class UserEntity {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory UserEntity.empty() {
    return UserEntity(id: '', name: '', email: '', createdAt: DateTime.now());
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;
}
