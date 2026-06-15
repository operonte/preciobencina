import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'repositories/gas_station_repository.dart';
import 'screens/main_scaffold.dart';
import 'theme/app_theme.dart';

/// Inicializa Firebase (Crashlytics, Analytics, App Check). Si algo falla
/// (por ejemplo, un dispositivo sin Play Services), la app sigue
/// funcionando igual, solo sin esas métricas/protecciones.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidPlayIntegrityProvider(),
      providerApple: const AppleAppAttestProvider(),
    );

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (error) {
    developer.log('No se pudo inicializar Firebase: $error', name: 'main');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();

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
      navigatorObservers: [
        if (Firebase.apps.isNotEmpty)
          FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      home: MainScaffold(repository: repository),
    );
  }
}
