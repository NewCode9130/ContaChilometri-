# ContaChilometri

App Flutter (Android/iOS) che conta i km percorsi in bus, dall'inizio di un
giro fino alla fine della giornata lavorativa, funzionando anche a schermo
spento.

## Come funziona

- **Avvia giro**: inizia a registrare la posizione GPS e accumula i km
  percorsi.
- **Ferma giro**: interrompe il conteggio del giro corrente, ma i km restano
  sommati al totale della giornata. Si può avviare un nuovo giro in
  qualsiasi momento: i km si aggiungono allo stesso totale, finché non
  cambia la data.
- **KM di oggi**: totale km di tutti i giri fatti nella giornata corrente,
  aggiornato in tempo reale.
- **Storico giornate**: elenco di tutte le giornate registrate, con il
  dettaglio dei singoli giri (orario di inizio/fine e km).

Tutti i dati restano salvati solo sul telefono (nessun server, nessun
account).

## Funzionamento a schermo spento

- **Android**: il tracciamento gira in un *foreground service* con notifica
  persistente ("Oggi: X km"), il meccanismo standard Android per continuare
  a ricevere aggiornamenti GPS anche a schermo spento o con l'app in
  background.
- **iOS**: il tracciamento continua grazie alla modalità background
  "location" di iOS, che mantiene attivo il flusso di posizione anche ad
  app in background/schermo spento, finché l'app non viene chiusa
  manualmente dall'utente (limite imposto dal sistema operativo, non
  aggirabile).

In entrambi i casi è necessario concedere il permesso di localizzazione
**"Consenti sempre"** (non solo "Consenti durante l'uso"), altrimenti il
conteggio si ferma quando l'app va in background. L'app lo richiede
automaticamente al primo avvio di un giro; se il telefono lo nega o lo
degrada nel tempo, va riabilitato manualmente da Impostazioni > App >
ContaChilometri > Autorizzazioni > Posizione.

Su Android, se il telefono ha un'ottimizzazione batteria aggressiva (es.
Xiaomi/MIUI, Huawei, Samsung), disattivala per questa app (Impostazioni >
Batteria > ContaChilometri > "Nessuna restrizione"), altrimenti il sistema
potrebbe terminare il servizio in background dopo un po'.

## Come compilare ed eseguire

Serve l'[SDK Flutter](https://docs.flutter.dev/get-started/install) (canale
`stable`) e, per Android, Android Studio con l'Android SDK; per iOS, Xcode
su macOS.

```bash
flutter pub get

# Su un dispositivo/emulatore Android collegato:
flutter run -d android

# Su un dispositivo/simulatore iOS (richiede macOS + Xcode):
flutter run -d ios
```

Per generare l'APK da installare direttamente sul telefono:

```bash
flutter build apk --release
# file generato in build/app/outputs/flutter-apk/app-release.apk
```

## Struttura del progetto

```
lib/
  main.dart                       Avvio app
  models/
    giorno.dart                   Una giornata lavorativa (insieme di giri)
    giro.dart                     Un singolo giro (tratta) tracciato
  services/
    background_service.dart       Foreground service Android per il GPS
    location_math.dart            Logica di accumulo/filtro distanza GPS
    storage_service.dart          Persistenza locale (SharedPreferences)
  state/
    tracking_controller.dart      Stato di tracciamento condiviso dalla UI
  screens/
    home_screen.dart              Schermata principale (avvia/ferma, km di oggi)
    history_screen.dart           Storico giornate
    giorno_detail_screen.dart     Dettaglio giri di una giornata
```

## Note

- Il calcolo dei km è basato sulla somma delle distanze tra letture GPS
  successive (filtrando spostamenti minimi, dovuti al rumore GPS da fermo,
  e salti anomali di segnale): è quindi una stima accurata ma non un
  valore da contachilometri certificato.
- Questo ambiente di sviluppo non ha l'Android SDK installato, quindi la
  build APK non è stata verificata end-to-end qui: sono stati eseguiti
  `flutter analyze` (nessun problema) e `flutter test` (test di fumo
  superato). Prima del primo utilizzo reale, si consiglia di lanciare
  `flutter run -d android` su un telefono per un giro di prova.
