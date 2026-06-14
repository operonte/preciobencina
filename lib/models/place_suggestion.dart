/// Un lugar sugerido por el buscador de direcciones (ciudad, comuna,
/// dirección, etc.), con sus coordenadas para centrar el mapa.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  /// Nombre legible del lugar, ej. "Providencia, Santiago, Chile".
  final String label;
  final double latitude;
  final double longitude;
}
