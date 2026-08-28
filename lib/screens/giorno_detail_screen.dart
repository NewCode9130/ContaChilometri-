import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/giorno.dart';

class GiornoDetailScreen extends StatelessWidget {
  final Giorno giorno;

  const GiornoDetailScreen({super.key, required this.giorno});

  @override
  Widget build(BuildContext context) {
    final data = DateTime.parse(giorno.data);
    final formatoOra = DateFormat('HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE d MMMM yyyy', 'it_IT').format(data)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${giorno.totaleKm.toStringAsFixed(1)} km totali',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: giorno.giri.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, indice) {
                final giro = giorno.giri[indice];
                final orarioFine =
                    giro.fine != null ? formatoOra.format(giro.fine!) : 'in corso';
                return ListTile(
                  leading: CircleAvatar(child: Text('${indice + 1}')),
                  title: Text('${giro.distanzaKm.toStringAsFixed(1)} km'),
                  subtitle: Text(
                    '${formatoOra.format(giro.inizio)} - $orarioFine',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
