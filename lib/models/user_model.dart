class UserModel {
  final String id;
  final String name;
  final String email;
  final String passwordHash;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        passwordHash: map['password_hash'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password_hash': passwordHash,
      };
}
