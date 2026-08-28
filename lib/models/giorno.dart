import 'giro.dart';

/// Una giornata lavorativa: raggruppa tutti i "giri" fatti in bus in quel
/// giorno. Il totale km della giornata è la somma dei km di ogni giro.
class Giorno {
  /// Data della giornata in formato yyyy-MM-dd, usata anche come chiave
  /// univoca per il salvataggio.
  final String data;
  final List<Giro> giri;

  Giorno({required this.data, List<Giro>? giri}) : giri = giri ?? [];

  double get totaleKm => giri.fold(0.0, (somma, g) => somma + g.distanzaKm);

  Duration get durataTotale =>
      giri.fold(Duration.zero, (somma, g) => somma + g.durata);

  bool get inCorso => giri.isNotEmpty && giri.last.inCorso;

  Map<String, dynamic> toJson() => {
        'data': data,
        'giri': giri.map((g) => g.toJson()).toList(),
      };

  factory Giorno.fromJson(Map<String, dynamic> json) => Giorno(
        data: json['data'] as String,
        giri: (json['giri'] as List<dynamic>)
            .map((g) => Giro.fromJson(g as Map<String, dynamic>))
            .toList(),
      );
}
