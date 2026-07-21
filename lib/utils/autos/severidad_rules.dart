// =============================================================================
// REGLA DE NEGOCIO: tipo de daño → severidad forzada
// =============================================================================
// Port de frontend/src/pages/autos/severidadRules.ts (repo Django, commit
// c3d45e748). El backend NO impone esta regla (el serializer queda libre a
// propósito), así que la app la replica client-side para que los datos salgan
// correctos. Aplica al CREAR y al EDITAR un daño.
//
// Ciertos tipos de daño determinan la severidad de forma automática:
//   - Tipo "FALTANTE" (pero NO "FLOJO/FALTANTE") → severidad "FALTANTE"
//   - Tipo "SIN DAÑO"                             → severidad "CERO/V3" (cero)
//
// Los tipos "FLOJO/FALTANTE" (moldura/emblema/jebe, hardware) quedan LIBRES:
// pueden ser un daño real (flojo) o un faltante, así que la severidad se elige.
//
// Se empareja por TEXTO del nombre, NO por id: los ids del catálogo no son
// estables entre entornos (dev SQLite vs prod PostgreSQL), pero los nombres sí.

import 'package:stampcamera/core/helpers/formatters/text_formatters.dart';

/// Severidad que un tipo de daño obliga (o `null` si el tipo es libre).
enum ReglaSeveridad { faltante, cero }

/// Normaliza un nombre: sin acentos y en mayúsculas ("SIN DAÑO" → "SIN DANO").
String _normalizar(String s) => TextFormatters.removeAccents(s).toUpperCase();

/// Determina qué severidad fuerza un tipo de daño según su nombre,
/// o `null` si el tipo no dispara ninguna regla (severidad libre).
ReglaSeveridad? reglaSeveridadParaTipo(String? tipoLabel) {
  if (tipoLabel == null || tipoLabel.isEmpty) return null;
  final n = _normalizar(tipoLabel);
  // "FLOJO - FALTANTE" / "FLOJO/FALTANTE" quedan libres (severidad seleccionable).
  if (n.contains('FALTANTE') && !n.contains('FLOJO')) {
    return ReglaSeveridad.faltante;
  }
  if (n.contains('SIN DANO')) return ReglaSeveridad.cero;
  return null;
}

/// Id de la severidad que debe forzarse para un tipo de daño (por su nombre),
/// o `null` si el tipo es libre o no hay una severidad que empareje.
///
/// [severidades] son las opciones del form: mapas con `value` (int) y `label`.
int? severidadForzada(String? tipoLabel, List<dynamic> severidades) {
  final regla = reglaSeveridadParaTipo(tipoLabel);
  if (regla == null) return null;

  for (final s in severidades) {
    final label = _normalizar((s['label'] ?? '').toString());
    final match = switch (regla) {
      ReglaSeveridad.faltante => label == 'FALTANTE',
      ReglaSeveridad.cero => label.startsWith('CERO'),
    };
    if (match) return s['value'] as int?;
  }
  return null;
}

/// Igual que [severidadForzada] pero resolviendo el tipo por su id (busca el
/// nombre en la lista de tipos). Devuelve `null` si el tipo es libre.
///
/// [tipos] y [severidades] son las opciones del form: mapas con `value`/`label`.
int? severidadForzadaPorTipoId(
  int? tipoId,
  List<dynamic> tipos,
  List<dynamic> severidades,
) {
  if (tipoId == null) return null;
  for (final t in tipos) {
    if (t['value'] == tipoId) {
      return severidadForzada((t['label'] ?? '').toString(), severidades);
    }
  }
  return null;
}
