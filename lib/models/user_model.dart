// ============================================================================
// USER MODEL - MODELO DE USUARIO CON MÓDULOS Y ASISTENCIA
// ============================================================================

/// Representa la asistencia activa del usuario
class AsistenciaActiva {
  final int id;
  final String fechaHoraEntrada;
  final int? zonaTrabajoId;
  final String? zonaTrabajoNombre;
  final String? zonaTrabajoTipo; // PUERTO, ALMACEN, ALMACEN-PDI, OFICINA
  final int? naveId;
  final String? naveNombre;
  final String? naveRubro; // FPR, SIC, etc.
  final String? naveCategoriaRubro; // AUTOS, GRANELES
  final bool activo;
  final String? horasTrabajadasDisplay;

  const AsistenciaActiva({
    required this.id,
    required this.fechaHoraEntrada,
    this.zonaTrabajoId,
    this.zonaTrabajoNombre,
    this.zonaTrabajoTipo,
    this.naveId,
    this.naveNombre,
    this.naveRubro,
    this.naveCategoriaRubro,
    this.activo = true,
    this.horasTrabajadasDisplay,
  });

  factory AsistenciaActiva.fromJson(Map<String, dynamic> json) {
    // Extraer datos de zona de trabajo
    int? zonaId;
    String? zonaNombre;
    String? zonaTipo;
    if (json['zona_trabajo'] != null) {
      if (json['zona_trabajo'] is Map) {
        zonaId = json['zona_trabajo']['id'];
        zonaNombre = json['zona_trabajo']['zona'] ?? json['zona_trabajo']['nombre'] ?? json['zona_trabajo']['value'];
        zonaTipo = json['zona_trabajo']['tipo'];
      } else if (json['zona_trabajo'] is String) {
        zonaNombre = json['zona_trabajo'];
      }
    }
    // Fallback: leer campos planos (datos restaurados desde storage)
    zonaId ??= json['zona_trabajo_id'] as int?;
    zonaTipo ??= json['zona_trabajo_tipo'] as String?;

    // Extraer datos de nave
    int? naveId;
    String? naveNombre;
    String? naveRubro;
    String? naveCategoriaRubro;
    if (json['nave'] != null) {
      if (json['nave'] is Map) {
        naveId = json['nave']['id'];
        naveNombre = json['nave']['nombre'] ?? json['nave']['value'];
        naveRubro = json['nave']['rubro'];
        naveCategoriaRubro = json['nave']['categoria_rubro'];
      } else if (json['nave'] is String) {
        naveNombre = json['nave'];
      }
    }
    // Fallback: leer campos planos (datos restaurados desde storage)
    naveId ??= json['nave_id'] as int?;
    naveRubro ??= json['nave_rubro'] as String?;
    naveCategoriaRubro ??= json['nave_categoria_rubro'] as String?;

    return AsistenciaActiva(
      id: json['id'] ?? 0,
      fechaHoraEntrada: json['fecha_hora_entrada'] ?? '',
      zonaTrabajoId: zonaId,
      zonaTrabajoNombre: zonaNombre,
      zonaTrabajoTipo: zonaTipo,
      naveId: naveId,
      naveNombre: naveNombre,
      naveRubro: naveRubro,
      naveCategoriaRubro: naveCategoriaRubro,
      activo: json['activo'] ?? true,
      horasTrabajadasDisplay: json['horas_trabajadas_display'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fecha_hora_entrada': fechaHoraEntrada,
    'zona_trabajo': zonaTrabajoNombre,
    'zona_trabajo_id': zonaTrabajoId,
    'zona_trabajo_tipo': zonaTrabajoTipo,
    'nave': naveNombre,
    'nave_id': naveId,
    'nave_rubro': naveRubro,
    'nave_categoria_rubro': naveCategoriaRubro,
    'activo': activo,
    'horas_trabajadas_display': horasTrabajadasDisplay,
  };

  /// Helper para obtener descripción del contexto de trabajo
  String get contextoTrabajo {
    final parts = <String>[];
    if (zonaTrabajoNombre != null) parts.add(zonaTrabajoNombre!);
    if (naveCategoriaRubro != null) parts.add(naveCategoriaRubro!);
    return parts.join(' - ');
  }
}

/// Representa un módulo/aplicación disponible para el usuario
class ModuleAccess {
  final String id;
  final String name;
  final String icon;
  final bool isEnabled;
  final bool requiresAsistencia;

  const ModuleAccess({
    required this.id,
    required this.name,
    required this.icon,
    this.isEnabled = true,
    this.requiresAsistencia = false,
  });

  factory ModuleAccess.fromJson(Map<String, dynamic> json) {
    return ModuleAccess(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'apps',
      isEnabled: json['is_enabled'] ?? true,
      requiresAsistencia: json['requires_asistencia'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'is_enabled': isEnabled,
    'requires_asistencia': requiresAsistencia,
  };

  @override
  String toString() => 'ModuleAccess(id: $id, name: $name, requiresAsistencia: $requiresAsistencia)';
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
  final AsistenciaActiva? ultimaAsistenciaActiva; // Asistencia activa actual

  UserModel({
    required this.id,
    required this.username,
    this.email = '',
    this.firstName = '',
    this.lastName = '',
    this.isSuperuser = false,
    List<String>? groups,
    List<ModuleAccess>? availableModules,
    this.ultimaAsistenciaActiva,
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

    // Parsear asistencia activa si viene del backend
    AsistenciaActiva? asistencia;
    if (json['ultima_asistencia_activa'] != null) {
      asistencia = AsistenciaActiva.fromJson(json['ultima_asistencia_activa']);
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
      ultimaAsistenciaActiva: asistencia,
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
    'ultima_asistencia_activa': ultimaAsistenciaActiva?.toJson(),
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
    AsistenciaActiva? ultimaAsistenciaActiva,
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
      ultimaAsistenciaActiva: ultimaAsistenciaActiva ?? this.ultimaAsistenciaActiva,
    );
  }

  // ===========================================================================
  // HELPERS DE ASISTENCIA
  // ===========================================================================

  /// Verifica si el usuario tiene una asistencia activa
  bool get hasActiveAsistencia =>
      ultimaAsistenciaActiva != null && ultimaAsistenciaActiva!.activo;

  /// Verifica si un módulo específico está bloqueado por falta de asistencia
  bool isModuleBlocked(String moduleId) {
    final module = availableModules.firstWhere(
      (m) => m.id == moduleId,
      orElse: () => const ModuleAccess(id: '', name: '', icon: ''),
    );

    // Si el módulo requiere asistencia y no hay asistencia activa, está bloqueado
    return module.requiresAsistencia && !hasActiveAsistencia;
  }

  /// Verifica si el usuario puede acceder a un módulo
  bool canAccessModule(String moduleId) {
    return hasModuleAccess(moduleId) && !isModuleBlocked(moduleId);
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
  /// Solo superusers y grupo GESTORES COORDINACION AUTOS pueden acceder
  bool get hasAutosAccess =>
      isSuperuser ||
      groups.any((g) => ['GESTORES COORDINACION AUTOS', 'COORDINACION AUTOS'].contains(g));

  /// Usuario tiene acceso al módulo de graneles
  bool get hasGranosAccess =>
      isSuperuser ||
      groups.any((g) => ['GRANOS', 'GRANELES', 'COORDINACION GRANELES'].contains(g));

  /// Usuario tiene acceso al módulo de casos y documentos
  /// Solo superusers y coordinadores
  bool get hasCasosAccess =>
      isSuperuser ||
      groups.any((g) => [
        'CASOS Y DOCUMENTOS',
        'COORDINACION AUTOS',
        'COORDINACION GRANELES',
        'ADMINISTRACION',
      ].contains(g));

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

    // Casos - Superusers y coordinadores
    if (hasCasosAccess) {
      modules.add(const ModuleAccess(
        id: 'casos',
        name: 'Casos',
        icon: 'folder',
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
