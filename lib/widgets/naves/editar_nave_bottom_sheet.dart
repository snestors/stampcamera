import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stampcamera/core/core.dart';
import 'package:stampcamera/models/naves/berthing_model.dart';
import 'package:stampcamera/providers/naves/berthings_provider.dart';

/// Bottom sheet para editar estatus y fechas de una nave (berthing).
/// Compartido por Autos (inventario) y Graneles (servicio dashboard).
///
/// Carga internamente los datos actuales (estatus + fechas) desde
/// `GET /api/v1/berthings/{naveId}/` así que la callsite solo necesita
/// el id y el nombre para mostrar en el header.
///
/// Devuelve `true` si se guardaron cambios, `null/false` si se canceló.
Future<bool?> showEditarNaveBottomSheet(
  BuildContext context, {
  required int naveId,
  required String naveNombre,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EditarNaveForm(
      naveId: naveId,
      naveNombre: naveNombre,
    ),
  );
}

class _EditarNaveForm extends ConsumerStatefulWidget {
  final int naveId;
  final String naveNombre;

  const _EditarNaveForm({
    required this.naveId,
    required this.naveNombre,
  });

  @override
  ConsumerState<_EditarNaveForm> createState() => _EditarNaveFormState();
}

class _EditarNaveFormState extends ConsumerState<_EditarNaveForm> {
  BerthingEstatus? _estatusInicial;
  BerthingEstatus? _estatus;
  DateTime? _fechaArribo;
  DateTime? _fechaAtraque;
  DateTime? _fechaFinOperacion;
  bool _saving = false;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    try {
      final service = ref.read(berthingsServiceProvider);
      final detalle = await service.getBerthing(widget.naveId);
      if (!mounted) return;
      setState(() {
        _estatusInicial = detalle.estatus;
        _estatus = detalle.estatus;
        _fechaArribo = detalle.fechaArribo;
        _fechaAtraque = detalle.fechaAtraque;
        _fechaFinOperacion = detalle.fechaFinOperacion;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spaceM),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHandle(),
              const SizedBox(height: DesignTokens.spaceM),
              _buildHeader(),
              const SizedBox(height: DesignTokens.spaceL),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(DesignTokens.spaceL),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceM),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(height: DesignTokens.spaceS),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: DesignTokens.spaceM),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _loadError = null;
                });
                _cargarDetalle();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final optionsAsync = ref.watch(berthingsFormOptionsProvider);
    return optionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(DesignTokens.spaceL),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceM),
        child: Text(
          'Error al cargar opciones: $err',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (options) => _buildForm(options),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.neutral,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.directions_boat, color: AppColors.primary, size: 24),
        const SizedBox(width: DesignTokens.spaceS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Editar estado de nave',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: DesignTokens.fontSizeL,
                ),
              ),
              Text(
                widget.naveNombre,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BerthingsFormOptions options) {
    final transiciones = options.transicionesDesde(_estatusInicial);
    final opcionesMostrar = <BerthingEstatus>{
      if (_estatusInicial != null) _estatusInicial!,
      ...transiciones,
    }.toList();

    final soloActual = transiciones.isEmpty ||
        (transiciones.length == 1 && transiciones.first == _estatusInicial);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Estatus
        const Text(
          'Estado',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceXS),
        DropdownButtonFormField<BerthingEstatus>(
          initialValue: _estatus,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: soloActual
                ? AppColors.surface.withValues(alpha: 0.5)
                : AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceM,
              vertical: DesignTokens.spaceS,
            ),
          ),
          style: const TextStyle(
            fontSize: DesignTokens.fontSizeM,
            color: AppColors.textPrimary,
          ),
          items: opcionesMostrar
              .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
              .toList(),
          onChanged: soloActual ? null : (v) => setState(() => _estatus = v),
        ),
        if (soloActual && _estatusInicial != null) ...[
          const SizedBox(height: DesignTokens.spaceXS),
          Text(
            _estatusInicial == BerthingEstatus.finalizado ||
                    _estatusInicial == BerthingEstatus.cancelado
                ? 'Este estado es terminal y no puede cambiarse'
                : 'No hay transiciones disponibles desde este estado',
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.spaceL),

        // Fechas
        _DateTimeField(
          label: 'Fecha de arribo',
          value: _fechaArribo,
          onChanged: (v) => setState(() => _fechaArribo = v),
          clearable: true,
        ),
        const SizedBox(height: DesignTokens.spaceM),
        _DateTimeField(
          label: 'Fecha de atraque *',
          value: _fechaAtraque,
          onChanged: (v) => setState(() => _fechaAtraque = v),
          clearable: false,
        ),
        const SizedBox(height: DesignTokens.spaceM),
        _DateTimeField(
          label: 'Fecha fin de operación',
          value: _fechaFinOperacion,
          onChanged: (v) => setState(() => _fechaFinOperacion = v),
          clearable: true,
        ),
        const SizedBox(height: DesignTokens.spaceL),

        // Botones
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.spaceM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: DesignTokens.spaceM),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.spaceM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceS),
      ],
    );
  }

  Future<void> _guardar() async {
    if (_fechaAtraque == null) {
      AppSnackBar.error(context, 'La fecha de atraque es obligatoria');
      return;
    }

    setState(() => _saving = true);

    try {
      final service = ref.read(berthingsServiceProvider);
      await service.updateBerthing(
        widget.naveId,
        BerthingUpdatePayload(
          estatus: _estatus != _estatusInicial ? _estatus : null,
          fechaArribo: _fechaArribo,
          fechaAtraque: _fechaAtraque,
          fechaFinOperacion: _fechaFinOperacion,
        ),
      );

      if (!mounted) return;
      AppSnackBar.success(context, 'Nave actualizada');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

/// Campo de fecha+hora reutilizable interno.
class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool clearable;

  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.clearable,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final text = value != null ? formatter.format(value!) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceXS),
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceM,
              vertical: DesignTokens.spaceM - 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(color: AppColors.neutral),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: DesignTokens.spaceS),
                Expanded(
                  child: Text(
                    text.isEmpty ? 'Seleccionar…' : text,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      color: text.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (clearable && value != null)
                  GestureDetector(
                    onTap: () => onChanged(null),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = value ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}
