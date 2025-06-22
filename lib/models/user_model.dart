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

  // ✅ AGREGAR: copyWith completo
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    bool? isSuperuser,
    List<String>? groups,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isSuperuser: isSuperuser ?? this.isSuperuser,
      groups: groups ?? this.groups,
    );
  }

  bool get isInspector =>
      groups.any((g) => ['PUERTO', 'ALMACEN', 'OFICINA'].contains(g));
  bool get isCliente => groups.contains('CLIENTE');

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, firstName: $firstName, lastName: $lastName, groups: $groups)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.isSuperuser == isSuperuser &&
        _listEquals(other.groups, groups);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      username,
      email,
      firstName,
      lastName,
      isSuperuser,
      Object.hashAll(groups),
    );
  }

  // Helper para comparar listas
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
