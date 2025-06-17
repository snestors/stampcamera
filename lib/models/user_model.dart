class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final bool isSuperuser;
  final List<String> groups;

  UserModel({
    required this.id,
    required this.username,
    this.email = '',
    this.firstName = '',
    this.lastName = '',
    this.isSuperuser = false,
    List<String>? groups,
  }) : groups = groups ?? [];

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      isSuperuser: json['is_superuser'] ?? false,
      groups: List<String>.from(json['groups'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'is_superuser': isSuperuser,
        'groups': groups,
      };

  bool get isInspector => groups.any((g) => ['PUERTO', 'ALMACEN', 'OFICINA'].contains(g));
  bool get isCliente => groups.contains('CLIENTE');
}
