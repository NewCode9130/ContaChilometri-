/// Un singolo "giro" (tratta) percorso in bus: da quando l'autista preme
/// Avvia/Riprendi a quando preme Pausa/Termina.
class Giro {
  final DateTime inizio;
  DateTime? fine;
  double distanzaKm;

  Giro({
    required this.inizio,
    this.fine,
    this.distanzaKm = 0,
  });

  bool get inCorso => fine == null;

  Duration get durata => (fine ?? DateTime.now()).difference(inizio);

  Map<String, dynamic> toJson() => {
        'inizio': inizio.toIso8601String(),
        'fine': fine?.toIso8601String(),
        'distanzaKm': distanzaKm,
      };

  factory Giro.fromJson(Map<String, dynamic> json) => Giro(
        inizio: DateTime.parse(json['inizio'] as String),
        fine: json['fine'] != null ? DateTime.parse(json['fine'] as String) : null,
        distanzaKm: (json['distanzaKm'] as num).toDouble(),
      );
}
