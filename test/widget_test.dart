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

void main() {
  testWidgets('Home screen shows app title and bottom navigation', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = GasStationRepository(
      service: _FakeCneFuelPriceService(),
      bundledStationsLoader: ({bundle}) async => [
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
    );
    await tester.pumpWidget(PrecioBencinaApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('PrecioBencina'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Lista'), findsOneWidget);
    expect(find.text('Filtros'), findsOneWidget);
  });
}
