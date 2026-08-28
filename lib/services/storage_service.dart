import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/giorno.dart';

/// Salva e carica lo storico delle giornate (e i relativi giri) in locale.
///
/// Usato sia dall'isolate della UI sia dall'isolate del servizio in
/// background: entrambi passano dallo stesso plugin `shared_preferences`,
/// quindi è sicuro leggerne/scriverne lo stato da entrambi i lati finché le
/// operazioni non si sovrappongono (il servizio scrive solo quando cambia
/// qualcosa, throttlato lato chiamante).
class StorageService {
  static const _chiaveGiorni = 'giorni';

  static final DateFormat _formatoData = DateFormat('yyyy-MM-dd');

  static String chiaveDataOdierna() => _formatoData.format(DateTime.now());

  static String chiaveData(DateTime data) => _formatoData.format(data);

  Future<List<Giorno>> caricaGiorni() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chiaveGiorni);
    if (raw == null || raw.isEmpty) return [];
    final lista = jsonDecode(raw) as List<dynamic>;
    return lista
        .map((g) => Giorno.fromJson(g as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  Future<void> salvaGiorni(List<Giorno> giorni) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(giorni.map((g) => g.toJson()).toList());
    await prefs.setString(_chiaveGiorni, raw);
  }

  /// Aggiorna (o inserisce) una singola giornata nello storico persistito.
  Future<void> upsertGiorno(Giorno giorno) async {
    final giorni = await caricaGiorni();
    final indice = giorni.indexWhere((g) => g.data == giorno.data);
    if (indice >= 0) {
      giorni[indice] = giorno;
    } else {
      giorni.add(giorno);
    }
    await salvaGiorni(giorni);
  }

  Future<Giorno?> caricaGiorno(String data) async {
    final giorni = await caricaGiorni();
    for (final g in giorni) {
      if (g.data == data) return g;
    }
    return null;
  }
}
