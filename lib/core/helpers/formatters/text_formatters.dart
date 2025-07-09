// ============================================================================
// 📝 FORMATEADORES DE TEXTO CENTRALIZADOS
// ============================================================================

class TextFormatters {
  // ============================================================================
  // CASE FORMATTERS
  // ============================================================================
  
  /// Convertir a título: "juan pérez" → "Juan Pérez"
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
  
  /// Convertir a sentence case: "HELLO WORLD" → "Hello world"
  static String toSentenceCase(String text) {
    if (text.isEmpty) return text;
    
    final lowerText = text.toLowerCase();
    return lowerText[0].toUpperCase() + lowerText.substring(1);
  }
  
  /// Limpiar espacios: "  hello   world  " → "hello world"
  static String cleanSpaces(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
  
  /// Remover acentos: "José María" → "Jose Maria"
  static String removeAccents(String text) {
    const accents = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ā': 'a', 'ã': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e', 'ē': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i', 'ī': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'ō': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', 'ū': 'u',
      'ñ': 'n', 'ç': 'c',
      'Á': 'A', 'À': 'A', 'Ä': 'A', 'Â': 'A', 'Ā': 'A', 'Ã': 'A',
      'É': 'E', 'È': 'E', 'Ë': 'E', 'Ê': 'E', 'Ē': 'E',
      'Í': 'I', 'Ì': 'I', 'Ï': 'I', 'Î': 'I', 'Ī': 'I',
      'Ó': 'O', 'Ò': 'O', 'Ö': 'O', 'Ô': 'O', 'Ō': 'O', 'Õ': 'O',
      'Ú': 'U', 'Ù': 'U', 'Ü': 'U', 'Û': 'U', 'Ū': 'U',
      'Ñ': 'N', 'Ç': 'C',
    };
    
    String result = text;
    accents.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    
    return result;
  }
  
  // ============================================================================
  // BUSINESS FORMATTERS
  // ============================================================================
  
  /// Formatear VIN: "abc123def456" → "ABC123DEF456"
  static String formatVin(String vin) {
    return cleanSpaces(vin).toUpperCase();
  }
  
  /// Formatear número de serie: "  abc123  " → "ABC123"
  static String formatSerieNumber(String serie) {
    return cleanSpaces(serie).toUpperCase();
  }
  
  /// Formatear placa: "abc123" → "ABC-123"
  static String formatPlate(String plate) {
    final clean = cleanSpaces(plate).toUpperCase().replaceAll('-', '');
    if (clean.length == 6) {
      return '${clean.substring(0, 3)}-${clean.substring(3)}';
    }
    return clean;
  }
  
  /// Formatear contenedor: "abcd1234567" → "ABCD1234567"
  static String formatContainer(String container) {
    return cleanSpaces(container).toUpperCase();
  }
  
  /// Formatear marca de vehículo: "toyota" → "TOYOTA"
  static String formatBrand(String brand) {
    return cleanSpaces(brand).toUpperCase();
  }
  
  /// Formatear modelo de vehículo: "corolla xli" → "Corolla XLI"
  static String formatModel(String model) {
    return toTitleCase(cleanSpaces(model));
  }
  
  /// Formatear color: "azul oscuro" → "AZUL OSCURO"
  static String formatColor(String color) {
    return cleanSpaces(color).toUpperCase();
  }
  
  /// Formatear nombre de persona: "JUAN CARLOS pérez" → "Juan Carlos Pérez"
  static String formatPersonName(String name) {
    return toTitleCase(cleanSpaces(name));
  }
  
  /// Formatear nombre de empresa: "a&g ajustadores sac" → "A&G Ajustadores SAC"
  static String formatCompanyName(String company) {
    return toTitleCase(cleanSpaces(company));
  }
  
  // ============================================================================
  // PHONE FORMATTERS
  // ============================================================================
  
  /// Formatear teléfono peruano: "987654321" → "+51 987 654 321"
  static String formatPeruvianPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (clean.length == 9) {
      return '+51 ${clean.substring(0, 3)} ${clean.substring(3, 6)} ${clean.substring(6)}';
    } else if (clean.length == 11 && clean.startsWith('51')) {
      return '+${clean.substring(0, 2)} ${clean.substring(2, 5)} ${clean.substring(5, 8)} ${clean.substring(8)}';
    }
    
    return phone;
  }
  
  /// Limpiar teléfono: "+51 987 654 321" → "987654321"
  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }
  
  // ============================================================================
  // TRUNCATE & ELLIPSIS
  // ============================================================================
  
  /// Truncar texto con elipsis: "Very long text" → "Very long..."
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    
    final truncated = text.substring(0, maxLength - ellipsis.length);
    return '$truncated$ellipsis';
  }
  
  /// Truncar por palabras: "Very long text here" → "Very long text..."
  static String truncateWords(String text, int maxWords, {String ellipsis = '...'}) {
    final words = text.split(' ');
    if (words.length <= maxWords) return text;
    
    final truncated = words.take(maxWords).join(' ');
    return '$truncated$ellipsis';
  }
  
  // ============================================================================
  // MASKS & PATTERNS
  // ============================================================================
  
  /// Aplicar máscara de RUC: "20123456789" → "20-123456789"
  static String formatRuc(String ruc) {
    final clean = ruc.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 11) {
      return '${clean.substring(0, 2)}-${clean.substring(2)}';
    }
    return ruc;
  }
  
  /// Aplicar máscara de DNI: "12345678" → "12.345.678"
  static String formatDni(String dni) {
    final clean = dni.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 8) {
      return '${clean.substring(0, 2)}.${clean.substring(2, 5)}.${clean.substring(5)}';
    }
    return dni;
  }
  
  /// Aplicar máscara de tarjeta de crédito: "1234567890123456" → "1234 **** **** 3456"
  static String formatCreditCard(String card, {bool maskMiddle = true}) {
    final clean = card.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 16) {
      if (maskMiddle) {
        return '${clean.substring(0, 4)} **** **** ${clean.substring(12)}';
      } else {
        return '${clean.substring(0, 4)} ${clean.substring(4, 8)} ${clean.substring(8, 12)} ${clean.substring(12)}';
      }
    }
    return card;
  }
  
  // ============================================================================
  // SEARCH & HIGHLIGHTING
  // ============================================================================
  
  /// Normalizar texto para búsqueda: "José María" → "jose maria"
  static String normalizeForSearch(String text) {
    return removeAccents(text.toLowerCase().trim());
  }
  
  /// Verificar si contiene término de búsqueda
  static bool containsSearchTerm(String text, String searchTerm) {
    return normalizeForSearch(text).contains(normalizeForSearch(searchTerm));
  }
  
  /// Extraer matches de búsqueda
  static List<String> extractSearchMatches(String text, String searchTerm) {
    final normalized = normalizeForSearch(text);
    final normalizedTerm = normalizeForSearch(searchTerm);
    
    if (normalizedTerm.isEmpty) return [];
    
    final matches = <String>[];
    final words = normalized.split(' ');
    
    for (final word in words) {
      if (word.contains(normalizedTerm)) {
        matches.add(word);
      }
    }
    
    return matches;
  }
  
  // ============================================================================
  // CURRENCY & NUMBERS
  // ============================================================================
  
  /// Formatear moneda peruana: "1234.56" → "S/ 1,234.56"
  static String formatCurrency(double amount, {String symbol = 'S/'}) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    
    // Agregar separadores de miles
    String integerPart = parts[0];
    String formattedInteger = '';
    
    for (int i = integerPart.length - 1; i >= 0; i--) {
      formattedInteger = integerPart[i] + formattedInteger;
      if ((integerPart.length - i) % 3 == 0 && i > 0) {
        formattedInteger = ',$formattedInteger';
      }
    }
    
    return '$symbol $formattedInteger.${parts[1]}';
  }
  
  /// Formatear número con separadores: "1234567" → "1,234,567"
  static String formatNumber(int number) {
    final str = number.toString();
    String formatted = '';
    
    for (int i = str.length - 1; i >= 0; i--) {
      formatted = str[i] + formatted;
      if ((str.length - i) % 3 == 0 && i > 0) {
        formatted = ',$formatted';
      }
    }
    
    return formatted;
  }
  
  // ============================================================================
  // FILE & PATH FORMATTERS
  // ============================================================================
  
  /// Formatear nombre de archivo: "Mi Archivo.pdf" → "mi_archivo.pdf"
  static String formatFileName(String fileName) {
    return removeAccents(fileName.toLowerCase())
        .replaceAll(RegExp(r'[^\w\-_\.]'), '_')
        .replaceAll(RegExp(r'_{2,}'), '_');
  }
  
  /// Extraer extensión de archivo: "archivo.pdf" → "pdf"
  static String getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
  
  /// Formatear tamaño de archivo: "1048576" → "1.0 MB"
  static String formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
  
  // ============================================================================
  // VALIDATION HELPERS
  // ============================================================================
  
  /// Verificar si es solo números
  static bool isNumeric(String text) {
    return RegExp(r'^[0-9]+$').hasMatch(text);
  }
  
  /// Verificar si es solo letras
  static bool isAlpha(String text) {
    return RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(text);
  }
  
  /// Verificar si es alfanumérico
  static bool isAlphaNumeric(String text) {
    return RegExp(r'^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(text);
  }
  
  /// Verificar si contiene solo caracteres válidos para VIN
  static bool isValidVinChars(String text) {
    return RegExp(r'^[A-HJ-NPR-Z0-9]+$').hasMatch(text);
  }
  
  // ============================================================================
  // SLUG GENERATION
  // ============================================================================
  
  /// Generar slug: "José María Pérez" → "jose-maria-perez"
  static String generateSlug(String text) {
    return removeAccents(text.toLowerCase())
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[-\s]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
  
  /// Generar ID único: "Mi Producto" → "mi-producto-abc123"
  static String generateUniqueId(String text) {
    final slug = generateSlug(text);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final shortId = timestamp.substring(timestamp.length - 6);
    return '$slug-$shortId';
  }
}