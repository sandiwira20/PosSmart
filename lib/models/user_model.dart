class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' or 'kasir'
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isKasir => role.toLowerCase() == 'kasir';

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'kasir',
      avatarUrl: map['avatarUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
    };
  }
}
