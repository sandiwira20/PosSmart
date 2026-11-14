class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? photoUrl;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isKasir => role == 'kasir';

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'kasir',
      photoUrl: map['photo_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role,
    'photo_url': photoUrl,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'UserModel(uid: $uid, name: $name, role: $role)';
}
