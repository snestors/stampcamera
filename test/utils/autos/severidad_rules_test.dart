import 'package:flutter_test/flutter_test.dart';
import 'package:stampcamera/utils/autos/severidad_rules.dart';

void main() {
  // Catálogo de ejemplo con ids arbitrarios: la regla debe emparejar por
  // NOMBRE, no por id (los ids difieren entre entornos).
  final severidades = [
    {'value': 10, 'label': 'CERO / V3'},
    {'value': 20, 'label': 'LEVE'},
    {'value': 30, 'label': 'FALTANTE'},
    {'value': 40, 'label': 'GRAVE'},
  ];
  final tipos = [
    {'value': 1, 'label': 'FALTANTE'},
    {'value': 2, 'label': 'FLOJO / FALTANTE'},
    {'value': 3, 'label': 'SIN DAÑO'},
    {'value': 4, 'label': 'RAYÓN'},
  ];

  group('reglaSeveridadParaTipo', () {
    test('FALTANTE sin FLOJO fuerza faltante', () {
      expect(reglaSeveridadParaTipo('FALTANTE'), ReglaSeveridad.faltante);
      expect(
        reglaSeveridadParaTipo('EMBLEMA FALTANTE'),
        ReglaSeveridad.faltante,
      );
    });

    test('FLOJO / FALTANTE queda libre', () {
      expect(reglaSeveridadParaTipo('FLOJO / FALTANTE'), isNull);
      expect(reglaSeveridadParaTipo('FLOJO-FALTANTE'), isNull);
    });

    test('SIN DAÑO (con acento) fuerza cero', () {
      expect(reglaSeveridadParaTipo('SIN DAÑO'), ReglaSeveridad.cero);
      expect(reglaSeveridadParaTipo('sin daño'), ReglaSeveridad.cero);
    });

    test('tipo libre y valores nulos/vacíos → null', () {
      expect(reglaSeveridadParaTipo('RAYÓN'), isNull);
      expect(reglaSeveridadParaTipo(null), isNull);
      expect(reglaSeveridadParaTipo(''), isNull);
    });
  });

  group('severidadForzada empareja por nombre', () {
    test('faltante → id de la severidad FALTANTE', () {
      expect(severidadForzada('EMBLEMA FALTANTE', severidades), 30);
    });

    test('cero → id de la severidad que empieza con CERO', () {
      expect(severidadForzada('SIN DAÑO', severidades), 10);
    });

    test('tipo libre → null', () {
      expect(severidadForzada('FLOJO / FALTANTE', severidades), isNull);
      expect(severidadForzada('RAYÓN', severidades), isNull);
    });

    test('regla activa pero sin severidad que empareje → null', () {
      expect(
        severidadForzada('FALTANTE', [
          {'value': 99, 'label': 'LEVE'},
        ]),
        isNull,
      );
    });
  });

  group('severidadForzadaPorTipoId', () {
    test('resuelve el tipo por id y aplica la regla', () {
      expect(severidadForzadaPorTipoId(1, tipos, severidades), 30); // FALTANTE
      expect(severidadForzadaPorTipoId(3, tipos, severidades), 10); // SIN DAÑO
    });

    test('tipo libre por id → null', () {
      expect(
        severidadForzadaPorTipoId(2, tipos, severidades),
        isNull,
      ); // FLOJO/FALTANTE
      expect(severidadForzadaPorTipoId(4, tipos, severidades), isNull); // RAYÓN
    });

    test('id inexistente o null → null', () {
      expect(severidadForzadaPorTipoId(999, tipos, severidades), isNull);
      expect(severidadForzadaPorTipoId(null, tipos, severidades), isNull);
    });
  });
}
