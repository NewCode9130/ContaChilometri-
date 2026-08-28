import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import '../models/giorno.dart';
import '../models/giro.dart';
import 'location_math.dart';
import 'storage_service.dart';

/// Nome degli eventi scambiati tra la UI e il servizio in background
/// (usati sia lato invoke sia lato listener, per non sbagliare a scriverli).
class ComandiServizio {
  static const avvia = 'avvia';
  static const ferma = 'ferma';
  static const richiediStato = 'richiediStato';
  static const aggiornamento = 'aggiornamento';
}

/// Configura il plugin flutter_background_service. Va chiamato una sola
/// volta, in main(), prima di runApp().
///
/// Su Android il tracciamento GPS gira in un isolate separato, ospitato da
/// un vero e proprio "foreground service" con notifica persistente: questo
/// è ciò che permette ad Android di continuare a fornire aggiornamenti di
/// posizione anche a schermo spento o con l'app in background, senza che il
/// sistema operativo interrompa il processo per risparmiare batteria.
Future<void> inizializzaServizioBackground() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: avvioServizio,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'contachilometri_tracking',
      initialNotificationTitle: 'ContaChilometri',
      initialNotificationContent: 'In attesa di avvio del giro',
      foregroundServiceNotificationId: 990,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: avvioServizio,
      onBackground: _fallbackIos,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> _fallbackIos(ServiceInstance service) async {
  return true;
}

/// Entry point eseguito nell'isolate del servizio in background.
///
/// NB: gira in un isolate diverso da quello della UI, quindi non condivide
/// stato Dart con essa: ogni comunicazione passa da `service.invoke`/`on`
/// oppure dallo storage condiviso (SharedPreferences).
@pragma('vm:entry-point')
void avvioServizio(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final storage = StorageService();
  final accumulatore = AccumulatoreDistanza();
  StreamSubscription<Position>? sottoscrizionePosizione;
  Position? ultimaPosizione;
  Giorno? giornoCorrente;
  Giro? giroCorrente;
  DateTime? ultimoSalvataggio;

  Future<void> pubblicaAggiornamento({required bool inCorso}) async {
    service.invoke(ComandiServizio.aggiornamento, {
      'totaleKmOggi': giornoCorrente?.totaleKm ?? 0.0,
      'kmGiroCorrente': accumulatore.kmAccumulati,
      'inCorso': inCorso,
    });
  }

  Future<void> avviaTracking() async {
    final dataOggi = StorageService.chiaveDataOdierna();
    giornoCorrente =
        await storage.caricaGiorno(dataOggi) ?? Giorno(data: dataOggi);
    giroCorrente = Giro(inizio: DateTime.now());
    giornoCorrente!.giri.add(giroCorrente!);
    await storage.upsertGiorno(giornoCorrente!);

    accumulatore.azzera();
    ultimaPosizione = null;
    ultimoSalvataggio = null;

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    await sottoscrizionePosizione?.cancel();
    const impostazioniPosizione = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 8,
    );
    sottoscrizionePosizione = Geolocator.getPositionStream(
      locationSettings: impostazioniPosizione,
    ).listen((posizione) async {
      if (ultimaPosizione != null) {
        final distanzaMetri = Geolocator.distanceBetween(
          ultimaPosizione!.latitude,
          ultimaPosizione!.longitude,
          posizione.latitude,
          posizione.longitude,
        );
        if (accumulatore.aggiungiSpostamentoMetri(distanzaMetri)) {
          giroCorrente!.distanzaKm = accumulatore.kmAccumulati;
        }
      }
      ultimaPosizione = posizione;

      await pubblicaAggiornamento(inCorso: true);

      if (service is AndroidServiceInstance) {
        final totale = giornoCorrente!.totaleKm;
        service.setForegroundNotificationInfo(
          title: 'ContaChilometri - giro in corso',
          content: 'Oggi: ${totale.toStringAsFixed(1)} km',
        );
      }

      final ora = DateTime.now();
      if (ultimoSalvataggio == null ||
          ora.difference(ultimoSalvataggio!) > const Duration(seconds: 15)) {
        ultimoSalvataggio = ora;
        await storage.upsertGiorno(giornoCorrente!);
      }
    });
  }

  Future<void> fermaTracking() async {
    await sottoscrizionePosizione?.cancel();
    sottoscrizionePosizione = null;

    if (giroCorrente != null && giornoCorrente != null) {
      giroCorrente!.fine = DateTime.now();
      await storage.upsertGiorno(giornoCorrente!);
    }

    await pubblicaAggiornamento(inCorso: false);

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'ContaChilometri',
        content: 'In pausa - tocca "Avvia" per riprendere',
      );
    }

    giroCorrente = null;
  }

  service.on(ComandiServizio.avvia).listen((_) => avviaTracking());
  service.on(ComandiServizio.ferma).listen((_) async {
    await fermaTracking();
    service.stopSelf();
  });
  service.on(ComandiServizio.richiediStato).listen((_) {
    pubblicaAggiornamento(inCorso: giroCorrente != null);
  });
}

/// Facciata usata dalla UI per pilotare il servizio in background senza
/// conoscerne i dettagli implementativi.
class BackgroundServiceController {
  final _service = FlutterBackgroundService();

  Stream<Map<String, dynamic>?> get aggiornamenti =>
      _service.on(ComandiServizio.aggiornamento);

  Future<bool> isRunning() => _service.isRunning();

  Future<void> avvia() async {
    if (!await _service.isRunning()) {
      await _service.startService();
      // Piccola attesa per dare tempo all'isolate di registrare i listener
      // prima di inviargli il comando.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    _service.invoke(ComandiServizio.avvia);
  }

  Future<void> ferma() async {
    if (await _service.isRunning()) {
      _service.invoke(ComandiServizio.ferma);
    }
  }

  Future<void> richiediStato() async {
    if (await _service.isRunning()) {
      _service.invoke(ComandiServizio.richiediStato);
    }
  }
}
