import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';
import 'services/background_service.dart';
import 'state/tracking_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT');

  if (!kIsWeb && Platform.isAndroid) {
    await inizializzaServizioBackground();
  }

  final controller = TrackingController();
  await controller.inizializza();

  runApp(ContaChilometriApp(controller: controller));
}

class ContaChilometriApp extends StatelessWidget {
  final TrackingController controller;

  const ContaChilometriApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ContaChilometri',
      debugShowCheckedModeBanner: false,
      locale: const Locale('it', 'IT'),
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1F6FEB),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF1F6FEB),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: HomeScreen(controller: controller),
    );
  }
}
