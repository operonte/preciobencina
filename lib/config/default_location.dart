/// Punto de referencia usado cuando no hay ubicación del usuario (GPS
/// denegado o apagado) ni un lugar buscado: el centro de Santiago
/// (Providencia).
///
/// Sin este valor, [GasStationRepository] recibiría `latitude`/`longitude`
/// nulos y devolvería las estaciones en el orden natural de la API de la
/// CNE (de norte a sur), mostrando bencineras de Iquique como si fueran
/// "cercanas" a cualquier usuario que no comparta su ubicación. Con este
/// punto de referencia, la distancia mostrada es real y la app puede
/// avisar explícitamente qué zona está mostrando (ver `_ReferencePlaceChip`
/// en `home_screen.dart`).
const defaultLatitude = -33.4280;
const defaultLongitude = -70.6150;
const defaultLocationLabel = 'Santiago (Providencia)';
