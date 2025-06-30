// lib/providers/autos/detalle_registro_provider.dart
import 'dart:io';
import 'package:dio/dio.dart';
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
    _preloadOptionsInBackground();
    return await _service.getByVin(vin);
  }

  /// Precargar opciones de manera silenciosa en segundo plano
  void _preloadOptionsInBackground() {
    // ✅ Disparar las cargas sin await - no bloquean

    // Cargar opciones de registro VIN
    ref.read(registroVinOptionsProvider.future).catchError((error) {
      debugPrint('⚠️ Error cargando registroVinOptions (silencioso): $error');
      // No hacer nada, las opciones se cargarán cuando se necesiten
    });

    // Cargar opciones de fotos
    ref.read(fotosOptionsProvider.future).catchError((error) {
      debugPrint('⚠️ Error cargando fotosOptions (silencioso): $error');
    });

    // Cargar opciones de daños
    ref.read(danosOptionsProvider.future).catchError((error) {
      debugPrint('⚠️ Error cargando danosOptions (silencioso): $error');
    });

    debugPrint('🚀 Opciones iniciadas en background para VIN: $arg');
  }

  /// Refrescar datos del detalle
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      // ✅ También recargar opciones en background durante refresh

      final detalle = await _loadDetalle(arg);
      state = AsyncValue.data(detalle);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ============================================================================
  // REGISTRO VIN OPERATIONS
  // ============================================================================

  /// Crear registro VIN simple - SIMPLE ERROR HANDLING
  /// Crear registro VIN simple - FIX DioException
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

      // ✅ Verificar si la operación fue exitosa
      if (result['success'] == false) {
        // ✅ Extraer mensaje de error
        final errors = result['errors'];
        if (errors != null && errors['non_field_errors'] != null) {
          final errorList = errors['non_field_errors'] as List;
          if (errorList.isNotEmpty) {
            throw Exception(errorList.first.toString());
          }
        }
        throw Exception('Error al crear el registro');
      }

      // ✅ Actualizar state local con el nuevo registro VIN
      final currentDetalle = state.valueOrNull;
      if (currentDetalle != null) {
        final nuevoRegistroVin = RegistroVin.fromJson(result['data']);
        final registrosActualizados = [
          ...currentDetalle.registrosVin,
          nuevoRegistroVin,
        ];

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
        debugPrint("✅ State actualizado correctamente");
      }

      return true;
    } on DioException catch (dioError) {
      // ✅ CAPTURAR DioException y extraer el mensaje real
      debugPrint('❌ DioException: ${dioError.response?.statusCode}');
      debugPrint('❌ Response data: ${dioError.response?.data}');

      if (dioError.response?.statusCode == 400 &&
          dioError.response?.data != null) {
        final responseData = dioError.response!.data;

        // ✅ Buscar el mensaje de error en la respuesta
        if (responseData is Map<String, dynamic>) {
          // Caso 1: {success: false, errors: {non_field_errors: [...]}}
          if (responseData['success'] == false &&
              responseData['errors'] != null) {
            final errors = responseData['errors'];
            if (errors['non_field_errors'] != null) {
              final errorList = errors['non_field_errors'] as List;
              if (errorList.isNotEmpty) {
                throw Exception(errorList.first.toString());
              }
            }
          }

          // Caso 2: {non_field_errors: [...]}
          if (responseData['non_field_errors'] != null) {
            final errorList = responseData['non_field_errors'] as List;
            if (errorList.isNotEmpty) {
              throw Exception(errorList.first.toString());
            }
          }

          // Caso 3: {detail: "mensaje"}
          if (responseData['detail'] != null) {
            throw Exception(responseData['detail'].toString());
          }
        }
      }

      // ✅ Si no encontramos el mensaje específico, usar mensaje genérico
      throw Exception('VIN duplicado o datos inválidos');
    } catch (e) {
      debugPrint('❌ Error creando registro VIN: $e');
      // ✅ Re-lanzar la excepción para que el form la capture
      rethrow;
    }
  }

  /// Actualizar registro VIN
  /// Actualizar registro VIN (CON DEBUG)
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
    // 🐛 DEBUG: Mostrar todos los parámetros recibidos desde el form
    debugPrint('📝 PROVIDER updateRegistroVin - Parámetros del formulario:');
    debugPrint('   registroVinId: $registroVinId');
    debugPrint('   condicion: $condicion');
    debugPrint('   zonaInspeccion: $zonaInspeccion');
    debugPrint('   bloque: $bloque');
    debugPrint('   fila: $fila');
    debugPrint('   posicion: $posicion');
    debugPrint('   contenedorId: $contenedorId');
    debugPrint('   fotoVin: ${fotoVin?.path ?? 'null'}');

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

      debugPrint('✅ Service result: $result');

      // ✅ Actualizar state local con el registro modificado
      final currentDetalle = state.valueOrNull;
      if (currentDetalle != null && result['data'] != null) {
        final registroActualizado = RegistroVin.fromJson(result['data']);
        final registrosActualizados = currentDetalle.registrosVin.map((r) {
          return r.id == registroVinId ? registroActualizado : r;
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
        debugPrint('✅ State actualizado correctamente');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error actualizando registro VIN: $e');
      return false;
    }
  }

  /// Eliminar registro VIN
  Future<bool> deleteRegistroVin(int registroVinId) async {
    try {
      await _service.deleteRegistroVin(registroVinId);

      // ✅ Actualizar state local removiendo el registro
      final currentDetalle = state.valueOrNull;
      if (currentDetalle != null) {
        final registrosActualizados = currentDetalle.registrosVin
            .where((r) => r.id != registroVinId)
            .toList();

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
      debugPrint('❌ Error eliminando registro VIN: $e');
      return false;
    }
  }

  // ============================================================================
  // FOTOS DE PRESENTACIÓN OPERATIONS
  // ============================================================================

  /// Agregar foto individual
  Future<bool> addFoto({
    int?
    registroVinId, // ✅ Parámetro opcional para seleccionar registro específico
    required String tipo,
    required File imagen,
    String? nDocumento,
  }) async {
    try {
      final detalle = state.valueOrNull;
      if (detalle == null) return false;

      // ✅ Si no se proporciona registroVinId, usar el más reciente (comportamiento anterior)
      final targetRegistroVinId =
          registroVinId ?? _getLatestRegistroVinId(detalle);
      if (targetRegistroVinId == null) return false;

      debugPrint('🔧 addFoto - Parámetros finales:');
      debugPrint('   targetRegistroVinId: $targetRegistroVinId');
      debugPrint('   tipo: $tipo');
      debugPrint('   nDocumento: $nDocumento');

      final result = await _service.createFoto(
        registroVinId: targetRegistroVinId,
        tipo: tipo,
        imagen: imagen,
        nDocumento: nDocumento,
      );

      debugPrint('✅ addFoto result: $result');

      // ✅ Verificar si la operación fue exitosa
      if (result['success'] == false) {
        // ✅ Extraer mensaje de error
        final errors = result['errors'];
        if (errors != null) {
          // Caso 1: {errors: {non_field_errors: [...]}}
          if (errors['non_field_errors'] != null) {
            final errorList = errors['non_field_errors'] as List;
            if (errorList.isNotEmpty) {
              throw Exception(errorList.first.toString());
            }
          }

          // Caso 2: {errors: {campo_especifico: [...]}}
          if (errors is Map<String, dynamic>) {
            final firstError = errors.values.firstWhere(
              (value) => value is List && value.isNotEmpty,
              orElse: () => null,
            );
            if (firstError != null) {
              throw Exception(firstError.first.toString());
            }
          }
        }

        // Si no encontramos error específico
        throw Exception('Error al crear la foto');
      }

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
    } on DioException catch (dioError) {
      // ✅ CAPTURAR DioException similar a createRegistroVin
      debugPrint('❌ DioException en addFoto: ${dioError.response?.statusCode}');
      debugPrint('❌ Response data: ${dioError.response?.data}');

      if (dioError.response?.statusCode == 400 &&
          dioError.response?.data != null) {
        final responseData = dioError.response!.data;

        // ✅ Buscar el mensaje de error en la respuesta
        if (responseData is Map<String, dynamic>) {
          // Caso 1: {success: false, errors: {non_field_errors: [...]}}
          if (responseData['success'] == false &&
              responseData['errors'] != null) {
            final errors = responseData['errors'];
            if (errors['non_field_errors'] != null) {
              final errorList = errors['non_field_errors'] as List;
              if (errorList.isNotEmpty) {
                throw Exception(errorList.first.toString());
              }
            }
          }

          // Caso 2: {non_field_errors: [...]}
          if (responseData['non_field_errors'] != null) {
            final errorList = responseData['non_field_errors'] as List;
            if (errorList.isNotEmpty) {
              throw Exception(errorList.first.toString());
            }
          }

          // Caso 3: {detail: "mensaje"}
          if (responseData['detail'] != null) {
            throw Exception(responseData['detail'].toString());
          }

          // Caso 4: Errores de campo específico
          if (responseData['errors'] != null) {
            final errors = responseData['errors'] as Map<String, dynamic>;
            final firstError = errors.values.firstWhere(
              (value) => value is List && value.isNotEmpty,
              orElse: () => null,
            );
            if (firstError != null) {
              throw Exception(firstError.first.toString());
            }
          }
        }
      }

      // ✅ Si no encontramos el mensaje específico, usar mensaje genérico
      throw Exception('Error de validación en la foto');
    } catch (e) {
      debugPrint('❌ Error agregando foto: $e');
      // ✅ Re-lanzar la excepción para que el form la capture
      rethrow;
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
    required registroVinId,
    required int tipoDano,
    required int areaDano,
    required int severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool relevante = false,
    List<File>? imagenes,
    int? nDocumento,
  }) async {
    try {
      final detalle = state.valueOrNull;
      if (detalle == null) return false;

      // ✅ Usar el método correcto del servicio
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
        nDocumento: nDocumento,
      );

      debugPrint('🎯 createDanoWithImages result: $result');

      // ✅ ACTUALIZAR STATE LOCAL IGUAL QUE updateDano()
      if (result['success'] == true && result['data'] != null) {
        debugPrint('✅ Daño creado exitosamente, actualizando state local...');

        // ✅ Crear el nuevo daño desde la respuesta del servidor
        final nuevoDano = Dano.fromJson(result['data']);

        // ✅ Agregar el nuevo daño a la lista existente
        final danosActualizados = [...detalle.danos, nuevoDano];

        // ✅ Construir el detalle actualizado
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

        // ✅ Actualizar el state
        state = AsyncValue.data(detalleActualizado);

        debugPrint(
          '✅ State local actualizado con nuevo daño ID: ${nuevoDano.id}',
        );
        return true;
      } else {
        debugPrint('❌ Respuesta sin success o data: $result');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error creando daño con imágenes: $e');
      return false;
    }
  }

  // Método updateDano corregido en el provider

  // Método updateDano corregido en el provider

  Future<bool> updateDano({
    required int danoId,
    required registroVinId,
    int? tipoDano,
    int? areaDano,
    int? severidad,
    List<int>? zonas,
    String? descripcion,
    int? responsabilidad,
    bool? relevante,
    List<File>? newImages, // ✅ Nuevas imágenes a agregar
    List<int>? removedImageIds, // ✅ IDs de imágenes a eliminar
    int? nDocumento, // ✅ NUEVO: ID de la foto de presentación
  }) async {
    try {
      debugPrint('🔧 updateDano - Iniciando actualización:');
      debugPrint('   danoId: $danoId');
      debugPrint('   newImages: ${newImages?.length ?? 0}');
      debugPrint('   removedImageIds: ${removedImageIds?.length ?? 0}');

      final currentDetalle = state.valueOrNull;
      if (currentDetalle == null) {
        debugPrint('❌ No hay detalle disponible');
        return false;
      }

      // ✅ 1. ELIMINAR imágenes que el usuario quitó
      if (removedImageIds != null && removedImageIds.isNotEmpty) {
        debugPrint('🗑️ Eliminando ${removedImageIds.length} imágenes...');

        for (final imagenId in removedImageIds) {
          try {
            debugPrint('🗑️ Eliminando imagen ID: $imagenId');
            await _service.removeImagenFromDano(
              danoId: danoId,
              imagenId: imagenId, // ✅ Usar directamente el ID
            );
            debugPrint('✅ Imagen $imagenId eliminada exitosamente');
          } catch (e) {
            debugPrint('⚠️ Error eliminando imagen $imagenId: $e');
            // Continuar con las demás imágenes
          }
        }
      }

      // ✅ 2. ACTUALIZAR daño + agregar nuevas imágenes en una operación
      debugPrint('📝 Actualizando datos del daño...');
      final result = await _service.updateDano(
        registroVinId: registroVinId,
        danoId: danoId,
        tipoDano: tipoDano,
        areaDano: areaDano,
        severidad: severidad,
        zonas: zonas,
        descripcion: descripcion,
        responsabilidad: responsabilidad,
        relevante: relevante,
        newImages: newImages,
        nDocumento: nDocumento, // ✅ NUEVO: Pasar foto de presentación
      );

      debugPrint('📋 Resultado del servicio: $result');

      // ✅ 3. ACTUALIZAR state local con los datos más recientes
      if (result['success'] == true || result['data'] != null) {
        debugPrint('✅ Actualizando state local...');

        // Opción 1: Usar datos de la respuesta si están disponibles
        if (result['data'] != null) {
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
          debugPrint('✅ State actualizado con datos de la respuesta');
        } else {
          // Opción 2: Refrescar desde el servidor si no hay datos en la respuesta
          debugPrint('🔄 Refrescando desde servidor...');
          await refresh();
        }

        return true;
      } else {
        debugPrint('❌ Respuesta del servicio sin éxito: $result');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error actualizando daño: $e');
      debugPrint('❌ StackTrace: $stackTrace');
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

    return sortedRegistros.first.id;
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

final vinHasDetalleProvider = FutureProvider.family<bool, String>((
  ref,
  vin,
) async {
  try {
    // ✅ Usar el provider principal para evitar duplicación
    await ref.watch(detalleRegistroProvider(vin).future);
    return true;
  } catch (e) {
    return false;
  }
});
