// ============================================================================
// 🚗 HELPERS PARA VEHÍCULOS - UNIFICADO
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class VehicleHelpers {
  // ============================================================================
  // MARCAS DE VEHÍCULOS
  // ============================================================================

  /// Marcas que son principalmente camiones/comerciales
  static const Set<String> truckBrands = {
    'HINO',
    'FUSO',
    'T-KING',
    'UD TRUCKS',
    'JAC PESADO',
    'KOMATSU',
    'JAC',
    'VOLVO TRUCKS',
    'SCANIA',
    'MERCEDES-BENZ TRUCKS',
    'ISUZU',
    'DONGFENG',
    'SINOTRUK',
    'FAW',
    'FOTON',
    'IVECO',
    'MAN',
    'RENAULT TRUCKS',
    'MACK',
    'KENWORTH',
    'PETERBILT',
    'FREIGHTLINER',
  };

  /// Marcas de autos de lujo
  static const Set<String> luxuryBrands = {
    'BMW',
    'MERCEDES-BENZ',
    'AUDI',
    'LEXUS',
    'INFINITI',
    'ACURA',
    'CADILLAC',
    'LINCOLN',
    'JAGUAR',
    'LAND ROVER',
    'PORSCHE',
    'MASERATI',
    'FERRARI',
    'LAMBORGHINI',
    'BENTLEY',
    'ROLLS-ROYCE',
    'ASTON MARTIN',
  };

  /// Marcas populares
  static const Set<String> popularBrands = {
    'TOYOTA',
    'HONDA',
    'NISSAN',
    'MAZDA',
    'MITSUBISHI',
    'HYUNDAI',
    'KIA',
    'CHEVROLET',
    'FORD',
    'VOLKSWAGEN',
    'SUZUKI',
    'SUBARU',
    'PEUGEOT',
    'RENAULT',
    'CITROEN',
    'FIAT',
    'JEEP',
    'DODGE',
    'CHRYSLER',
  };

  // ============================================================================
  // ICONOS DE VEHÍCULOS
  // ============================================================================

  /// Obtener icono según marca de vehículo
  static IconData getVehicleIcon(String marca) {
    final upperMarca = marca.toUpperCase();

    if (truckBrands.contains(upperMarca)) {
      return Icons.local_shipping; // Camión
    } else if (luxuryBrands.contains(upperMarca)) {
      return Icons.directions_car; // Auto de lujo
    } else if (popularBrands.contains(upperMarca)) {
      return Icons.directions_car; // Auto regular
    } else {
      return Icons.directions_car; // Auto por defecto
    }
  }

  /// Obtener icono específico por tipo de vehículo
  static IconData getVehicleTypeIcon(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'SEDAN':
        return Icons.directions_car;
      case 'SUV':
        return Icons.directions_car;
      case 'HATCHBACK':
        return Icons.directions_car;
      case 'COUPE':
        return Icons.directions_car;
      case 'CONVERTIBLE':
        return Icons.directions_car;
      case 'WAGON':
        return Icons.directions_car;
      case 'PICKUP':
        return Icons.local_shipping;
      case 'TRUCK':
        return Icons.local_shipping;
      case 'VAN':
        return Icons.airport_shuttle;
      case 'MINIVAN':
        return Icons.airport_shuttle;
      case 'BUS':
        return Icons.directions_bus;
      case 'MOTORCYCLE':
        return Icons.two_wheeler;
      case 'SCOOTER':
        return Icons.two_wheeler;
      default:
        return Icons.directions_car;
    }
  }

  // ============================================================================
  // COLORES POR CONDICIÓN
  // ============================================================================

  /// Obtener color según condición de inspección
  static Color getCondicionColor(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PUERTO':
        return AppColors.puerto;
      case 'RECEPCION':
        return AppColors.recepcion;
      case 'ALMACEN':
        return AppColors.almacen;
      case 'PDI':
        return AppColors.pdi;
      case 'PRE-PDI':
        return AppColors.prePdi;
      case 'ARRIBO':
        return AppColors.arribo;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Obtener color según estado de vehículo
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DISPONIBLE':
      case 'COMPLETED':
      case 'TERMINADO':
        return AppColors.success;
      case 'EN_PROCESO':
      case 'PROCESSING':
      case 'PROGRESO':
        return AppColors.warning;
      case 'BLOQUEADO':
      case 'BLOCKED':
      case 'ERROR':
        return AppColors.error;
      case 'PENDIENTE':
      case 'PENDING':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  // ============================================================================
  // ICONOS POR CONDICIÓN
  // ============================================================================

  /// Obtener icono según condición de inspección
  static IconData getCondicionIcon(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PUERTO':
        return Icons.anchor;
      case 'RECEPCION':
        return Icons.login;
      case 'ALMACEN':
        return Icons.warehouse;
      case 'PDI':
        return Icons.build_circle;
      case 'PRE-PDI':
        return Icons.search;
      case 'ARRIBO':
        return Icons.flight_land;
      default:
        return Icons.location_on;
    }
  }

  /// Obtener icono según estado de vehículo
  static IconData getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'DISPONIBLE':
      case 'COMPLETED':
      case 'TERMINADO':
        return Icons.check_circle;
      case 'EN_PROCESO':
      case 'PROCESSING':
      case 'PROGRESO':
        return Icons.pending;
      case 'BLOQUEADO':
      case 'BLOCKED':
      case 'ERROR':
        return Icons.error;
      case 'PENDIENTE':
      case 'PENDING':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  // ============================================================================
  // COLORES DE SEVERIDAD
  // ============================================================================

  /// Obtener color según severidad de daño
  static Color getSeveridadColor(String severidad) {
    if (severidad.toUpperCase().contains('LEVE')) {
      return AppColors.severityLow;
    } else if (severidad.toUpperCase().contains('MEDIO')) {
      return AppColors.severityMedium;
    } else if (severidad.toUpperCase().contains('GRAVE')) {
      return AppColors.severityHigh;
    }
    return AppColors.textSecondary;
  }

  /// Obtener icono según severidad de daño
  static IconData getSeveridadIcon(String severidad) {
    if (severidad.toUpperCase().contains('LEVE')) {
      return Icons.warning_amber;
    } else if (severidad.toUpperCase().contains('MEDIO')) {
      return Icons.error_outline;
    } else if (severidad.toUpperCase().contains('GRAVE')) {
      return Icons.dangerous;
    }
    return Icons.info_outline;
  }

  // ============================================================================
  // HELPERS DE VALIDACIÓN
  // ============================================================================

  /// Verificar si es una marca de camión
  static bool isTruckBrand(String marca) {
    return truckBrands.contains(marca.toUpperCase());
  }

  /// Verificar si es una marca de lujo
  static bool isLuxuryBrand(String marca) {
    return luxuryBrands.contains(marca.toUpperCase());
  }

  /// Verificar si es una marca popular
  static bool isPopularBrand(String marca) {
    return popularBrands.contains(marca.toUpperCase());
  }

  /// Verificar si la condición requiere contenedor
  static bool requiresContainer(String condicion) {
    return condicion.toUpperCase() == 'ALMACEN';
  }

  /// Verificar si la condición requiere bloque
  static bool requiresBlock(String condicion) {
    return condicion.toUpperCase() == 'PUERTO';
  }

  /// Verificar si la condición permite fila y posición
  static bool allowsRowAndPosition(String condicion) {
    return condicion.toUpperCase() == 'PUERTO';
  }

  /// Verificar si la condición es válida para puerto
  static bool isValidForPort(String condicion) {
    return ['PUERTO', 'RECEPCION', 'ARRIBO'].contains(condicion.toUpperCase());
  }

  /// Verificar si la condición es válida para almacén
  static bool isValidForWarehouse(String condicion) {
    return ['ALMACEN', 'PDI', 'PRE-PDI'].contains(condicion.toUpperCase());
  }

  // ============================================================================
  // HELPERS DE FORMATEO
  // ============================================================================

  /// Formatear condición para display
  static String formatCondicion(String condicion) {
    switch (condicion.toUpperCase()) {
      case 'PRE-PDI':
        return 'Pre-PDI';
      case 'PDI':
        return 'PDI';
      default:
        return condicion
            .toLowerCase()
            .split(' ')
            .map((word) {
              return word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1)
                  : word;
            })
            .join(' ');
    }
  }

  /// Formatear severidad para display
  static String formatSeveridad(String severidad) {
    if (severidad.toUpperCase().contains('LEVE')) {
      return 'Leve';
    } else if (severidad.toUpperCase().contains('MEDIO')) {
      return 'Medio';
    } else if (severidad.toUpperCase().contains('GRAVE')) {
      return 'Grave';
    }
    return severidad;
  }

  /// Formatear marca para display
  static String formatBrand(String marca) {
    // Casos especiales
    switch (marca.toUpperCase()) {
      case 'BMW':
        return 'BMW';
      case 'KIA':
        return 'KIA';
      case 'PDI':
        return 'PDI';
      case 'SUV':
        return 'SUV';
      case 'T-KING':
        return 'T-King';
      case 'UD TRUCKS':
        return 'UD Trucks';
      case 'JAC PESADO':
        return 'JAC Pesado';
      case 'MERCEDES-BENZ':
        return 'Mercedes-Benz';
      case 'LAND ROVER':
        return 'Land Rover';
      case 'ROLLS-ROYCE':
        return 'Rolls-Royce';
      case 'ASTON MARTIN':
        return 'Aston Martin';
      default:
        return marca
            .toLowerCase()
            .split(' ')
            .map((word) {
              return word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1)
                  : word;
            })
            .join(' ');
    }
  }

  // ============================================================================
  // HELPERS DE AGRUPACIÓN
  // ============================================================================

  /// Agrupar vehículos por condición
  static Map<String, List<T>> groupByCondicion<T>(
    List<T> vehicles,
    String Function(T) getCondicion,
  ) {
    final Map<String, List<T>> groups = {};

    for (final vehicle in vehicles) {
      final condicion = getCondicion(vehicle);
      groups[condicion] ??= [];
      groups[condicion]!.add(vehicle);
    }

    return groups;
  }

  /// Agrupar vehículos por marca
  static Map<String, List<T>> groupByBrand<T>(
    List<T> vehicles,
    String Function(T) getBrand,
  ) {
    final Map<String, List<T>> groups = {};

    for (final vehicle in vehicles) {
      final brand = getBrand(vehicle);
      groups[brand] ??= [];
      groups[brand]!.add(vehicle);
    }

    return groups;
  }

  /// Agrupar vehículos por severidad
  static Map<String, List<T>> groupBySeverity<T>(
    List<T> damages,
    String Function(T) getSeverity,
  ) {
    final Map<String, List<T>> groups = {};

    for (final damage in damages) {
      final severity = getSeverity(damage);
      groups[severity] ??= [];
      groups[severity]!.add(damage);
    }

    return groups;
  }

  // ============================================================================
  // HELPERS DE ORDENAMIENTO
  // ============================================================================

  /// Ordenar condiciones por prioridad
  static List<String> sortConditionsByPriority(List<String> condiciones) {
    const priority = {
      'ARRIBO': 1,
      'RECEPCION': 2,
      'PUERTO': 3,
      'ALMACEN': 4,
      'PRE-PDI': 5,
      'PDI': 6,
    };

    condiciones.sort((a, b) {
      final priorityA = priority[a.toUpperCase()] ?? 999;
      final priorityB = priority[b.toUpperCase()] ?? 999;
      return priorityA.compareTo(priorityB);
    });

    return condiciones;
  }

  /// Ordenar severidades por prioridad
  static List<String> sortSeveritiesByPriority(List<String> severidades) {
    const priority = {'GRAVE': 1, 'MEDIO': 2, 'LEVE': 3};

    severidades.sort((a, b) {
      final priorityA = priority[a.toUpperCase()] ?? 999;
      final priorityB = priority[b.toUpperCase()] ?? 999;
      return priorityA.compareTo(priorityB);
    });

    return severidades;
  }

  // ============================================================================
  // HELPERS DE CONTEO
  // ============================================================================

  /// Contar vehículos por condición
  static Map<String, int> countByCondicion<T>(
    List<T> vehicles,
    String Function(T) getCondicion,
  ) {
    final Map<String, int> counts = {};

    for (final vehicle in vehicles) {
      final condicion = getCondicion(vehicle);
      counts[condicion] = (counts[condicion] ?? 0) + 1;
    }

    return counts;
  }

  /// Contar daños por severidad
  static Map<String, int> countBySeverity<T>(
    List<T> damages,
    String Function(T) getSeverity,
  ) {
    final Map<String, int> counts = {};

    for (final damage in damages) {
      final severity = getSeverity(damage);
      counts[severity] = (counts[severity] ?? 0) + 1;
    }

    return counts;
  }

  /// Obtener estadísticas de vehículos
  static Map<String, dynamic> getVehicleStats<T>(
    List<T> vehicles,
    String Function(T) getCondicion,
    String Function(T) getBrand,
  ) {
    return {
      'total': vehicles.length,
      'by_condition': countByCondicion(vehicles, getCondicion),
      'by_brand': countByCondicion(vehicles, getBrand),
      'truck_count': vehicles.where((v) => isTruckBrand(getBrand(v))).length,
      'luxury_count': vehicles.where((v) => isLuxuryBrand(getBrand(v))).length,
    };
  }
}
