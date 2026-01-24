import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
import 'package:stampcamera/providers/autos/inventario_provider.dart';
import 'package:stampcamera/core/core.dart';

class InventarioFormWidget extends ConsumerStatefulWidget {
  final int informacionUnidadId;
  final InventarioBase? inventario; // null = crear, no null = editar
  final VoidCallback? onSaved;

  const InventarioFormWidget({
    super.key,
    required this.informacionUnidadId,
    this.inventario,
    this.onSaved,
  });

  @override
  ConsumerState<InventarioFormWidget> createState() =>
      _InventarioFormWidgetState();
}

class _InventarioFormWidgetState extends ConsumerState<InventarioFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _otrosController = TextEditingController();

  // Mapa para almacenar todos los valores del inventario
  final Map<String, int> _inventarioValues = {};
  bool _isLoading = false;

  // Getters para modo
  bool get isEditMode => widget.inventario != null;
  String get formTitle => isEditMode ? 'Editar Inventario' : 'Crear Inventario';
  String get submitButtonText => isEditMode ? 'Actualizar' : 'Guardar';

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _otrosController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (isEditMode) {
      // Cargar valores existentes
      final inventario = widget.inventario!;
      _inventarioValues.addAll({
        'LLAVE_SIMPLE': inventario.llaveSimple,
        'LLAVE_COMANDO': inventario.llaveComando,
        'LLAVE_INTELIGENTE': inventario.llaveInteligente,
        'ENCENDEDOR': inventario.encendedor,
        'CENICERO': inventario.cenicero,
        'CABLE_USB_O_AUX': inventario.cableUsbOAux,
        'RETROVISOR': inventario.retrovisor,
        'PISOS': inventario.pisos,
        'LOGOS': inventario.logos,
        'ESTUCHE_MANUAL': inventario.estucheManual,
        'MANUALES_ESTUCHE': inventario.manualesEstuche,
        'PIN_DE_REMOLQUE': inventario.pinDeRemolque,
        'TAPA_PIN_DE_REMOLQUE': inventario.tapaPinDeRemolque,
        'PORTAPLACA': inventario.portaplaca,
        'COPAS_TAPAS_DE_AROS': inventario.copasTapasDeAros,
        'TAPONES_CHASIS': inventario.taponesChasis,
        'COBERTOR': inventario.cobertor,
        'BOTIQUIN': inventario.botiquin,
        'PERNO_SEGURO_RUEDA': inventario.pernoSeguroRueda,
        'AMBIENTADORES': inventario.ambientadores,
        'ESTUCHE_HERRAMIENTA': inventario.estucheHerramienta,
        'DESARMADOR': inventario.desarmador,
        'LLAVE_BOCA_COMBINADA': inventario.llaveBocaCombinada,
        'ALICATE': inventario.alicate,
        'LLAVE_DE_RUEDA': inventario.llaveDeRueda,
        'PALANCA_DE_GATA': inventario.palancaDeGata,
        'GATA': inventario.gata,
        'LLANTA_DE_REPUESTO': inventario.llantaDeRepuesto,
        'TRIANGULO_DE_EMERGENCIA': inventario.trianguloDeEmergencia,
        'MALLA': inventario.malla,
        'ANTENA': inventario.antena,
        'EXTRA': inventario.extra,
        'CABLE_CARGADOR': inventario.cableCargador,
        'CAJA_DE_FUSIBLES': inventario.cajaDeFusibles,
        'EXTINTOR': inventario.extintor,
        'CHALECO_REFLECTIVO': inventario.chalecoReflectivo,
        'CONOS': inventario.conos,
        'EXTENSION': inventario.extension,
      });
      _otrosController.text = inventario.otros;
    } else {
      // Modo creación: obtener opciones del API y cargar inventario previo
      _loadOptionsForNewInventory();
    }
  }

  Future<void> _loadOptionsForNewInventory() async {
    setState(() => _isLoading = true);

    try {
      // Obtener información de la unidad para los parámetros
      final inventarioDetail = await ref.read(
        inventarioDetalleProvider(widget.informacionUnidadId).future,
      );

      // Extraer marca, modelo y versión de la información de la unidad
      final informacionUnidad = inventarioDetail.informacionUnidad;
      final marcaId = informacionUnidad.marca.id;
      final modelo = informacionUnidad.modelo;
      final version = informacionUnidad.version;

      // Llamar al servicio para obtener las opciones usando el provider existente
      final service = ref.read(inventarioBaseServiceProvider);
      final options = await service.getOptions(
        marcaId: marcaId,
        modelo: modelo,
        version: version,
      );

      // Cargar los valores del inventario previo en el formulario
      if (options.inventarioPrevio.isNotEmpty) {
        // Convertir los valores del Map<String, dynamic> a Map<String, int>
        final inventarioPrevio = <String, int>{};
        options.inventarioPrevio.forEach((key, value) {
          if (key != 'OTROS') {
            inventarioPrevio[key] = (value is int)
                ? value
                : int.tryParse(value.toString()) ?? 0;
          }
        });

        _inventarioValues.addAll(inventarioPrevio);

        // Cargar observaciones si existen
        final otros = options.inventarioPrevio['OTROS'];
        if (otros != null && otros.toString().isNotEmpty) {
          _otrosController.text = otros.toString();
        }
      } else {
        // Si no hay inventario previo, inicializar con valores por defecto
        _initializeDefaultValues();
      }

      if (mounted) {
        AppSnackBar.success(context, 'Plantilla de inventario cargada');
      }
    } catch (e) {
      // En caso de error, inicializar con valores por defecto
      _initializeDefaultValues();

      if (mounted) {
        AppSnackBar.warning(context, 'No se pudo cargar la plantilla: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeDefaultValues() {
    const campos = [
      'LLAVE_SIMPLE',
      'LLAVE_COMANDO',
      'LLAVE_INTELIGENTE',
      'ENCENDEDOR',
      'CENICERO',
      'CABLE_USB_O_AUX',
      'RETROVISOR',
      'PISOS',
      'LOGOS',
      'ESTUCHE_MANUAL',
      'MANUALES_ESTUCHE',
      'PIN_DE_REMOLQUE',
      'TAPA_PIN_DE_REMOLQUE',
      'PORTAPLACA',
      'COPAS_TAPAS_DE_AROS',
      'TAPONES_CHASIS',
      'COBERTOR',
      'BOTIQUIN',
      'PERNO_SEGURO_RUEDA',
      'AMBIENTADORES',
      'ESTUCHE_HERRAMIENTA',
      'DESARMADOR',
      'LLAVE_BOCA_COMBINADA',
      'ALICATE',
      'LLAVE_DE_RUEDA',
      'PALANCA_DE_GATA',
      'GATA',
      'LLANTA_DE_REPUESTO',
      'TRIANGULO_DE_EMERGENCIA',
      'MALLA',
      'ANTENA',
      'EXTRA',
      'CABLE_CARGADOR',
      'CAJA_DE_FUSIBLES',
      'EXTINTOR',
      'CHALECO_REFLECTIVO',
      'CONOS',
      'EXTENSION',
    ];

    for (final campo in campos) {
      _inventarioValues[campo] = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          children: [
            // Header fijo
            _buildHeader(),

            const SizedBox(height: 16),

            // Formulario scrolleable
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildFormSection('Llaves y Accesorios', Icons.vpn_key, [
                        'LLAVE_SIMPLE:Llave Simple',
                        'LLAVE_COMANDO:Llave Comando',
                        'LLAVE_INTELIGENTE:Llave Inteligente',
                      ]),

                      _buildFormSection(
                        'Interior',
                        Icons.airline_seat_recline_normal,
                        [
                          'ENCENDEDOR:Encendedor',
                          'CENICERO:Cenicero',
                          'CABLE_USB_O_AUX:Cable USB/AUX',
                          'RETROVISOR:Retrovisor',
                          'PISOS:Pisos',
                          'LOGOS:Logos',
                        ],
                      ),

                      _buildFormSection('Documentación', Icons.description, [
                        'ESTUCHE_MANUAL:Estuche Manual',
                        'MANUALES_ESTUCHE:Manuales en Estuche',
                      ]),

                      _buildFormSection(
                        'Exterior y Carrocería',
                        Icons.directions_car,
                        [
                          'PIN_DE_REMOLQUE:Pin de Remolque',
                          'TAPA_PIN_DE_REMOLQUE:Tapa Pin Remolque',
                          'PORTAPLACA:Portaplaca',
                          'COPAS_TAPAS_DE_AROS:Copas/Tapas de Aros',
                          'TAPONES_CHASIS:Tapones Chasis',
                          'COBERTOR:Cobertor',
                          'ANTENA:Antena',
                        ],
                      ),

                      _buildFormSection(
                        'Herramientas y Emergencia',
                        Icons.build,
                        [
                          'ESTUCHE_HERRAMIENTA:Estuche Herramienta',
                          'DESARMADOR:Desarmador',
                          'LLAVE_BOCA_COMBINADA:Llave Boca Combinada',
                          'ALICATE:Alicate',
                          'LLAVE_DE_RUEDA:Llave de Rueda',
                          'PALANCA_DE_GATA:Palanca de Gata',
                          'GATA:Gata',
                          'LLANTA_DE_REPUESTO:Llanta de Repuesto',
                          'TRIANGULO_DE_EMERGENCIA:Triángulo Emergencia',
                        ],
                      ),

                      _buildFormSection('Seguridad y Extras', Icons.security, [
                        'BOTIQUIN:Botiquín',
                        'PERNO_SEGURO_RUEDA:Perno Seguro Rueda',
                        'EXTINTOR:Extintor',
                        'CHALECO_REFLECTIVO:Chaleco Reflectivo',
                        'CONOS:Conos',
                        'CABLE_CARGADOR:Cable Cargador',
                        'CAJA_DE_FUSIBLES:Caja de Fusibles',
                      ]),

                      _buildFormSection('Otros', Icons.more_horiz, [
                        'MALLA:Malla',
                        'AMBIENTADORES:Ambientadores',
                        'EXTRA:Extra',
                        'EXTENSION:Extensión',
                      ]),

                      const SizedBox(height: 16),

                      // Campo de observaciones
                      _buildOtrosField(),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),

            // Botones fijos en el bottom
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            formTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildFormSection(String title, IconData icon, List<String> campos) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ...campos.map((campo) {
              final parts = campo.split(':');
              final fieldKey = parts[0];
              final fieldLabel = parts[1];
              return _buildNumberField(fieldKey, fieldLabel);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(String fieldKey, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),

          const SizedBox(width: 16),

          Row(
            children: [
              // Botón decrementar
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neutral),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: IconButton(
                  onPressed: () => _decrementValue(fieldKey),
                  icon: const Icon(Icons.remove, size: 16),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),

              // Campo de número como Text
              Container(
                width: 60,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: AppColors.neutral),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${_inventarioValues[fieldKey] ?? 0}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Botón incrementar
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neutral),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: IconButton(
                  onPressed: () => _incrementValue(fieldKey),
                  icon: const Icon(Icons.add, size: 16),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtrosField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Observaciones',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _otrosController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Agregar observaciones adicionales...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.neutral)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(submitButtonText),
            ),
          ),
        ],
      ),
    );
  }

  void _incrementValue(String fieldKey) {
    setState(() {
      _inventarioValues[fieldKey] = (_inventarioValues[fieldKey] ?? 0) + 1;
    });
  }

  void _decrementValue(String fieldKey) {
    setState(() {
      final currentValue = _inventarioValues[fieldKey] ?? 0;
      if (currentValue > 0) {
        _inventarioValues[fieldKey] = currentValue - 1;
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(
        inventarioDetalleProvider(widget.informacionUnidadId).notifier,
      );

      // Preparar datos del formulario
      final inventarioData = Map<String, dynamic>.from(_inventarioValues);
      inventarioData['OTROS'] = _otrosController.text.trim();
      if (isEditMode) {
        await notifier.updateInventario(inventarioData);
        if (mounted) {
          AppSnackBar.success(context, 'Inventario actualizado exitosamente');
        }
      } else {
        await notifier.createInventario(inventarioData);
        if (mounted) {
          AppSnackBar.success(context, 'Inventario creado exitosamente');
        }
      }

      // Llamar callback y cerrar formulario
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
