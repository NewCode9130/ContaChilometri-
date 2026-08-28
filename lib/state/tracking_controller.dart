import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/giorno.dart';
import '../models/giro.dart';
import '../services/background_service.dart';
import '../services/location_math.dart';
import '../services/storage_service.dart';

/// Stato del tracciamento, condiviso da tutta l'app.
///
/// Su Android il lavoro vero (stream GPS, accumulo km, notifica) avviene nel
/// servizio in background (vedi `background_service.dart`): questo
/// controller si limita ad avviarlo/fermarlo e a rispecchiarne lo stato.
///
/// Su iOS non serve un servizio separato: basta mantenere attivo lo stream
/// di posizione con `allowBackgroundLocationUpdates`, perché il sistema
/// operativo continua a consegnarlo all'app anche a schermo spento finché il
/// modo background "location" è dichiarato in Info.plist e l'app non viene
/// chiusa manualmente dall'utente.
class TrackingController extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final BackgroundServiceController _servizioAndroid =
      BackgroundServiceController();

  StreamSubscription<Map<String, dynamic>?>? _sottoscrizioneAggiornamenti;
  StreamSubscription<Position>? _sottoscrizionePosizioneIos;
  final AccumulatoreDistanza _accumulatoreIos = AccumulatoreDistanza();
  Position? _ultimaPosizioneIos;
  Giorno? _giornoCorrenteIos;
  Giro? _giroCorrenteIos;

  double totaleKmOggi = 0;
  double kmGiroCorrente = 0;
  bool inCorso = false;
  bool inizializzato = false;
  String? erroreUltimoAvvio;

  bool get _usaServizioAndroid => !kIsWeb && Platform.isAndroid;

  Future<void> inizializza() async {
    if (_usaServizioAndroid) {
      _sottoscrizioneAggiornamenti = _servizioAndroid.aggiornamenti.listen(
        (dati) {
          if (dati == null) return;
          totaleKmOggi = (dati['totaleKmOggi'] as num).toDouble();
          kmGiroCorrente = (dati['kmGiroCorrente'] as num).toDouble();
          inCorso = dati['inCorso'] as bool;
          notifyListeners();
        },
      );
      final giaAttivo = await _servizioAndroid.isRunning();
      if (giaAttivo) {
        await _servizioAndroid.richiediStato();
      }
    }

    final giornoOggi = await _storage.caricaGiorno(
      StorageService.chiaveDataOdierna(),
    );
    if (giornoOggi != null) {
      totaleKmOggi = giornoOggi.totaleKm;
      if (giornoOggi.inCorso) {
        inCorso = true;
        kmGiroCorrente = giornoOggi.giri.last.distanzaKm;
      }
    }

    inizializzato = true;
    notifyListeners();
  }

  Future<bool> _richiediPermessi() async {
    final servizioAttivo = await Geolocator.isLocationServiceEnabled();
    if (!servizioAttivo) {
      erroreUltimoAvvio =
          'Il GPS del telefono è spento. Attivalo dalle impostazioni.';
      return false;
    }

    var permesso = await Geolocator.checkPermission();
    if (permesso == LocationPermission.denied) {
      permesso = await Geolocator.requestPermission();
    }
    if (permesso == LocationPermission.denied ||
        permesso == LocationPermission.deniedForever) {
      erroreUltimoAvvio =
          'Permesso di localizzazione negato. Concedilo dalle impostazioni '
          'dell\'app per poter contare i km.';
      return false;
    }

    // Per continuare a tracciare a schermo spento/app in background serve
    // il permesso "sempre" (Consenti sempre / Always), non solo "durante
    // l'uso dell'app".
    if (permesso == LocationPermission.whileInUse) {
      final semprePermesso = await Permission.locationAlways.request();
      if (!semprePermesso.isGranted) {
        erroreUltimoAvvio =
            'Per contare i km anche a schermo spento seleziona "Consenti '
            'sempre" nel permesso di localizzazione, dalle impostazioni '
            'del telefono.';
        // Non blocchiamo l'avvio: funzionerà comunque finché l'app è in
        // primo piano.
      }
    }

    if (_usaServizioAndroid) {
      await Permission.notification.request();
    }

    erroreUltimoAvvio = null;
    return true;
  }

  Future<bool> avvia() async {
    final ok = await _richiediPermessi();
    if (!ok) {
      notifyListeners();
      return false;
    }

    if (_usaServizioAndroid) {
      await _servizioAndroid.avvia();
    } else {
      await _avviaIos();
    }

    inCorso = true;
    notifyListeners();
    return true;
  }

  Future<void> ferma() async {
    if (_usaServizioAndroid) {
      await _servizioAndroid.ferma();
    } else {
      await _fermaIos();
    }
    inCorso = false;
    notifyListeners();
  }

  Future<void> _avviaIos() async {
    final dataOggi = StorageService.chiaveDataOdierna();
    _giornoCorrenteIos =
        await _storage.caricaGiorno(dataOggi) ?? Giorno(data: dataOggi);
    _giroCorrenteIos = Giro(inizio: DateTime.now());
    _giornoCorrenteIos!.giri.add(_giroCorrenteIos!);
    await _storage.upsertGiorno(_giornoCorrenteIos!);

    _accumulatoreIos.azzera();
    _ultimaPosizioneIos = null;

    await _sottoscrizionePosizioneIos?.cancel();
    final impostazioni = AppleSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 8,
      pauseLocationUpdatesAutomatically: false,
      allowBackgroundLocationUpdates: true,
      showBackgroundLocationIndicator: true,
    );
    _sottoscrizionePosizioneIos =
        Geolocator.getPositionStream(locationSettings: impostazioni).listen(
      (posizione) async {
        if (_ultimaPosizioneIos != null) {
          final distanzaMetri = Geolocator.distanceBetween(
            _ultimaPosizioneIos!.latitude,
            _ultimaPosizioneIos!.longitude,
            posizione.latitude,
            posizione.longitude,
          );
          if (_accumulatoreIos.aggiungiSpostamentoMetri(distanzaMetri)) {
            _giroCorrenteIos!.distanzaKm = _accumulatoreIos.kmAccumulati;
          }
        }
        _ultimaPosizioneIos = posizione;

        totaleKmOggi = _giornoCorrenteIos!.totaleKm;
        kmGiroCorrente = _accumulatoreIos.kmAccumulati;
        notifyListeners();

        await _storage.upsertGiorno(_giornoCorrenteIos!);
      },
    );
  }

  Future<void> _fermaIos() async {
    await _sottoscrizionePosizioneIos?.cancel();
    _sottoscrizionePosizioneIos = null;

    if (_giroCorrenteIos != null && _giornoCorrenteIos != null) {
      _giroCorrenteIos!.fine = DateTime.now();
      await _storage.upsertGiorno(_giornoCorrenteIos!);
      totaleKmOggi = _giornoCorrenteIos!.totaleKm;
    }
    _giroCorrenteIos = null;
  }

  @override
  void dispose() {
    _sottoscrizioneAggiornamenti?.cancel();
    _sottoscrizionePosizioneIos?.cancel();
    super.dispose();
  }
}
