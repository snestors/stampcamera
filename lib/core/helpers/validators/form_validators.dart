// ============================================================================
// 🔍 VALIDADORES DE FORMULARIOS CENTRALIZADOS
// ============================================================================

class FormValidators {
  // ============================================================================
  // VIN VALIDATION
  // ============================================================================
  
  static String? validateVin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El VIN es requerido';
    }
    
    final cleanVin = value.trim().toUpperCase();
    
    // Longitud correcta
    if (cleanVin.length != 17) {
      return 'El VIN debe tener 17 caracteres';
    }
    
    // Caracteres válidos (sin I, O, Q)
    final validChars = RegExp(r'^[A-HJ-NPR-Z0-9]+$');
    if (!validChars.hasMatch(cleanVin)) {
      return 'El VIN contiene caracteres inválidos';
    }
    
    // Verificar dígito de control (posición 9)
    if (!_validateVinCheckDigit(cleanVin)) {
      return 'El VIN tiene un dígito de control inválido';
    }
    
    return null;
  }
  
  static bool _validateVinCheckDigit(String vin) {
    const weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2];
    const values = {
      'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8,
      'J': 1, 'K': 2, 'L': 3, 'M': 4, 'N': 5, 'P': 7, 'R': 9, 'S': 2,
      'T': 3, 'U': 4, 'V': 5, 'W': 6, 'X': 7, 'Y': 8, 'Z': 9,
      '0': 0, '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9
    };
    
    int sum = 0;
    for (int i = 0; i < 17; i++) {
      if (i == 8) continue; // Skip check digit position
      sum += (values[vin[i]] ?? 0) * weights[i];
    }
    
    final remainder = sum % 11;
    final checkDigit = remainder == 10 ? 'X' : remainder.toString();
    
    return vin[8] == checkDigit;
  }
  
  // ============================================================================
  // BASIC VALIDATIONS
  // ============================================================================
  
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }
    return null;
  }
  
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }
    
    return null;
  }
  
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido';
    }
    
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    final cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Ingresa un teléfono válido';
    }
    
    return null;
  }
  
  // ============================================================================
  // NUMERIC VALIDATIONS
  // ============================================================================
  
  static String? validateNumber(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }
    
    if (double.tryParse(value.trim()) == null) {
      return 'Ingresa un número válido';
    }
    
    return null;
  }
  
  static String? validatePositiveNumber(String? value, {String? fieldName}) {
    final numberValidation = validateNumber(value, fieldName: fieldName);
    if (numberValidation != null) return numberValidation;
    
    final number = double.parse(value!.trim());
    if (number <= 0) {
      return '${fieldName ?? 'Este valor'} debe ser positivo';
    }
    
    return null;
  }
  
  static String? validateRange(String? value, {
    required double min,
    required double max,
    String? fieldName,
  }) {
    final numberValidation = validateNumber(value, fieldName: fieldName);
    if (numberValidation != null) return numberValidation;
    
    final number = double.parse(value!.trim());
    if (number < min || number > max) {
      return '${fieldName ?? 'Este valor'} debe estar entre $min y $max';
    }
    
    return null;
  }
  
  // ============================================================================
  // STRING VALIDATIONS
  // ============================================================================
  
  static String? validateMinLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }
    
    if (value.trim().length < minLength) {
      return '${fieldName ?? 'Este campo'} debe tener al menos $minLength caracteres';
    }
    
    return null;
  }
  
  static String? validateMaxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.trim().length > maxLength) {
      return '${fieldName ?? 'Este campo'} no debe exceder $maxLength caracteres';
    }
    
    return null;
  }
  
  static String? validateAlphaNumeric(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Este campo'} es requerido';
    }
    
    final alphaNumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!alphaNumericRegex.hasMatch(value.trim())) {
      return '${fieldName ?? 'Este campo'} solo puede contener letras y números';
    }
    
    return null;
  }
  
  // ============================================================================
  // COMBINED VALIDATIONS
  // ============================================================================
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
      return 'La contraseña debe contener al menos una letra y un número';
    }
    
    return null;
  }
  
  static String? validateConfirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    
    if (value != originalPassword) {
      return 'Las contraseñas no coinciden';
    }
    
    return null;
  }
  
  // ============================================================================
  // BUSINESS SPECIFIC VALIDATIONS
  // ============================================================================
  
  static String? validateSerieNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El número de serie es requerido';
    }
    
    final cleanSerie = value.trim().toUpperCase();
    
    // Longitud entre 6 y 20 caracteres
    if (cleanSerie.length < 6 || cleanSerie.length > 20) {
      return 'El número de serie debe tener entre 6 y 20 caracteres';
    }
    
    // Solo letras y números
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleanSerie)) {
      return 'El número de serie solo puede contener letras y números';
    }
    
    return null;
  }
  
  static String? validatePlateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La placa es requerida';
    }
    
    final cleanPlate = value.trim().toUpperCase();
    
    // Formato peruano: 3 letras + 3 números (ABC-123)
    if (!RegExp(r'^[A-Z]{3}-?[0-9]{3}$').hasMatch(cleanPlate)) {
      return 'Formato de placa inválido (ej: ABC-123)';
    }
    
    return null;
  }
  
  static String? validateContainerNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El número de contenedor es requerido';
    }
    
    final cleanContainer = value.trim().toUpperCase();
    
    // ISO 6346: 4 letras + 7 números
    if (!RegExp(r'^[A-Z]{4}[0-9]{7}$').hasMatch(cleanContainer)) {
      return 'Formato de contenedor inválido (ej: ABCD1234567)';
    }
    
    return null;
  }
}