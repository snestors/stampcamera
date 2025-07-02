import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampcamera/models/autos/inventario_model.dart';
import 'package:stampcamera/providers/autos/inventario_provider.dart';

class InventarioTabWidget extends ConsumerWidget {
  final InventarioBaseResponse response;
  final int informacionUnidadId;

  const InventarioTabWidget({
    super.key,
    required this.response,
    required this.informacionUnidadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!response.hasInventario) {
      return _buildEmptyState(context, ref);
    }

    return _buildInventarioContent(context, ref);
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'No hay inventario registrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Esta unidad aún no tiene un inventario creado.\nPuedes crear uno ahora.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () => _showInventarioForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Crear Inventario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003B5C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventarioContent(BuildContext context, WidgetRef ref) {
    final inventario = response.inventario!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Secciones de inventario con cantidades siempre visibles
        _buildInventarioSection('Llaves y Accesorios', Icons.vpn_key, [
          _buildInventarioItem('Llave Simple', inventario.llaveSimple),
          _buildInventarioItem('Llave Comando', inventario.llaveComando),
          _buildInventarioItem(
            'Llave Inteligente',
            inventario.llaveInteligente,
          ),
        ]),

        const SizedBox(height: 16),

        _buildInventarioSection('Interior', Icons.airline_seat_recline_normal, [
          _buildInventarioItem('Encendedor', inventario.encendedor),
          _buildInventarioItem('Cenicero', inventario.cenicero),
          _buildInventarioItem('Cable USB/AUX', inventario.cableUsbOAux),
          _buildInventarioItem('Retrovisor', inventario.retrovisor),
          _buildInventarioItem('Pisos', inventario.pisos),
          _buildInventarioItem('Logos', inventario.logos),
        ]),

        const SizedBox(height: 16),

        _buildInventarioSection('Documentación', Icons.description, [
          _buildInventarioItem('Estuche Manual', inventario.estucheManual),
          _buildInventarioItem(
            'Manuales en Estuche',
            inventario.manualesEstuche,
          ),
        ]),

        const SizedBox(height: 16),

        _buildInventarioSection('Exterior y Carrocería', Icons.directions_car, [
          _buildInventarioItem('Pin de Remolque', inventario.pinDeRemolque),
          _buildInventarioItem(
            'Tapa Pin Remolque',
            inventario.tapaPinDeRemolque,
          ),
          _buildInventarioItem('Portaplaca', inventario.portaplaca),
          _buildInventarioItem(
            'Copas/Tapas de Aros',
            inventario.copasTapasDeAros,
          ),
          _buildInventarioItem('Tapones Chasis', inventario.taponesChasis),
          _buildInventarioItem('Cobertor', inventario.cobertor),
          _buildInventarioItem('Antena', inventario.antena),
        ]),

        const SizedBox(height: 16),

        _buildInventarioSection('Herramientas y Emergencia', Icons.build, [
          _buildInventarioItem(
            'Estuche Herramienta',
            inventario.estucheHerramienta,
          ),
          _buildInventarioItem('Desarmador', inventario.desarmador),
          _buildInventarioItem(
            'Llave Boca Combinada',
            inventario.llaveBocaCombinada,
          ),
          _buildInventarioItem('Alicate', inventario.alicate),
          _buildInventarioItem('Llave de Rueda', inventario.llaveDeRueda),
          _buildInventarioItem('Palanca de Gata', inventario.palancaDeGata),
          _buildInventarioItem('Gata', inventario.gata),
          _buildInventarioItem(
            'Llanta de Repuesto',
            inventario.llantaDeRepuesto,
          ),
          _buildInventarioItem(
            'Triángulo Emergencia',
            inventario.trianguloDeEmergencia,
          ),
        ]),

        const SizedBox(height: 16),

        _buildInventarioSection('Seguridad y Extras', Icons.security, [
          _buildInventarioItem('Botiquín', inventario.botiquin),
          _buildInventarioItem(
            'Perno Seguro Rueda',
            inventario.pernoSeguroRueda,
          ),
          _buildInventarioItem('Extintor', inventario.extintor),
          _buildInventarioItem(
            'Chaleco Reflectivo',
            inventario.chalecoReflectivo,
          ),
          _buildInventarioItem('Conos', inventario.conos),
          _buildInventarioItem('Cable Cargador', inventario.cableCargador),
          _buildInventarioItem('Caja de Fusibles', inventario.cajaDeFusibles),
        ]),

        const SizedBox(height: 16),

        _buildInventarioSection('Otros', Icons.more_horiz, [
          _buildInventarioItem('Malla', inventario.malla),
          _buildInventarioItem('Ambientadores', inventario.ambientadores),
          _buildInventarioItem('Extra', inventario.extra),
          _buildInventarioItem('Extensión', inventario.extension),
        ]),

        if (inventario.otros.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildOtrosSection(inventario.otros),
        ],

        const SizedBox(height: 24),

        // Botón de editar
        Center(
          child: ElevatedButton.icon(
            onPressed: () =>
                _showInventarioForm(context, ref, inventario: inventario),
            icon: const Icon(Icons.edit),
            label: const Text('Editar Inventario'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003B5C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildInventarioSection(
    String title,
    IconData icon,
    List<Widget> items,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF003B5C), size: 20),
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

            const SizedBox(height: 12),

            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildInventarioItem(String name, int quantity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),

          // Siempre mostrar la cantidad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: quantity > 0
                  ? Colors.green.shade100
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: quantity > 0
                    ? Colors.green.shade300
                    : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: quantity > 0
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtrosSection(String otros) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note, color: Color(0xFF003B5C), size: 20),
                SizedBox(width: 8),
                Text(
                  'Observaciones',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(otros, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showInventarioForm(
    BuildContext context,
    WidgetRef ref, {
    InventarioBase? inventario,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InventarioFormWidget(
        informacionUnidadId: informacionUnidadId,
        inventario: inventario, // null = crear, no null = editar
        onSaved: () {
          // Refrescar la data del inventario
          ref.refresh(inventarioDetalleProvider(informacionUnidadId));
        },
      ),
    );
  }
}

// ============================================================================
// FORMULARIO DE INVENTARIO
// ============================================================================

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
      // Inicializar con valores por defecto (0)
      _initializeDefaultValues();
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
                Icon(icon, color: const Color(0xFF003B5C), size: 20),
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
            }).toList(),
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
                  border: Border.all(color: Colors.grey.shade300),
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
                    horizontal: BorderSide(color: Colors.grey.shade300),
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
                  border: Border.all(color: Colors.grey.shade300),
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
                Icon(Icons.note, color: Color(0xFF003B5C), size: 20),
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
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                backgroundColor: const Color(0xFF003B5C),
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
      print(isEditMode);
      if (isEditMode) {
        await notifier.updateInventario(inventarioData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Inventario actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await notifier.createInventario(inventarioData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Inventario creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Llamar callback y cerrar formulario
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
