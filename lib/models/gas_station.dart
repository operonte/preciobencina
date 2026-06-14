/// Tipos de combustible disponibles.
enum FuelType { gas93, gas95, gas97, diesel, glp }

extension FuelTypeLabel on FuelType {
  String get label {
    switch (this) {
      case FuelType.gas93:
        return '93';
      case FuelType.gas95:
        return '95';
      case FuelType.gas97:
        return '97';
      case FuelType.diesel:
        return 'Diésel';
      case FuelType.glp:
        return 'GLP';
    }
  }

  /// Unidad en la que se expresa el precio: litro para combustibles
  /// líquidos, metro cúbico para el GLP.
  String get unit => this == FuelType.glp ? 'm³' : 'L';

  /// Descripción corta del tipo de combustible (ej. "95 octanos", "Diésel",
  /// "GLP"), usada en la ficha de detalle de una estación.
  String get description {
    switch (this) {
      case FuelType.gas93:
      case FuelType.gas95:
      case FuelType.gas97:
        return '$label octanos';
      case FuelType.diesel:
      case FuelType.glp:
        return label;
    }
  }

  /// Texto que acompaña al precio en las tarjetas (ej. "95 oct./L",
  /// "Diésel/L", "GLP/m³").
  String get unitLabel {
    switch (this) {
      case FuelType.gas93:
      case FuelType.gas95:
      case FuelType.gas97:
        return '$label oct./$unit';
      case FuelType.diesel:
      case FuelType.glp:
        return '$label/$unit';
    }
  }
}

/// Para cada [FuelType], las claves del mapa `precios` de la API de la CNE
/// que pueden representarlo, en orden de preferencia. Se prefiere el precio
/// de autoservicio (prefijo "A") cuando la estación lo ofrece.
const _fuelPriceKeys = {
  FuelType.gas93: ['A93', '93'],
  FuelType.gas95: ['A95', '95'],
  FuelType.gas97: ['A97', '97'],
  FuelType.diesel: ['ADI', 'DI'],
  FuelType.glp: ['GLP'],
};

/// Convierte la fecha/hora de actualización de un precio de la CNE (formato
/// `yyyy-MM-dd` + `HH:mm:ss`) en un texto relativo y amigable como
/// "hace 5 min" o "hace 2 días". Si no se puede interpretar, devuelve la
/// fecha cruda o "sin fecha" si no hay información.
String _relativeUpdate(String? fecha, String? hora) {
  if (fecha == null || fecha.isEmpty) return 'sin fecha';

  final updated = DateTime.tryParse('$fecha ${hora ?? '00:00:00'}');
  if (updated == null) return fecha;

  final diff = DateTime.now().difference(updated);
  if (diff.isNegative || diff.inMinutes < 1) return 'hace un momento';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) {
    return 'hace ${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'}';
  }
  final days = diff.inDays;
  if (days < 7) return 'hace $days ${days == 1 ? 'día' : 'días'}';
  return fecha;
}

/// Representa una estación de servicio con su precio para un combustible.
class GasStation {
  final String id;
  final String name;
  final String address;
  final double distanceKm;
  final FuelType fuelType;
  final double price;
  final String lastUpdated;

  /// Coordenadas geográficas reales, si están disponibles (API CNE).
  final double? latitude;
  final double? longitude;

  const GasStation({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.fuelType,
    required this.price,
    required this.lastUpdated,
    this.latitude,
    this.longitude,
  });

  String get formattedPrice => '\$${price.toStringAsFixed(0)}';

  /// Devuelve una copia de esta estación con [distanceKm] actualizada
  /// (usada al calcular la distancia real a partir de la ubicación del
  /// usuario).
  GasStation copyWithDistance(double distanceKm) => GasStation(
    id: id,
    name: name,
    address: address,
    distanceKm: distanceKm,
    fuelType: fuelType,
    price: price,
    lastUpdated: lastUpdated,
    latitude: latitude,
    longitude: longitude,
  );

  /// Crea una [GasStation] por cada combustible vigente en [station], un
  /// elemento del array devuelto por `GET /api/v4/estaciones` de la CNE.
  ///
  /// Cada estación reporta varios precios a la vez (uno por combustible) en
  /// su mapa `precios`, así que una sola estación puede producir varias
  /// [GasStation] (una por cada [FuelType] disponible).
  static List<GasStation> fromCneStation(Map<String, dynamic> station) {
    final ubicacion = Map<String, dynamic>.from(
      station['ubicacion'] as Map? ?? const {},
    );
    final precios = Map<String, dynamic>.from(
      station['precios'] as Map? ?? const {},
    );
    final codigo = station['codigo']?.toString() ?? '';
    final marca =
        (station['distribuidor'] as Map?)?['marca']?.toString() ??
        'Sin bandera';

    final direccion = ubicacion['direccion']?.toString().trim() ?? '';
    final comuna = ubicacion['nombre_comuna']?.toString();
    final address = [
      direccion,
      comuna,
    ].where((p) => p != null && p.isNotEmpty).join(', ');

    final latitude = double.tryParse(ubicacion['latitud']?.toString() ?? '');
    final longitude = double.tryParse(ubicacion['longitud']?.toString() ?? '');

    final stations = <GasStation>[];
    for (final entry in _fuelPriceKeys.entries) {
      for (final key in entry.value) {
        final priceInfo = precios[key];
        if (priceInfo is! Map) continue;

        final price = double.tryParse(
          priceInfo['precio']?.toString().replaceAll(',', '.') ?? '',
        );
        if (price == null) continue;

        final fecha = priceInfo['fecha_actualizacion']?.toString();
        final hora = priceInfo['hora_actualizacion']?.toString();
        final lastUpdated = _relativeUpdate(fecha, hora);

        stations.add(
          GasStation(
            id: '$codigo-${entry.key.name}',
            name: marca,
            address: address,
            distanceKm: 0,
            fuelType: entry.key,
            price: price,
            lastUpdated: lastUpdated,
            latitude: latitude,
            longitude: longitude,
          ),
        );
        break;
      }
    }
    return stations;
  }

  /// Serializa esta estación para guardarla en caché local.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'distanceKm': distanceKm,
    'fuelType': fuelType.name,
    'price': price,
    'lastUpdated': lastUpdated,
    'latitude': latitude,
    'longitude': longitude,
  };

  /// Reconstruye una [GasStation] desde un mapa generado por [toJson].
  factory GasStation.fromJson(Map<String, dynamic> json) => GasStation(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    distanceKm: (json['distanceKm'] as num).toDouble(),
    fuelType: FuelType.values.byName(json['fuelType'] as String),
    price: (json['price'] as num).toDouble(),
    lastUpdated: json['lastUpdated'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}

/// Criterios de orden disponibles en la pantalla de filtros.
enum SortOrder { price, distance }

extension GasStationListX on List<GasStation> {
  /// La estación con el precio más bajo de la lista.
  GasStation get cheapest => reduce((a, b) => a.price < b.price ? a : b);

  /// La estación con el precio más bajo, o `null` si la lista está vacía.
  GasStation? get cheapestOrNull => isEmpty ? null : cheapest;
}
