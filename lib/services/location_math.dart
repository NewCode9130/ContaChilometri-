/// Logica di accumulo distanza condivisa tra il tracking in background
/// (Android) e quello in-app (iOS). Isolata qui per essere semplice da
/// verificare e riusare in entrambi i punti.
class AccumulatoreDistanza {
  /// Sotto questa soglia (metri) uno spostamento viene ignorato: è rumore
  /// GPS tipico quando il bus è fermo.
  static const double sogliaMinimaMetri = 3;

  /// Sopra questa soglia (metri) uno spostamento viene ignorato: è quasi
  /// certamente un salto GPS anomalo (es. rimbalzo del segnale) e non un
  /// vero tratto percorso tra due letture ravvicinate.
  static const double sogliaMassimaMetri = 300;

  double _kmAccumulati = 0;

  double get kmAccumulati => _kmAccumulati;

  /// Azzera l'accumulo, ad esempio all'inizio di un nuovo giro.
  void azzera() {
    _kmAccumulati = 0;
  }

  /// Aggiunge uno spostamento (in metri) all'accumulo, applicando i filtri
  /// anti-rumore. Ritorna true se lo spostamento è stato conteggiato.
  bool aggiungiSpostamentoMetri(double distanzaMetri) {
    if (distanzaMetri <= sogliaMinimaMetri || distanzaMetri >= sogliaMassimaMetri) {
      return false;
    }
    _kmAccumulati += distanzaMetri / 1000;
    return true;
  }
}
