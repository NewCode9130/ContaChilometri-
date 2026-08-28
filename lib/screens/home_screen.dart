import 'package:flutter/material.dart';

import '../state/tracking_controller.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  final TrackingController controller;

  const HomeScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ContaChilometri'),
        actions: [
          IconButton(
            tooltip: 'Storico giornate',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (!controller.inizializzato) {
            return const Center(child: CircularProgressIndicator());
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  _CartaKmOggi(controller: controller),
                  const SizedBox(height: 16),
                  if (controller.inCorso) _CartaGiroCorrente(controller: controller),
                  const Spacer(),
                  if (controller.erroreUltimoAvvio != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        controller.erroreUltimoAvvio!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  _PulsanteTracking(controller: controller),
                  const SizedBox(height: 8),
                  Text(
                    controller.inCorso
                        ? 'Tocca per fermare il giro (i km restano contati per oggi)'
                        : 'Tocca per iniziare a contare i km del prossimo giro',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CartaKmOggi extends StatelessWidget {
  final TrackingController controller;

  const _CartaKmOggi({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 0,
      color: tema.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            Text(
              'KM DI OGGI',
              style: tema.textTheme.labelLarge?.copyWith(
                color: tema.colorScheme.onPrimaryContainer,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.totaleKmOggi.toStringAsFixed(1),
              style: tema.textTheme.displayLarge?.copyWith(
                color: tema.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'km',
              style: tema.textTheme.titleMedium?.copyWith(
                color: tema.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaGiroCorrente extends StatelessWidget {
  final TrackingController controller;

  const _CartaGiroCorrente({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.directions_bus, color: tema.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          'Giro in corso: ${controller.kmGiroCorrente.toStringAsFixed(1)} km',
          style: tema.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _PulsanteTracking extends StatelessWidget {
  final TrackingController controller;

  const _PulsanteTracking({required this.controller});

  @override
  Widget build(BuildContext context) {
    final inCorso = controller.inCorso;
    final tema = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: inCorso ? tema.colorScheme.error : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          if (inCorso) {
            await controller.ferma();
          } else {
            await controller.avvia();
          }
        },
        icon: Icon(inCorso ? Icons.stop_circle_outlined : Icons.play_circle_outline),
        label: Text(inCorso ? 'FERMA GIRO' : 'AVVIA GIRO'),
      ),
    );
  }
}
