// ============================================================================
// 👤 USER MODEL - MODELO DE USUARIO CON MÓDULOS DISPONIBLES
// ============================================================================

/// Representa un módulo/aplicación disponible para el usuario
class ModuleAccess {
  final String id;
  final String name;
  final String icon;
  final bool isEnabled;

  const ModuleAccess({
    required this.id,
    required this.name,
    required this.icon,
    this.isEnabled = true,
  });

  factory ModuleAccess.fromJson(Map<String, dynamic> json) {
    return ModuleAccess(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'apps',
      isEnabled: json['is_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'is_enabled': isEnabled,
  };

  @override
  String toString() => 'ModuleAccess(id: $id, name: $name)';
}

/// Modelo principal del usuario
class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final bool isSuperuser;
  final List<String> groups;
  final List<ModuleAccess>? _availableModules; // Desde el backend (opcional)

  UserModel({
    required this.id,
    required this.username,
    this.email = '',
    this.firstName = '',
    this.lastName = '',
    this.isSuperuser = false,
    List<String>? groups,
    List<ModuleAccess>? availableModules,
  }) : groups = groups ?? [],
       _availableModules = availableModules;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parsear módulos si vienen del backend
    List<ModuleAccess>? modules;
    if (json['available_modules'] != null) {
      modules = (json['available_modules'] as List)
          .map((m) => ModuleAccess.fromJson(m))
          .toList();
    }

    return UserModel(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      isSuperuser: json['is_superuser'] ?? false,
      groups: List<String>.from(json['groups'] ?? []),
      availableModules: modules,
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
    'available_modules': _availableModules?.map((m) => m.toJson()).toList(),
  };

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    bool? isSuperuser,
    List<String>? groups,
    List<ModuleAccess>? availableModules,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isSuperuser: isSuperuser ?? this.isSuperuser,
      groups: groups ?? this.groups,
      availableModules: availableModules ?? _availableModules,
    );
  }

  // ===========================================================================
  // HELPERS DE ROL (basados en grupos)
  // ===========================================================================

  /// Usuario es inspector (tiene rol de trabajo en campo)
  bool get isInspector =>
      groups.any((g) => ['PUERTO', 'ALMACEN', 'OFICINA', 'AUTOS'].contains(g));

  /// Usuario es cliente externo
  bool get isCliente => groups.contains('CLIENTE');

  /// Usuario tiene acceso al módulo de autos
  bool get hasAutosAccess =>
      isSuperuser ||
      groups.any((g) => ['AUTOS', 'PUERTO', 'ALMACEN', 'OFICINA', 'COORDINACION AUTOS'].contains(g));

  /// Usuario tiene acceso al módulo de granos (futuro)
  bool get hasGranosAccess =>
      isSuperuser || groups.contains('GRANOS');

  /// Usuario tiene acceso a asistencia
  bool get hasAsistenciaAccess =>
      isSuperuser || !isCliente;

  // ===========================================================================
  // MÓDULOS DISPONIBLES
  // ===========================================================================

  /// Obtiene los módulos disponibles para este usuario
  /// Si el backend envía available_modules, usa esos.
  /// Si no, calcula basándose en los grupos.
  List<ModuleAccess> get availableModules {
    // Si el backend envió módulos, usarlos
    if (_availableModules != null && _availableModules.isNotEmpty) {
      return _availableModules;
    }

    // Calcular módulos basado en grupos
    return _calculateModulesFromGroups();
  }

  /// Calcula los módulos disponibles basándose en los grupos del usuario
  List<ModuleAccess> _calculateModulesFromGroups() {
    final modules = <ModuleAccess>[];

    // Cámara - Disponible para todos los usuarios autenticados
    modules.add(const ModuleAccess(
      id: 'camera',
      name: 'Cámara',
      icon: 'camera_alt',
    ));

    // Asistencia - Todos excepto CLIENTE
    if (hasAsistenciaAccess) {
      modules.add(const ModuleAccess(
        id: 'asistencia',
        name: 'Asistencia',
        icon: 'access_time',
      ));
    }

    // Autos - AUTOS, PUERTO, ALMACEN, OFICINA, superuser
    if (hasAutosAccess) {
      modules.add(const ModuleAccess(
        id: 'autos',
        name: 'Autos',
        icon: 'directions_car',
      ));
    }

    // Granos - Solo usuarios con grupo GRANOS o superuser
    if (hasGranosAccess) {
      modules.add(const ModuleAccess(
        id: 'granos',
        name: 'Granos',
        icon: 'agriculture',
      ));
    }

    return modules;
  }

  /// Verifica si el usuario tiene acceso a un módulo específico
  bool hasModuleAccess(String moduleId) {
    return availableModules.any((m) => m.id == moduleId && m.isEnabled);
  }

  // ===========================================================================
  // UTILIDADES
  // ===========================================================================

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, '
        'firstName: $firstName, lastName: $lastName, groups: $groups, '
        'modules: ${availableModules.map((m) => m.id).toList()})';
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

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
