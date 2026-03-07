import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dagboek_entry.dart';
import '../models/voedsel_entry.dart';
import '../models/gezondheids_metric.dart';
import 'bewerk_screen.dart';
import '../widgets/home_button.dart';

class DagboekDetailScreen extends StatelessWidget {
  final DagboekEntry entry;

  const DagboekDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          const HomeButton(),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BewerkScreen(entry: entry),
                ),
              );
            },
            tooltip: 'Bewerken',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Datum header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.geformateerdeDatum,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    entry.dagVanWeek,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Voedsel sectie
            if (entry.voedselEntries.isNotEmpty) ...[
              const Text(
                'Voedsel & Drinken',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...entry.voedselEntries.map((ve) => VoedselEntryCard(entry: ve)),
              const SizedBox(height: 20),
            ],

            // Gezondheid sectie
            if (entry.gezondheidsMetrics.isNotEmpty) ...[
              const Text(
                'Gezondheid',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...entry.gezondheidsMetrics.map((gm) => GezondheidsMetricCard(metric: gm)),
            ],
          ],
        ),
      ),
    );
  }
}

class VoedselEntryCard extends StatelessWidget {
  final VoedselEntry entry;

  const VoedselEntryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(entry.categorie.icoon, color: entry.categorie.kleur),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.categorie.naam,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        entry.beschrijving,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat.Hm().format(entry.tijdstip),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
            if (entry.ingredienten.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ingrediënten: ${entry.ingredienten.join(", ")}',
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline),
              ),
            ],
            if (entry.notities != null && entry.notities!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.notities!,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GezondheidsMetricCard extends StatelessWidget {
  final GezondheidsMetric metric;

  const GezondheidsMetricCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gezondheidscheck',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  DateFormat.Hm().format(metric.tijdstip),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MetricRij(naam: '🔴 Ernstig', waarde: metric.eczeemErnstig, kleur: Colors.red),
            const SizedBox(height: 8),
            _MetricRij(naam: '🟠 Jeuk', waarde: metric.eczeemJeuken, kleur: Colors.orange),
            const SizedBox(height: 8),
            _MetricRij(naam: '🟡 Mild', waarde: metric.eczeemMild, kleur: Colors.yellow[700]!),
            const SizedBox(height: 8),
            _MetricRij(naam: '🟢 Rustig', waarde: metric.geenEczeem, kleur: Colors.green),
            const SizedBox(height: 8),
            _MetricRij(naam: '🔵 Slaap', waarde: metric.slaapKwaliteit, kleur: Colors.blue),
            if (metric.notities != null && metric.notities!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                metric.notities!,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricRij extends StatelessWidget {
  final String naam;
  final int waarde;
  final Color kleur;

  const _MetricRij({
    required this.naam,
    required this.waarde,
    required this.kleur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(naam, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: waarde / 10,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: kleur,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 25,
          child: Text(
            '$waarde',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
