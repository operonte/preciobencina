import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/gas_station.dart';
import '../models/place_suggestion.dart';
import '../repositories/gas_station_repository.dart';
import '../services/favorites_service.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';
import 'filter_screen.dart';
import 'home_screen.dart';
import 'list_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, this.repository});

  /// Repositorio a usar. Permite inyectar uno de prueba (por ejemplo en
  /// tests de widgets, para evitar cargar el snapshot real de estaciones).
  final GasStationRepository? repository;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;
  FuelType _selectedFuel = FuelType.gas95;
  SortOrder _sortOrder = SortOrder.price;
  String _searchQuery = '';
  late final _repository = widget.repository ?? GasStationRepository();
  final _locationService = LocationService();
  final _favoritesService = FavoritesService();
  final _geocodingService = GeocodingService();
  GasStationsResult? _result;
  Position? _userPosition;
  Set<String> _favoriteIds = {};

  /// Lugar elegido por el usuario en el buscador, usado como punto de
  /// referencia en vez del GPS. `null` significa "usar mi ubicación".
  PlaceSuggestion? _referencePlace;
  List<PlaceSuggestion> _suggestions = [];
  Timer? _suggestionsDebounce;

  @override
  void initState() {
    super.initState();
    _loadStations();
    _loadFavorites();
  }

  @override
  void dispose() {
    _suggestionsDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadStations() async {
    final position = await _locationService.getCurrentPosition();
    final reference = _referencePlace;
    final result = await _repository.fetchNearbyStations(
      latitude: reference?.latitude ?? position?.latitude,
      longitude: reference?.longitude ?? position?.longitude,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _userPosition = position;
    });
  }

  Future<void> _loadFavorites() async {
    final favoriteIds = await _favoritesService.getFavoriteIds();
    if (!mounted) return;
    setState(() => _favoriteIds = favoriteIds);
  }

  Future<void> _toggleFavorite(String stationId) async {
    final favoriteIds = await _favoritesService.toggleFavorite(stationId);
    if (!mounted) return;
    setState(() => _favoriteIds = favoriteIds);
  }

  /// Actualiza el texto de búsqueda y, si parece una dirección o lugar,
  /// busca sugerencias en segundo plano (con un pequeño retraso para no
  /// consultar en cada tecla).
  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);

    _suggestionsDebounce?.cancel();
    if (value.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _suggestionsDebounce = Timer(const Duration(milliseconds: 400), () async {
      final suggestions = await _geocodingService.search(value);
      if (!mounted) return;
      setState(() => _suggestions = suggestions);
    });
  }

  /// El usuario eligió un lugar sugerido: lo usamos como nuevo punto de
  /// referencia y recargamos las estaciones cercanas a ese lugar.
  Future<void> _selectPlace(PlaceSuggestion place) async {
    _suggestionsDebounce?.cancel();
    setState(() {
      _referencePlace = place;
      _suggestions = [];
      _searchQuery = '';
      _result = null;
    });
    await _loadStations();
  }

  /// Vuelve a usar la ubicación GPS del usuario como referencia.
  Future<void> _useMyLocation() async {
    setState(() {
      _referencePlace = null;
      _result = null;
    });
    await _loadStations();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result == null) {
      return const LoadingView();
    }

    final userPosition = _userPosition;
    final referencePlace = _referencePlace;
    final refLatitude = referencePlace?.latitude ?? userPosition?.latitude;
    final refLongitude = referencePlace?.longitude ?? userPosition?.longitude;
    final stations = result.stations.map((station) {
      if (refLatitude == null ||
          refLongitude == null ||
          station.latitude == null ||
          station.longitude == null) {
        return station;
      }
      final meters = Geolocator.distanceBetween(
        refLatitude,
        refLongitude,
        station.latitude!,
        station.longitude!,
      );
      return station.copyWithDistance(meters / 1000);
    }).toList();

    final query = _searchQuery.trim().toLowerCase();
    final filteredStations = stations.where((station) {
      if (station.fuelType != _selectedFuel) return false;
      if (query.isEmpty) return true;
      return station.name.toLowerCase().contains(query) ||
          station.address.toLowerCase().contains(query);
    }).toList();
    final cheapest = filteredStations.cheapestOrNull;

    final screens = [
      HomeScreen(
        stations: filteredStations,
        cheapest: cheapest,
        searchQuery: _searchQuery,
        onSearchChanged: _onSearchChanged,
        suggestions: _suggestions,
        onSuggestionSelected: _selectPlace,
        referencePlaceLabel: referencePlace?.label,
        onUseMyLocation: _useMyLocation,
        onRefresh: _loadStations,
        favoriteIds: _favoriteIds,
        onToggleFavorite: _toggleFavorite,
        userLatitude: userPosition?.latitude,
        userLongitude: userPosition?.longitude,
        focusLatitude: referencePlace?.latitude,
        focusLongitude: referencePlace?.longitude,
      ),
      ListScreen(
        stations: filteredStations,
        cheapest: cheapest,
        sortOrder: _sortOrder,
        onRefresh: _loadStations,
        favoriteIds: _favoriteIds,
        onToggleFavorite: _toggleFavorite,
      ),
      FilterScreen(
        selectedFuel: _selectedFuel,
        sortOrder: _sortOrder,
        onFuelChanged: (fuel) => setState(() => _selectedFuel = fuel),
        onSortOrderChanged: (order) => setState(() => _sortOrder = order),
        onApply: () => setState(() => _index = 1),
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          if (!result.isLiveData)
            _DataSourceBanner(result: result, onRetry: _loadStations),
          Expanded(
            child: IndexedStack(index: _index, children: screens),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Lista',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_outlined),
            activeIcon: Icon(Icons.tune),
            label: 'Filtros',
          ),
        ],
      ),
    );
  }
}

/// Aviso visible cuando no se están mostrando datos en vivo de la CNE:
/// indica si se trata de la última caché guardada o de datos de ejemplo.
class _DataSourceBanner extends StatelessWidget {
  const _DataSourceBanner({required this.result, required this.onRetry});

  final GasStationsResult result;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (result.source) {
      DataSource.cached =>
        'Sin conexión: mostrando precios guardados${_cachedAtSuffix()}',
      DataSource.bundled =>
        'Mostrando precios de referencia (pueden no estar actualizados)',
      DataSource.mock =>
        'Mostrando datos de ejemplo mientras se cargan los '
            'precios reales',
      DataSource.live => '',
    };

    return Container(
      width: double.infinity,
      color: AppColors.primary.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.primaryDark),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: AppColors.primaryDark,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  String _cachedAtSuffix() {
    final cachedAt = result.cachedAt;
    if (cachedAt == null) return '';
    final h = cachedAt.hour.toString().padLeft(2, '0');
    final m = cachedAt.minute.toString().padLeft(2, '0');
    return ' (actualizados $h:$m)';
  }
}
