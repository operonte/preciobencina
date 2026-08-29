import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:preciobencina/main.dart';
import 'package:preciobencina/models/gas_station.dart';
import 'package:preciobencina/repositories/gas_station_repository.dart';
import 'package:preciobencina/services/cne_fuel_price_service.dart';

/// Servicio de prueba que no hace llamadas de red reales: simula que no hay
/// datos en vivo (sin `BFF_BASE_URL`), como ocurre en la app real sin
/// configurar.
class _FakeCneFuelPriceService extends CneFuelPriceService {
  @override
  Future<List<Map<String, dynamic>>> fetchStationPrices() async {
    throw CneApiException('sin auth_key');
  }
}

/// Repositorio de prueba: sin datos en vivo (como la app sin `BFF_BASE_URL`
/// configurado), cae al snapshot con una única estación de prueba.
GasStationRepository _testRepository() => GasStationRepository(
  service: _FakeCneFuelPriceService(),
  bundledStationsLoader: ({bundle}) async => (
    stations: [
      const GasStation(
        id: 'bundled-1',
        name: 'Copec de prueba',
        address: 'Av. Siempre Viva 123',
        distanceKm: 0,
        fuelType: FuelType.gas95,
        price: 1234,
        lastUpdated: 'hace 2 días',
      ),
    ],
    generatedAt: DateTime(2026, 8, 1),
  ),
);

void main() {
  testWidgets('Home screen shows app title and bottom navigation', (
    WidgetTester tester,
  ) async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(PrecioBencinaApp(repository: _testRepository()));
    await tester.pumpAndSettle();

    expect(find.text('PrecioBencina'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Lista'), findsOneWidget);
    expect(find.text('Filtros'), findsOneWidget);
  });

  testWidgets('la atribución a la fuente oficial (CNE) siempre está visible', (
    WidgetTester tester,
  ) async {
    // Guardarraíl para la política de Google Play que sacó la app de la
    // tienda: si un refactor borra este link sin querer, este test debe
    // fallar en vez de descubrirlo en la próxima revisión de Play Store.
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    SharedPreferences.setMockInitialValues({});

    // El enlace está al final del contenido del tab Mapa, después del
    // mapa; en el tamaño de pantalla de prueba por defecto queda fuera del
    // viewport y el ListView no lo monta. Se agranda la superficie de
    // prueba para que todo el contenido esté visible sin tener que
    // depender de la heurística de auto-scroll del framework de test.
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(PrecioBencinaApp(repository: _testRepository()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Fuente oficial: Comisión Nacional de Energía'),
      findsOneWidget,
    );
  });

  testWidgets(
    'la pantalla principal cumple contraste y tamaño de tap mínimos',
    (WidgetTester tester) async {
      setupFirebaseCoreMocks();
      await Firebase.initializeApp();
      SharedPreferences.setMockInitialValues({});
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(PrecioBencinaApp(repository: _testRepository()));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    },
  );
}
