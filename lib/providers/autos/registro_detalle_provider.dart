// lib/providers/autos/detalle_registro_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:stampcamera/models/autos/registro_vin_options.dart';
import '../../models/autos/detalle_registro_model.dart';
import '../../services/autos/detalle_registro_service.dart';

// ============================================================================
// PROVIDER DEL SERVICIO
// ============================================================================

final detalleRegistroServiceProvider = Provider<DetalleRegistroService>((ref) {
  return DetalleRegistroService();
});

// ============================================================================
// PROVIDER PRINCIPAL DE DETALLE POR VIN
// ============================================================================

final detalleRegistroProvider =
    AsyncNotifierProvider.family<
      DetalleRegistroNotifier,
      DetalleRegistroModel,
      String
    >(DetalleRegistroNotifier.new);

class DetalleRegistroNotifier
    extends FamilyAsyncNotifier<DetalleRegistroModel, String> {
  DetalleRegistroService get _service =>
      ref.read(detalleRegistroServiceProvider);

  @override
  Future<DetalleRegistroModel> build(String vin) async {
    return await _loadDetalle(vin);
  }

  // ============================================================================
  // MÉTODOS DE CARGA
  // ============================================================================

  Future<DetalleRegistroModel> _loadDetalle(String vin) async {
    return await _service.getByVin(vin);
  }

  /// Refrescar datos del detalle
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final detalle = await _loadDetalle(arg);
      state = AsyncValue.data(detalle);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ============================================================================
  // REGISTRO VIN OPERATIONS
  // ============================================================================

  /// Crear registro VIN simple
  Future<bool> createRegistroVin({
    required String condicion,
    required int zonaInspeccion,
    required File fotoVin,
    int? bloque,
    int? fila,
    int? posicion,
    int? contenedorId,
  }) async {
    try {
      final result = await _service.createRegistroVin(
        vin: arg,
        condicion: condicion,
        zonaInspeccion: zonaInspeccion,
        fotoVin: fotoVin,
        bloque: bloque,
        fila: fila,
        posicion: posicion,
        contenedorId: contenedorId,
      );

      debugPrint("✅ Result: $result");

      // ✅ Verificar que la operación fue exitosa
      if (result['success'] != true) {
        debugPrint("❌ Error del servidor: ${result['message']}");
        return false;
      }

      // ✅ Actualizar state local con el nuevo registro VIN
      final currentDetalle = state.valueOrNull;
      if (currentDetalle != null) {
        // ✅ FIX: Extraer 'data' de la respuesta
        final nuevoRegistroVin = RegistroVin.fromJson(result['data']);
        final registrosActualizados = [
          ...currentDetalle.registrosVin,
          nuevoRegistroVin,
        ];

        debugPrint("📋 Registros antes: ${currentDetalle.registrosVin.length}");
        debugPrint("📋 Registros después: ${registrosActualizados.length}");

        final detalleActualizado = DetalleRegistroModel(
          vin: currentDetalle.vin,
          serie: currentDetalle.serie,
          color: currentDetalle.color,
          factura: currentDetalle.factura,
          bl: currentDetalle.bl,
          naveDescarga: currentDetalle.naveDescarga,
          informacionUnidad: currentDetalle.informacionUnidad,
          registrosVin: registrosActualizados,
          fotosPresentacion: currentDetalle.fotosPresentacion,
          danos: currentDetalle.danos,
        );

        debugPrint("🔄 Actualizando state...");
        //TODO: Penitente arreglar el Refres de la pantalla.
        state = AsyncValue.data(detalleActualizado);
        debugPrint("✅ State actualizado correctamente");
      } else {
        debugPrint("⚠️ currentDetalle es null, no se puede actualizar state");
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error creando registro VIN: $e');
      return false;
    }
  }

  /// Actualizar registro VIN
  Future<bool> updateRegistroVin({
    required int registroVinId,
    String? condicion,
    int? zonaInspeccion,
    File? fotoVin,
    int? bloque,
    int? fila,
    int? posicion,
    int? contenedorId,
  }) async {
    try {
      final result = await _service.updateRegistroVin(
        registroVinId: registroVinId,
        condicion: condicion,
        zonaInspeccion: zonaInspeccion,
        fotoVin: fotoVin,
        bloque: bloque,
        fila: fila,
        posicion: posicion,
        contenedorId: contenedorId,
      );

      // ✅ Actualizar state local con el registro modificado
      final currentDetalle = state.valueOrNull;
      if (currentDetalle != null && result['data'] != null) {
        final registroActualizado = RegistroVin.fromJson(result['data']);
        final registrosActualizados = currentDetalle.registrosVin.map((r) {
          return r.vin.hashCode == registroVinId ? registroActualizado : r;
        }).toList();

        final detalleActualizado = DetalleRegistroModel(
          vin: currentDetalle.vin,
          serie: currentDetalle.serie,
          color: currentDetalle.color,
          factura: currentDetalle.factura,
          bl: currentDetalle.bl,
          naveDescarga: currentDetalle.naveDescarga,
          informacionUnidad: currentDetalle.informacionUnidad,
          registrosVin: registrosActualizados,
          fotosPresentacion: currentDetalle.fotosPresentacion,
          danos: currentDetalle.danos,
        );

        state = AsyncValue.data(detalleActualizado);
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error actualizando registro VIN: $e');
      return false;
    }
  }

  // ============================================================================
  // FOTOS DE PRESENTACIÓN OPERATIONS
  // ============================================================================

  /// Agregar foto individual
  Future<bool> addFoto({
    required String tipo,
    required File imagen,
    String? nDocumento,
  }) async {
    try {
      final detalle = state.valueOrNull;
      if (detalle == null) return false;

      final registroVinId = _getLatestRegistroVinId(detalle);
      if (registroVinId == null) return false;

      final result = await _service.createFoto(
        registroVinId: registroVinId,
        tipo: tipo,
        imagen: imagen,
        nDocumento: nDocumento,
      );

      // ✅ Actualizar state local con la nueva foto
      if (result['data'] != null) {
        final nuevaFoto = FotoPresentacion.fromJson(result['data']);
        final fotosActualizadas = [...detalle.fotosPresentacion, nuevaFoto];

        final detalleActualizado = DetalleRegistroModel(
          vin: detalle.vin,
          serie: detalle.serie,
          color: detalle.color,
          factura: detalle.factura,
          bl: detalle.bl,
          naveDescarga: detalle.naveDescarga,
          informacionUnidad: detalle.informacionUnidad,
          registrosVin: detalle.registrosVin,
          fotosPresentacion: fotosActualizadas,
          danos: detalle.danos,
        );

        state = AsyncValue.data(detalleActualizado);
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error agregando foto: $e');
      return false;
    }
  }

  /// Actualizar foto existente
  Future<bool> updateFoto({
    required int fotoId,
    String? tipo,
    File? imagen,
    String? nDocumento,
  }) async {
    try {
      final result = await _service.updateFoto(
        fotoId: fotoId,
        tipo: tipo,
        imagen: imagen,
        nDocumento: nDocumento,
      );

      // ✅ Actualizar state local con la foto modificada
      final currentDetalle = state.valueOrNull;
      if (currentDetalle != null && result['data'] != null) {
        final fotoActualizada = FotoPresentacion.fromJson(result['data']);
        final fotosActualizadas = currentDetalle.fotosPresentacion.map((f) {
          return f.id == fotoId ? fotoActualizada : f;
        }).toList();

        final detalleActualizado = DetalleRegistroModel(
          vin: currentDetalle.vin,
          serie: currentDetalle.serie,
          color: currentDetalle.color,
          factura: currentDetalle.factura,
          bl: currentDetalle.bl,
          naveDescarga: currentDetalle.naveDescarga,
          informacionUnidad: currentDetalle.informacionUnidad,
          registrosVin: currentDetalle.registrosVin,
          fotosPresentacion: fotosActualizadas,
          danos: currentDetalle.danos,
        );

        state = AsyncValue.data(detalleActualizado);
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error actualizando foto: $e');
      return false;
    }
  }

  /// Eliminar foto
  Future<bool> deleteFoto(int fotoId) async {
    try {
      await _service.deleteFoto(fotoId);

      // ✅ Actualizar state local removiendo la foto
      final currentDetalle = state.valueOrNull;
      if (currentDetalle != null) {
        final fotosActualizadas = currentDetalle.fotosPresentacion
            .where((f) => f.id != fotoId)
            .toList();

        final detalleActualizado = DetalleRegistroModel(
          vin: currentDetalle.vin,
          serie: currentDetalle.serie,
          color: currentDetalle.color,
          factura: currentDetalle.factura,
          bl: currentDetalle.bl,
          naveDescarga: currentDetalle.naveDescarga,
          informacionUnidad: currentDetalle.informacionUnidad,
          registrosVin: currentDetalle.registrosVin,
          fotosPresentacion: fotosActualizadas,
          danos: currentDetalle.danos,
        );

        state = AsyncValue.data(detalleActualizado);
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando foto: $e');
      return false;
    }
  }

  // ============================================================================
  // DAÑOS OPERATIONS - CRUD COMPLETO
  // ============================================================================

  /// Crear daño con imágenes
  Future<bool> createDanoWithImages({
    required int tipoDano,
    required int areaDano,
    required int severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool relevante = false,
    List<File>? imagenes,
  }) async {
    try {
      final detalle = state.valueOrNull;
      if (detalle == null) return false;

      final registroVinId = _getLatestRegistroVinId(detalle);
      if (registroVinId == null) return false;

      final result = await _service.createDanoWithImages(
        registroVinId: registroVinId,
        tipoDano: tipoDano,
        areaDano: areaDano,
        severidad: severidad,
        zonas: zonas,
        descripcion: descripcion,
        responsabilidad: responsabilidad,
        relevante: relevante,
        imagenes: imagenes,
      );

      // ✅ Actualizar state local con el nuevo daño
      if (result['dano'] != null) {
        final nuevoDano = Dano.fromJson(result['dano']);
        final danosActualizados = [...detalle.danos, nuevoDano];

        final detalleActualizado = DetalleRegistroModel(
          vin: detalle.vin,
          serie: detalle.serie,
          color: detalle.color,
          factura: detalle.factura,
          bl: detalle.bl,
          naveDescarga: detalle.naveDescarga,
          informacionUnidad: detalle.informacionUnidad,
          registrosVin: detalle.registrosVin,
          fotosPresentacion: detalle.fotosPresentacion,
          danos: danosActualizados,
        );

        state = AsyncValue.data(detalleActualizado);
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error creando daño con imágenes: $e');
      return false;
    }
  }

  /// Actualizar daño existente
  Future<bool> updateDano({
    required int danoId,
    int? tipoDano,
    int? areaDano,
    int? severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool? relevante,
  }) async {
    try {
      final result = await _service.updateDano(
        danoId: danoId,
        tipoDano: tipoDano,
        areaDano: areaDano,
        severidad: severidad,
        zonas: zonas,
        descripcion: descripcion,
        responsabilidad: responsabilidad,
        relevante: relevante,
      );

      // ✅ Actualizar state local con el daño modificado
      final currentDetalle = state.valueOrNull;
      if (currentDetalle != null && result['data'] != null) {
        final danoActualizado = Dano.fromJson(result['data']);
        final danosActualizados = currentDetalle.danos.map((d) {
          return d.id == danoId ? danoActualizado : d;
        }).toList();

        final detalleActualizado = DetalleRegistroModel(
          vin: currentDetalle.vin,
          serie: currentDetalle.serie,
          color: currentDetalle.color,
          factura: currentDetalle.factura,
          bl: currentDetalle.bl,
          naveDescarga: currentDetalle.naveDescarga,
          informacionUnidad: currentDetalle.informacionUnidad,
          registrosVin: currentDetalle.registrosVin,
          fotosPresentacion: currentDetalle.fotosPresentacion,
          danos: danosActualizados,
        );

        state = AsyncValue.data(detalleActualizado);
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error actualizando daño: $e');
      return false;
    }
  }

  /// Eliminar daño
  Future<bool> deleteDano(int danoId) async {
    try {
      await _service.deleteDano(danoId);

      // ✅ Actualizar state local removiendo el daño
      final currentDetalle = state.valueOrNull;
      if (currentDetalle != null) {
        final danosActualizados = currentDetalle.danos
            .where((d) => d.id != danoId)
            .toList();

        final detalleActualizado = DetalleRegistroModel(
          vin: currentDetalle.vin,
          serie: currentDetalle.serie,
          color: currentDetalle.color,
          factura: currentDetalle.factura,
          bl: currentDetalle.bl,
          naveDescarga: currentDetalle.naveDescarga,
          informacionUnidad: currentDetalle.informacionUnidad,
          registrosVin: currentDetalle.registrosVin,
          fotosPresentacion: currentDetalle.fotosPresentacion,
          danos: danosActualizados,
        );

        state = AsyncValue.data(detalleActualizado);
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando daño: $e');
      return false;
    }
  }

  /// Agregar imagen a daño existente
  Future<bool> addImagenToDano({
    required int danoId,
    required File imagen,
  }) async {
    try {
      final result = await _service.addImagenToDano(
        danoId: danoId,
        imagen: imagen,
      );

      // ✅ Actualizar state local agregando la imagen al daño
      final currentDetalle = state.valueOrNull;
      if (currentDetalle != null && result['data'] != null) {
        final nuevaImagen = DanoImagen.fromJson(result['data']);
        final danosActualizados = currentDetalle.danos.map((d) {
          if (d.id == danoId) {
            final imagenesActualizadas = [...d.imagenes, nuevaImagen];
            return Dano(
              id: d.id,
              descripcion: d.descripcion,
              condicion: d.condicion,
              tipoDano: d.tipoDano,
              areaDano: d.areaDano,
              severidad: d.severidad,
              nDocumento: d.nDocumento,
              zonas: d.zonas,
              imagenes: imagenesActualizadas,
              responsabilidad: d.responsabilidad,
              createAt: d.createAt,
              createBy: d.createBy,
              relevante: d.relevante,
              verificadoBool: d.verificadoBool,
              verificado: d.verificado,
            );
          }
          return d;
        }).toList();

        final detalleActualizado = DetalleRegistroModel(
          vin: currentDetalle.vin,
          serie: currentDetalle.serie,
          color: currentDetalle.color,
          factura: currentDetalle.factura,
          bl: currentDetalle.bl,
          naveDescarga: currentDetalle.naveDescarga,
          informacionUnidad: currentDetalle.informacionUnidad,
          registrosVin: currentDetalle.registrosVin,
          fotosPresentacion: currentDetalle.fotosPresentacion,
          danos: danosActualizados,
        );

        state = AsyncValue.data(detalleActualizado);
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error agregando imagen a daño: $e');
      return false;
    }
  }

  /// Eliminar imagen de daño
  Future<bool> removeImagenFromDano({
    required int danoId,
    required int imagenId,
  }) async {
    try {
      await _service.removeImagenFromDano(danoId: danoId, imagenId: imagenId);

      // ✅ Actualizar state local removiendo la imagen del daño
      final currentDetalle = state.valueOrNull;
      if (currentDetalle != null) {
        final danosActualizados = currentDetalle.danos.map((d) {
          if (d.id == danoId) {
            final imagenesActualizadas = d.imagenes
                .where((img) => img.id != imagenId)
                .toList();
            return Dano(
              id: d.id,
              descripcion: d.descripcion,
              condicion: d.condicion,
              tipoDano: d.tipoDano,
              areaDano: d.areaDano,
              severidad: d.severidad,
              nDocumento: d.nDocumento,
              zonas: d.zonas,
              imagenes: imagenesActualizadas,
              responsabilidad: d.responsabilidad,
              createAt: d.createAt,
              createBy: d.createBy,
              relevante: d.relevante,
              verificadoBool: d.verificadoBool,
              verificado: d.verificado,
            );
          }
          return d;
        }).toList();

        final detalleActualizado = DetalleRegistroModel(
          vin: currentDetalle.vin,
          serie: currentDetalle.serie,
          color: currentDetalle.color,
          factura: currentDetalle.factura,
          bl: currentDetalle.bl,
          naveDescarga: currentDetalle.naveDescarga,
          informacionUnidad: currentDetalle.informacionUnidad,
          registrosVin: currentDetalle.registrosVin,
          fotosPresentacion: currentDetalle.fotosPresentacion,
          danos: danosActualizados,
        );

        state = AsyncValue.data(detalleActualizado);
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando imagen de daño: $e');
      return false;
    }
  }

  // ============================================================================
  // MÉTODOS DE UTILIDAD
  // ============================================================================

  /// Obtener el ID del registro VIN más reciente
  int? _getLatestRegistroVinId(DetalleRegistroModel detalle) {
    if (detalle.registrosVin.isEmpty) return null;

    final sortedRegistros = List<RegistroVin>.from(detalle.registrosVin);
    sortedRegistros.sort((a, b) => (b.fecha ?? '').compareTo(a.fecha ?? ''));

    return sortedRegistros.first.vin.hashCode;
  }

  /// Limpiar estado actual
  void clear() {
    state = const AsyncValue.loading();
  }

  /// Verificar si tiene daños
  bool get hasDanos {
    final detalle = state.valueOrNull;
    return detalle?.danos.isNotEmpty ?? false;
  }

  /// Obtener conteo de daños por tipo
  Map<String, int> get danosCounts {
    final detalle = state.valueOrNull;
    if (detalle == null) return {};

    final counts = <String, int>{};
    for (final dano in detalle.danos) {
      final tipo = dano.tipoDano.esp;
      counts[tipo] = (counts[tipo] ?? 0) + 1;
    }
    return counts;
  }

  /// Obtener daños relevantes
  List<Dano> get danosRelevantes {
    final detalle = state.valueOrNull;
    return detalle?.danos.where((d) => d.relevante).toList() ?? [];
  }

  /// Obtener daños verificados
  List<Dano> get danosVerificados {
    final detalle = state.valueOrNull;
    return detalle?.danos.where((d) => d.verificadoBool).toList() ?? [];
  }
}

// ============================================================================
// PROVIDERS DE OPCIONES
// ============================================================================

/// Provider para opciones de registro VIN
final registroVinOptionsProvider = FutureProvider<RegistroVinOptions>((
  ref,
) async {
  final service = ref.read(detalleRegistroServiceProvider);
  final data = await service.getRegistroVinOptions();
  return RegistroVinOptions.fromJson(data);
});

/// Provider para opciones de fotos
final fotosOptionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(detalleRegistroServiceProvider);
  return await service.getFotosOptions();
});

/// Provider para opciones de daños
final danosOptionsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(detalleRegistroServiceProvider);
  return await service.getDanosOptions();
});

// ============================================================================
// PROVIDERS SIMPLIFICADOS
// ============================================================================

/// Provider simplificado para obtener detalle por VIN
final registroDetalleProvider =
    FutureProvider.family<DetalleRegistroModel, String>((ref, vin) async {
      final service = ref.read(detalleRegistroServiceProvider);
      return await service.getByVin(vin);
    });

/// Provider para verificar si un VIN tiene detalles
final vinHasDetalleProvider = FutureProvider.family<bool, String>((
  ref,
  vin,
) async {
  try {
    await ref.watch(registroDetalleProvider(vin).future);
    return true;
  } catch (e) {
    return false;
  }
});
