// =============================================================================
// DEVICE REQUESTS - Modelos de solicitudes de autorización de equipos (admin)
// =============================================================================

/// Acción reportada por el evento WS `device_request_changed`
enum DeviceRequestAction {
  created('created'),
  updated('updated');

  const DeviceRequestAction(this.wire);
  final String wire;

  static DeviceRequestAction? fromWire(Object? value) {
    if (value is! String) return null;
    for (final action in DeviceRequestAction.values) {
      if (action.wire == value) return action;
    }
    return null;
  }
}

/// Estado de una solicitud de autorización de equipo
enum DeviceRequestStatus {
  pendingOtp('pending_otp', 'Pendiente OTP'),
  pendingAdmin('pending_admin', 'Pendiente admin'),
  approved('approved', 'Aprobada'),
  rejected('rejected', 'Rechazada'),
  consumed('consumed', 'Consumida'),
  expired('expired', 'Expirada');

  const DeviceRequestStatus(this.wire, this.label);
  final String wire;
  final String label;

  static DeviceRequestStatus? fromWire(Object? value) {
    if (value is! String) return null;
    for (final status in DeviceRequestStatus.values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

/// Alcance de aprobación de un equipo
enum DeviceApprovalScope {
  personal('personal', 'Personal'),
  public('public', 'Público');

  const DeviceApprovalScope(this.wire, this.label);
  final String wire;
  final String label;

  static DeviceApprovalScope? fromWire(Object? value) {
    if (value is! String) return null;
    for (final scope in DeviceApprovalScope.values) {
      if (scope.wire == value) return scope;
    }
    return null;
  }
}

/// Evento WS `device_request_changed`.
///
/// Es una señal de invalidación: NO contiene datos sensibles ni es la fuente
/// de verdad. El contenido real siempre se consulta vía REST.
class DeviceRequestChangedEvent {
  final DeviceRequestAction action;
  final int requestId;
  final DeviceRequestStatus status;

  const DeviceRequestChangedEvent({
    required this.action,
    required this.requestId,
    required this.status,
  });

  /// Parsea el payload validando tipos y valores.
  /// Devuelve `null` ante cualquier payload inválido (nunca lanza).
  static DeviceRequestChangedEvent? tryParse(Map<String, dynamic> json) {
    if (json['type'] != 'device_request_changed') return null;

    final action = DeviceRequestAction.fromWire(json['action']);
    final status = DeviceRequestStatus.fromWire(json['status']);
    final requestId = json['request_id'];

    if (action == null || status == null || requestId is! int) return null;

    return DeviceRequestChangedEvent(
      action: action,
      requestId: requestId,
      status: status,
    );
  }

  @override
  String toString() =>
      'DeviceRequestChangedEvent(action: ${action.wire}, '
      'requestId: $requestId, status: ${status.wire})';
}

/// Solicitud de autorización de equipo (fuente de verdad: REST)
/// GET /api/v1/admin/device-requests/
class DeviceRequest {
  final int id;
  final String username;
  final String userFullName;
  final String deviceId;
  final String deviceName;
  final String clientType; // 'web' | 'api'
  final DeviceRequestStatus? status;
  final String statusRaw;
  final DeviceApprovalScope? approvalScope;
  final String? resolvedByUsername;
  final DateTime? resolvedAt;
  final int attempts;
  final String? ipAddress;
  final String userAgent;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? consumedAt;

  const DeviceRequest({
    required this.id,
    required this.username,
    this.userFullName = '',
    this.deviceId = '',
    this.deviceName = '',
    this.clientType = '',
    this.status,
    this.statusRaw = '',
    this.approvalScope,
    this.resolvedByUsername,
    this.resolvedAt,
    this.attempts = 0,
    this.ipAddress,
    this.userAgent = '',
    this.expiresAt,
    this.createdAt,
    this.consumedAt,
  });

  factory DeviceRequest.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String? ?? '';
    return DeviceRequest(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      userFullName: json['user_full_name'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      clientType: json['client_type'] as String? ?? '',
      status: DeviceRequestStatus.fromWire(statusRaw),
      statusRaw: statusRaw,
      approvalScope: DeviceApprovalScope.fromWire(json['approval_scope']),
      resolvedByUsername: json['resolved_by_username'] as String?,
      resolvedAt: _parseDate(json['resolved_at']),
      attempts: json['attempts'] as int? ?? 0,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String? ?? '',
      expiresAt: _parseDate(json['expires_at']),
      createdAt: _parseDate(json['created_at']),
      consumedAt: _parseDate(json['consumed_at']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  /// Nombre a mostrar del solicitante
  String get displayUser =>
      userFullName.trim().isNotEmpty ? userFullName : username;

  /// Nombre a mostrar del dispositivo
  String get displayDevice {
    if (deviceName.trim().isNotEmpty) return deviceName;
    if (deviceId.length > 12) return '${deviceId.substring(0, 12)}…';
    return deviceId.isEmpty ? 'Sin nombre' : deviceId;
  }

  /// Etiqueta del estado (usa el valor crudo si el backend envía uno nuevo)
  String get statusLabel => status?.label ?? statusRaw;

  bool get isPendingAdmin => status == DeviceRequestStatus.pendingAdmin;
}

/// Equipo de confianza registrado (listado admin)
/// GET /api/v1/admin/equipos-confianza/
class EquipoConfianza {
  final int id;
  final String nombre;
  final bool isGlobal;
  final String? userUsername;
  final String? userNombre;
  final bool activo;
  final bool vigente;
  final int sesionesActivas;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? lastUsed;

  const EquipoConfianza({
    required this.id,
    this.nombre = '',
    this.isGlobal = false,
    this.userUsername,
    this.userNombre,
    this.activo = false,
    this.vigente = false,
    this.sesionesActivas = 0,
    this.createdAt,
    this.expiresAt,
    this.lastUsed,
  });

  factory EquipoConfianza.fromJson(Map<String, dynamic> json) {
    return EquipoConfianza(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      isGlobal: json['is_global'] as bool? ?? false,
      userUsername: json['user_username'] as String?,
      userNombre: json['user_nombre'] as String?,
      activo: json['activo'] as bool? ?? false,
      vigente: json['vigente'] as bool? ?? false,
      sesionesActivas: json['sesiones_activas'] as int? ?? 0,
      createdAt: DeviceRequest._parseDate(json['created_at']),
      expiresAt: DeviceRequest._parseDate(json['expires_at']),
      lastUsed: DeviceRequest._parseDate(json['last_used']),
    );
  }
}
