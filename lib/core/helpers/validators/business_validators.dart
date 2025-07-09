// ============================================================================
// 🏢 VALIDADORES DE LÓGICA DE NEGOCIO
// ============================================================================

class BusinessValidators {
  // ============================================================================
  // INSPECTION VALIDATIONS
  // ============================================================================
  
  static String? validateInspectionCondition(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La condición de inspección es requerida';
    }
    
    const validConditions = [
      'PUERTO', 'RECEPCION', 'ALMACEN', 'PDI', 'PRE-PDI', 'ARRIBO'
    ];
    
    if (!validConditions.contains(value.toUpperCase())) {
      return 'Condición de inspección inválida';
    }
    
    return null;
  }
  
  static String? validateSeverity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La severidad es requerida';
    }
    
    const validSeverities = ['LEVE', 'MEDIO', 'GRAVE'];
    
    if (!validSeverities.any((severity) => value.toUpperCase().contains(severity))) {
      return 'Severidad inválida';
    }
    
    return null;
  }
  
  static String? validateDamageType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El tipo de daño es requerido';
    }
    
    // Validaciones específicas para tipos de daño
    if (value.trim().length < 3) {
      return 'El tipo de daño debe tener al menos 3 caracteres';
    }
    
    return null;
  }
  
  // ============================================================================
  // VEHICLE VALIDATIONS
  // ============================================================================
  
  static String? validateVehicleBrand(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La marca del vehículo es requerida';
    }
    
    // Lista de marcas válidas (puedes expandir según necesidad)
    const validBrands = [
      'TOYOTA', 'HONDA', 'NISSAN', 'MAZDA', 'MITSUBISHI', 'HYUNDAI', 'KIA',
      'CHEVROLET', 'FORD', 'VOLKSWAGEN', 'BMW', 'MERCEDES-BENZ', 'AUDI',
      'HINO', 'FUSO', 'T-KING', 'UD TRUCKS', 'JAC', 'KOMATSU'
    ];
    
    final upperBrand = value.trim().toUpperCase();
    if (!validBrands.contains(upperBrand)) {
      return 'Marca de vehículo no reconocida';
    }
    
    return null;
  }
  
  static String? validateVehicleModel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El modelo del vehículo es requerido';
    }
    
    if (value.trim().length < 2) {
      return 'El modelo debe tener al menos 2 caracteres';
    }
    
    if (value.trim().length > 50) {
      return 'El modelo no puede exceder 50 caracteres';
    }
    
    return null;
  }
  
  static String? validateVehicleYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El año del vehículo es requerido';
    }
    
    final year = int.tryParse(value.trim());
    if (year == null) {
      return 'Ingresa un año válido';
    }
    
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear + 1) {
      return 'El año debe estar entre 1900 y ${currentYear + 1}';
    }
    
    return null;
  }
  
  static String? validateVehicleColor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El color del vehículo es requerido';
    }
    
    // Colores válidos comunes
    const validColors = [
      'BLANCO', 'NEGRO', 'GRIS', 'PLATA', 'AZUL', 'ROJO', 'VERDE',
      'AMARILLO', 'NARANJA', 'CAFE', 'DORADO', 'BEIGE', 'VIOLETA'
    ];
    
    final upperColor = value.trim().toUpperCase();
    if (!validColors.contains(upperColor)) {
      return 'Color no reconocido';
    }
    
    return null;
  }
  
  // ============================================================================
  // LOCATION VALIDATIONS
  // ============================================================================
  
  static String? validateZone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La zona es requerida';
    }
    
    if (value.trim().length < 3) {
      return 'La zona debe tener al menos 3 caracteres';
    }
    
    return null;
  }
  
  static String? validateBlock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El bloque es requerido';
    }
    
    if (value.trim().length < 2) {
      return 'El bloque debe tener al menos 2 caracteres';
    }
    
    return null;
  }
  
  static String? validateRow(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Row is optional
    }
    
    final row = int.tryParse(value.trim());
    if (row == null) {
      return 'La fila debe ser un número';
    }
    
    if (row < 1 || row > 999) {
      return 'La fila debe estar entre 1 y 999';
    }
    
    return null;
  }
  
  static String? validatePosition(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Position is optional
    }
    
    final position = int.tryParse(value.trim());
    if (position == null) {
      return 'La posición debe ser un número';
    }
    
    if (position < 1 || position > 999) {
      return 'La posición debe estar entre 1 y 999';
    }
    
    return null;
  }
  
  // ============================================================================
  // DOCUMENT VALIDATIONS
  // ============================================================================
  
  static String? validateInvoiceNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El número de factura es requerido';
    }
    
    // Formato típico: letras y números
    if (!RegExp(r'^[A-Z0-9-]+$').hasMatch(value.trim().toUpperCase())) {
      return 'Formato de factura inválido';
    }
    
    if (value.trim().length < 5 || value.trim().length > 20) {
      return 'El número de factura debe tener entre 5 y 20 caracteres';
    }
    
    return null;
  }
  
  static String? validateBillOfLading(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El Bill of Lading es requerido';
    }
    
    if (value.trim().length < 8 || value.trim().length > 20) {
      return 'El BL debe tener entre 8 y 20 caracteres';
    }
    
    return null;
  }
  
  static String? validateShipName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de la nave es requerido';
    }
    
    if (value.trim().length < 3) {
      return 'El nombre de la nave debe tener al menos 3 caracteres';
    }
    
    if (value.trim().length > 100) {
      return 'El nombre de la nave no puede exceder 100 caracteres';
    }
    
    return null;
  }
  
  // ============================================================================
  // ATTENDANCE VALIDATIONS
  // ============================================================================
  
  static String? validateAttendanceType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El tipo de asistencia es requerido';
    }
    
    const validTypes = ['ENTRADA', 'SALIDA'];
    
    if (!validTypes.contains(value.toUpperCase())) {
      return 'Tipo de asistencia inválido';
    }
    
    return null;
  }
  
  static String? validateWorkShift(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El turno de trabajo es requerido';
    }
    
    const validShifts = ['MAÑANA', 'TARDE', 'NOCHE'];
    
    if (!validShifts.contains(value.toUpperCase())) {
      return 'Turno de trabajo inválido';
    }
    
    return null;
  }
  
  // ============================================================================
  // COMPLEX BUSINESS RULES
  // ============================================================================
  
  static String? validateInspectionComplete(Map<String, dynamic> inspection) {
    // Validar que una inspección esté completa
    if (inspection['vin'] == null || inspection['vin'].toString().isEmpty) {
      return 'El VIN es requerido para completar la inspección';
    }
    
    if (inspection['condicion'] == null || inspection['condicion'].toString().isEmpty) {
      return 'La condición es requerida para completar la inspección';
    }
    
    if (inspection['zona_inspeccion'] == null) {
      return 'La zona de inspección es requerida';
    }
    
    // Validaciones específicas por condición
    final condicion = inspection['condicion'].toString().toUpperCase();
    
    if (condicion == 'PUERTO') {
      if (inspection['bloque'] == null) {
        return 'El bloque es requerido para condición PUERTO';
      }
    }
    
    if (condicion == 'ALMACEN') {
      if (inspection['contenedor'] == null) {
        return 'El contenedor es requerido para condición ALMACEN';
      }
    }
    
    return null;
  }
  
  static String? validateDamageReport(Map<String, dynamic> damage) {
    // Validar que un reporte de daño esté completo
    if (damage['tipo_dano'] == null) {
      return 'El tipo de daño es requerido';
    }
    
    if (damage['area_dano'] == null) {
      return 'El área del daño es requerida';
    }
    
    if (damage['severidad'] == null) {
      return 'La severidad del daño es requerida';
    }
    
    if (damage['descripcion'] == null || damage['descripcion'].toString().trim().isEmpty) {
      return 'La descripción del daño es requerida';
    }
    
    return null;
  }
  
  static bool isValidForPort(String condicion) {
    return ['PUERTO', 'RECEPCION', 'ARRIBO'].contains(condicion.toUpperCase());
  }
  
  static bool isValidForWarehouse(String condicion) {
    return ['ALMACEN', 'PDI', 'PRE-PDI'].contains(condicion.toUpperCase());
  }
  
  static bool requiresContainer(String condicion) {
    return condicion.toUpperCase() == 'ALMACEN';
  }
  
  static bool requiresBlock(String condicion) {
    return condicion.toUpperCase() == 'PUERTO';
  }
}