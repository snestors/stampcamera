// ============================================================================
// 📅 FORMATEADORES DE FECHA Y HORA CENTRALIZADOS
// Todas las fechas se muestran en America/Lima (-05:00) independientemente
// del timezone del dispositivo.
// ============================================================================

import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Timezone fijo America/Lima para toda la app
late final tz.Location _limaTz;
bool _tzInitialized = false;

/// Inicializar timezone — llamar una vez en main.dart
void initTimezone() {
  if (_tzInitialized) return;
  tz_data.initializeTimeZones();
  _limaTz = tz.getLocation('America/Lima');
  _tzInitialized = true;
}

/// Convierte cualquier DateTime a America/Lima
tz.TZDateTime toLima(DateTime dt) {
  if (!_tzInitialized) initTimezone();
  return tz.TZDateTime.from(dt, _limaTz);
}

/// Crea un DateTime en zona Lima con componentes específicos
/// Uso: después de date/time pickers para combinar fecha+hora en Lima
tz.TZDateTime makeLima(int year, int month, int day, [int hour = 0, int minute = 0]) {
  if (!_tzInitialized) initTimezone();
  return tz.TZDateTime(_limaTz, year, month, day, hour, minute);
}

/// DateTime.now() en Lima
tz.TZDateTime nowLima() {
  if (!_tzInitialized) initTimezone();
  return tz.TZDateTime.now(_limaTz);
}

class DateFormatters {
  // ============================================================================
  // FORMATTERS ESTÁNDAR
  // ============================================================================
  
  /// Formato de fecha completa: "28/06/2025 15:30" (siempre en Lima)
  static String toFullFormat(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(toLima(date));
  }

  /// Formato de fecha: "28/06/2025" (siempre en Lima)
  static String toDateFormat(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(toLima(date));
  }

  /// Formato de hora: "15:30" (siempre en Lima)
  static String toTimeFormat(DateTime date) {
    return DateFormat('HH:mm').format(toLima(date));
  }
  
  /// Formato de hora con AM/PM: "3:30 PM"
  static String toTime12Format(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
  
  /// Formato corto: "28/06"
  static String toShortDate(DateTime date) {
    return DateFormat('dd/MM').format(date);
  }
  
  /// Formato largo: "Lunes, 28 de Junio de 2025"
  static String toLongFormat(DateTime date) {
    return DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'es_ES').format(date);
  }
  
  /// Formato médium: "28 Jun 2025"
  static String toMediumFormat(DateTime date) {
    return DateFormat('dd MMM yyyy', 'es_ES').format(date);
  }
  
  // ============================================================================
  // FORMATTERS DE CONVENIENCIA
  // ============================================================================
  
  /// Fecha y hora actual en formato completo
  static String formattedNow() {
    return toFullFormat(nowLima());
  }

  /// Solo fecha actual
  static String dateNow() {
    return toDateFormat(nowLima());
  }

  /// Solo hora actual
  static String timeNow() {
    return toTimeFormat(nowLima());
  }
  
  // ============================================================================
  // FORMATTERS RELATIVOS
  // ============================================================================
  
  /// Formato relativo: "Hace 5 minutos", "Ayer", "Hoy", etc.
  static String toRelativeFormat(DateTime date) {
    final now = nowLima();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Ahora';
        } else {
          return 'Hace ${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}';
        }
      } else {
        return 'Hace ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
      }
    } else if (difference.inDays == 1) {
      return 'Ayer a las ${toTimeFormat(date)}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
    } else {
      return toDateFormat(date);
    }
  }
  
  /// Formato para mostrar en listas: "Hoy 15:30", "Ayer 14:20", "28/06 16:45"
  static String toListFormat(DateTime date) {
    final now = nowLima();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy ${toTimeFormat(date)}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${toTimeFormat(date)}';
    } else if (difference.inDays < 7) {
      return '${DateFormat('EEEE', 'es_ES').format(date)} ${toTimeFormat(date)}';
    } else {
      return '${toShortDate(date)} ${toTimeFormat(date)}';
    }
  }
  
  // ============================================================================
  // FORMATTERS ESPECÍFICOS DEL NEGOCIO
  // ============================================================================
  
  /// Formato para registros de inspección: "08/07/2025 22:15"
  static String toInspectionFormat(DateTime date) {
    return toFullFormat(date);
  }
  
  /// Formato para asistencias: "15:30"
  static String toAttendanceFormat(DateTime date) {
    return toTimeFormat(date);
  }
  
  /// Formato para reportes: "Lunes 28/06/2025"
  static String toReportFormat(DateTime date) {
    return '${DateFormat('EEEE', 'es_ES').format(date)} ${toDateFormat(date)}';
  }
  
  /// Formato para archivos: "20250628_1530"
  static String toFileNameFormat(DateTime date) {
    return DateFormat('yyyyMMdd_HHmm').format(date);
  }
  
  // ============================================================================
  // FORMATTERS DE RANGO
  // ============================================================================
  
  /// Formato de rango de fechas: "28/06 - 30/06/2025"
  static String toRangeFormat(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${DateFormat('dd').format(start)} - ${toDateFormat(end)}';
    } else if (start.year == end.year) {
      return '${DateFormat('dd/MM').format(start)} - ${toDateFormat(end)}';
    } else {
      return '${toDateFormat(start)} - ${toDateFormat(end)}';
    }
  }
  
  /// Formato de rango de tiempo: "09:00 - 17:30"
  static String toTimeRangeFormat(DateTime start, DateTime end) {
    return '${toTimeFormat(start)} - ${toTimeFormat(end)}';
  }
  
  // ============================================================================
  // PARSERS
  // ============================================================================
  
  /// Parsear fecha desde string "28/06/2025 15:30"
  static DateTime? parseFullFormat(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  /// Parsear fecha desde string "28/06/2025"
  static DateTime? parseDateFormat(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  /// Parsear hora desde string "15:30"
  static DateTime? parseTimeFormat(String timeString) {
    try {
      final today = nowLima();
      final time = DateFormat('HH:mm').parse(timeString);
      return DateTime(today.year, today.month, today.day, time.hour, time.minute);
    } catch (e) {
      return null;
    }
  }
  
  // ============================================================================
  // VALIDATORS
  // ============================================================================
  
  /// Validar si una fecha es válida
  static bool isValidDate(String dateString) {
    return parseDateFormat(dateString) != null;
  }
  
  /// Validar si una fecha y hora es válida
  static bool isValidDateTime(String dateTimeString) {
    return parseFullFormat(dateTimeString) != null;
  }
  
  /// Validar si una hora es válida
  static bool isValidTime(String timeString) {
    return parseTimeFormat(timeString) != null;
  }
  
  // ============================================================================
  // HELPERS DE COMPARACIÓN
  // ============================================================================
  
  /// Verificar si una fecha es hoy
  static bool isToday(DateTime date) {
    final now = nowLima();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  /// Verificar si una fecha es ayer
  static bool isYesterday(DateTime date) {
    final yesterday = nowLima().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }
  
  /// Verificar si una fecha es en el futuro
  static bool isFuture(DateTime date) {
    return date.isAfter(nowLima());
  }
  
  /// Verificar si una fecha es en el pasado
  static bool isPast(DateTime date) {
    return date.isBefore(nowLima());
  }
  
  /// Verificar si una fecha está en la semana actual
  static bool isThisWeek(DateTime date) {
    final now = nowLima();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }
  
  /// Verificar si una fecha está en el mes actual
  static bool isThisMonth(DateTime date) {
    final now = nowLima();
    return date.year == now.year && date.month == now.month;
  }
  
  // ============================================================================
  // HELPERS DE CÁLCULO
  // ============================================================================
  
  /// Calcular edad en años
  static int calculateAge(DateTime birthDate) {
    final now = nowLima();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }
  
  /// Calcular días laborables entre dos fechas
  static int calculateWorkingDays(DateTime start, DateTime end) {
    int workingDays = 0;
    DateTime current = start;
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    return workingDays;
  }
  
  /// Obtener el inicio del día
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// Obtener el final del día
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
  
  /// Obtener el inicio de la semana (lunes)
  static DateTime startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
  
  /// Obtener el final de la semana (domingo)
  static DateTime endOfWeek(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }
  
  /// Obtener el inicio del mes
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// Obtener el final del mes
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  // ============================================================================
  // API - FECHAS PARA ENVIAR AL BACKEND
  // ============================================================================

  /// Convierte DateTime a ISO 8601 para enviar al backend.
  /// Envía hora local naive — Django (TIME_ZONE='America/Lima') la interpreta
  /// como hora Lima automáticamente.
  static String toApiIso(DateTime date) {
    return date.toIso8601String();
  }

  /// Convierte DateTime nullable a ISO 8601, o retorna null.
  static String? toApiIsoOrNull(DateTime? date) {
    return date?.toIso8601String();
  }
}