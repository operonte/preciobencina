import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'repositories/gas_station_repository.dart';
import 'screens/main_scaffold.dart';
import 'theme/app_theme.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const PrecioBencinaApp());
}

class PrecioBencinaApp extends StatelessWidget {
  const PrecioBencinaApp({super.key, this.repository});

  /// Repositorio a usar. Permite inyectar uno de prueba (por ejemplo en
  /// tests de widgets, para evitar cargar el snapshot real de estaciones).
  final GasStationRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrecioBencina',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: MainScaffold(repository: repository),
    );
  }
}
