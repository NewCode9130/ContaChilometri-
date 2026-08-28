// Test di fumo: verifica che l'app si costruisca senza eccezioni e mostri
// l'indicatore di caricamento finché il controller di tracciamento non è
// ancora inizializzato.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:contachilometri/main.dart';
import 'package:contachilometri/state/tracking_controller.dart';

void main() {
  testWidgets('mostra il caricamento prima dell\'inizializzazione', (
    WidgetTester tester,
  ) async {
    final controller = TrackingController();

    await tester.pumpWidget(ContaChilometriApp(controller: controller));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
