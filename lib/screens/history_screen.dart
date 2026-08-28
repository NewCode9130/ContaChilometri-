import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/giorno.dart';
import '../services/storage_service.dart';
import 'giorno_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = StorageService();
  late Future<List<Giorno>> _futureGiorni;

  @override
  void initState() {
    super.initState();
    _futureGiorni = _storage.caricaGiorni();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storico giornate')),
      body: FutureBuilder<List<Giorno>>(
        future: _futureGiorni,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final giorni = snapshot.data!;
          if (giorni.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nessuna giornata registrata ancora.\nAvvia il tuo primo giro dalla schermata principale.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: giorni.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, indice) {
              final giorno = giorni[indice];
              final data = DateTime.parse(giorno.data);
              return ListTile(
                leading: const Icon(Icons.directions_bus),
                title: Text(DateFormat('EEEE d MMMM yyyy', 'it_IT').format(data)),
                subtitle: Text(
                  giorno.giri.length == 1
                      ? '1 giro'
                      : '${giorno.giri.length} giri',
                ),
                trailing: Text(
                  '${giorno.totaleKm.toStringAsFixed(1)} km',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GiornoDetailScreen(giorno: giorno),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
