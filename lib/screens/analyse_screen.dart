import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/dagboek_provider.dart';
import '../models/analyse_resultaat.dart';
import '../models/dagboek_entry.dart';
import 'grafiek_view.dart';
import '../widgets/home_button.dart';

class AnalyseScreen extends StatefulWidget {
  const AnalyseScreen({super.key});

  @override
  State<AnalyseScreen> createState() => _AnalyseScreenState();
}

class _AnalyseScreenState extends State<AnalyseScreen> {
  String _selectedPeriod = 'all'; // all, week, month

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gezondheids Analyse'),
        actions: const [
          HomeButton(),
        ],
      ),
      body: Consumer<DagboekProvider>(
        builder: (context, provider, child) {
          if (provider.dagboekEntries.isEmpty) {
            return const GeenDataView();
          }

          final entries = _filterEntriesByPeriod(provider.dagboekEntries);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Periode selectie
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodButton('Alles', 'all'),
                      _buildPeriodButton('Week', 'week'),
                      _buildPeriodButton('Maand', 'month'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Analyse knop
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: provider.isAnalyseBezig
                          ? null
                          : () => provider.voerAnalyseUit(),
                      icon: provider.isAnalyseBezig
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.white),
                      label: Text(
                        provider.isAnalyseBezig ? 'Systeem analyseert...' : 'Start Medische Analyse',
                        style: const TextStyle(letterSpacing: 0.5, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Eczeem overzicht
                _buildEczeemOverzicht(entries),
                const SizedBox(height: 24),

                // Analyse resultaten
                if (provider.huidigAnalyseResultaat != null) ...[
                  _buildAnalysisResults(provider.huidigAnalyseResultaat!, entries),
                  const SizedBox(height: 32),
                  
                  // Grafieken
                  if (provider.huidigAnalyseResultaat!.dagData.isNotEmpty ||
                      provider.huidigAnalyseResultaat!.weekData.isNotEmpty ||
                      provider.huidigAnalyseResultaat!.maandData.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'TREND ANALYSE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    GrafiekenView(
                      dagData: provider.huidigAnalyseResultaat!.dagData,
                      weekData: provider.huidigAnalyseResultaat!.weekData,
                      maandData: provider.huidigAnalyseResultaat!.maandData,
                      topAllergen: provider.huidigAnalyseResultaat!.topAllergen,
                    ),
                  ],
                ] else
                  const InfoCard(
                    icoon: Icons.insights_rounded,
                    titel: 'Krijg diepere inzichten',
                    beschrijving:
                        'Druk op de knop hierboven om AI-analyse te starten. We zoeken naar onzichtbare patronen tussen je voeding en symptomen.',
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected 
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  List<DagboekEntry> _filterEntriesByPeriod(List<DagboekEntry> entries) {
    final now = DateTime.now();
    
    if (_selectedPeriod == 'week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return entries.where((e) => e.datum.isAfter(weekAgo)).toList();
    } else if (_selectedPeriod == 'month') {
      final monthAgo = now.subtract(const Duration(days: 30));
      return entries.where((e) => e.datum.isAfter(monthAgo)).toList();
    }
    
    return entries;
  }

  Widget _buildAnalysisResults(AnalyseResultaat resultaat, List<DagboekEntry> entries) {
    if (resultaat.correlaties.isEmpty) {
      return const InfoCard(
        icoon: Icons.info,
        titel: 'Onvoldoende data',
        beschrijving: 'Nog niet genoeg data om betrouwbare eczeem-triggers te identificeren.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patronen (Alleen patronen tonen zoals gevraagd)
        if (resultaat.patronen.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'GEDETECTEERDE PATRONEN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 1.0,
              ),
            ),
          ),
          ...resultaat.patronen.map((p) => PatroonCard(patroon: p)),
          const SizedBox(height: 16),
        ],

        // Klinisch Beeld Overview
        _buildKlinischOverzicht(entries),
        const SizedBox(height: 16),

        // Medisch Disclaimer & Bronnen
        _buildMedischeSectie(resultaat),
      ],
    );
  }

  Widget _buildMedischeSectie(AnalyseResultaat resultaat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Disclaimer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medische Disclaimer',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dit AI-advies is gebaseerd op statistische correlaties in jouw data. Het is geen medisch advies. Raadpleeg bij twijfel of ernstige klachten altijd een arts of specialist.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[900], height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Bronnen
        if (resultaat.medicalSources.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'BETROUWBARE BRONNEN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 1.0,
              ),
            ),
          ),
          ...resultaat.medicalSources.map((bron) => _buildBronCard(bron)),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildBronCard(MedischeBron bron) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(bron.titel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(bron.instantie, style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(bron.beschrijving, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.open_in_new_rounded, size: 18, color: Color(0xFF64748B)),
        ),
        onTap: () async {
          final uri = Uri.parse(bron.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  Widget _buildEczeemOverzicht(List<DagboekEntry> entries) {
    if (entries.isEmpty) {
      return const InfoCard(
        icoon: Icons.info_outline_rounded,
        titel: 'Geen data',
        beschrijving: 'Geen data beschikbaar voor deze periode.',
      );
    }

    final allMetrics = entries.expand((e) => e.gezondheidsMetrics).toList();
    if (allMetrics.isEmpty) {
      return const InfoCard(
        icoon: Icons.info_outline_rounded,
        titel: 'Geen gezondheidsdata',
        beschrijving: 'Voeg gezondheidsgegevens toe om analyse te zien.',
      );
    }

    final eczeemErnstig = allMetrics.map((m) => m.eczeemErnstig).toList();
    final eczeemJeuken = allMetrics.map((m) => m.eczeemJeuken).toList();

    final gemErnstig = eczeemErnstig.reduce((a, b) => a + b) / eczeemErnstig.length;
    final gemJeuken = eczeemJeuken.reduce((a, b) => a + b) / eczeemJeuken.length;
    final gemEczeem = (gemErnstig + gemJeuken) / 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.query_stats_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Gemiddelde Symptoomscore',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEczeemStat('ERNSTIG', gemErnstig, Colors.red[400]!),
              _buildEczeemStat('JEUK', gemJeuken, Colors.orange[400]!),
              _buildEczeemStat('TOTAAL', gemEczeem, Theme.of(context).colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEczeemStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label, 
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blueGrey[300], letterSpacing: 0.5)
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(width: 2),
              Text(
                '/10', 
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.withOpacity(0.5))
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKlinischOverzicht(List<DagboekEntry> entries) {
    final metrics = entries.expand((e) => e.gezondheidsMetrics).toList();
    if (metrics.isEmpty) return const SizedBox.shrink();

    final avgRed = metrics.isEmpty ? 0.0 : metrics.map((m) => m.roodheid).reduce((a, b) => a + b) / metrics.length;
    final avgDry = metrics.isEmpty ? 0.0 : metrics.map((m) => m.droogheid).reduce((a, b) => a + b) / metrics.length;
    final avgScale = metrics.isEmpty ? 0.0 : metrics.map((m) => m.schilfering).reduce((a, b) => a + b) / metrics.length;
    final medDays = metrics.where((m) => m.medicatieGebruikt).length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🩺 Specialist Gezondheidsoverzicht',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildKlinischRow('Roodheid', avgRed, Colors.red),
            _buildKlinischRow('Droogheid', avgDry, Colors.blue),
            _buildKlinischRow('Schilfering', avgScale, Colors.brown),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.medication, size: 20, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'Behandeling: $medDays van de ${metrics.length} dagen medicatie gebruikt.',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKlinischRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text('${value.toStringAsFixed(1)}/10', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 10,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class GeenDataView extends StatelessWidget {
  const GeenDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nog geen data',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Voeg eerst voedsel en gezondheidsdata toe om analyse te kunnen uitvoeren.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class DataOverzichtCard extends StatelessWidget {
  final int aantalEntries;

  const DataOverzichtCard({super.key, required this.aantalEntries});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Overzicht',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _OverzichtItem(icoon: Icons.calendar_today, waarde: '$aantalEntries', label: 'Dagen'),
                _OverzichtItem(icoon: Icons.restaurant, waarde: '~${aantalEntries * 3}', label: 'Maaltijden'),
                _OverzichtItem(icoon: Icons.favorite, waarde: '~${aantalEntries * 2}', label: 'Metrics'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverzichtItem extends StatelessWidget {
  final IconData icoon;
  final String waarde;
  final String label;

  const _OverzichtItem({
    required this.icoon,
    required this.waarde,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icoon, color: Colors.blue, size: 32),
        const SizedBox(height: 8),
        Text(
          waarde,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class AnalyseResultatenView extends StatelessWidget {
  final AnalyseResultaat resultaat;
  final List<DagboekEntry> entries;

  const AnalyseResultatenView({
    super.key,
    required this.resultaat,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overzicht van bevindingen
        _BevindingenOverzicht(
          aanbevelingen: resultaat.aanbevelingen,
          correlaties: resultaat.correlaties,
          patronen: resultaat.patronen,
        ),
        const SizedBox(height: 24),

        // Top correlaties visueel
        if (resultaat.correlaties.isNotEmpty) ...[
          const Text(
            'Voedsel & Gezondheid Koppeling',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _CorrelatiesSamenvatting(correlaties: resultaat.correlaties),
          const SizedBox(height: 16),
          _TopCorrelatiesVisueel(correlaties: resultaat.correlaties.take(5).toList()),
          const SizedBox(height: 20),
        ],

        // Gedetailleerde correlaties
        if (resultaat.correlaties.isNotEmpty) ...[
          const Text(
            'Gedetailleerde Correlaties',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...resultaat.correlaties.map((correlatie) => CorrelatieCard(correlatie: correlatie)),
          const SizedBox(height: 20),
        ],

        // Patronen
        if (resultaat.patronen.isNotEmpty) ...[
          const Text(
            'Patronen in Gegevens',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...resultaat.patronen.map((patroon) => PatroonCard(patroon: patroon)),
          const SizedBox(height: 20),
        ],

        // Info footer
        const InfoCard(
          icoon: Icons.info,
          titel: 'Over deze analyse',
          beschrijving:
              'Deze analyse is gebaseerd op de voedings- en gezondheidsdata die je hebt ingevoerd. Hoe meer data, hoe nauwkeuriger de patronen.',
        ),
      ],
    );
  }
}

class CorrelatieCard extends StatelessWidget {
  final Correlatie correlatie;

  const CorrelatieCard({super.key, required this.correlatie});

  Color _kleurVoorSterkte(double sterkte) {
    if (sterkte > 0.6) return Colors.red;
    if (sterkte > 0.3) return Colors.orange;
    return Colors.green;
  }

  IconData _iconVoorSterkte(double sterkte, String symptoom) {
    if (sterkte > 0.3) return Icons.warning_rounded;
    if (sterkte < -0.3) return Icons.thumb_up_rounded;
    return Icons.help_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final kleur = _kleurVoorSterkte(correlatie.correlatieSterkte);
    final icon = _iconVoorSterkte(correlatie.correlatieSterkte, correlatie.symptoom);
    final percentage = (correlatie.correlatieSterkte.abs() * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: kleur == Colors.green ? Colors.green[50] : (kleur == Colors.orange ? Colors.orange[50] : Colors.red[50]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kleur.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: kleur, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        correlatie.voedselItem,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        correlatie.symptoom,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kleur.withAlpha(100),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: kleur,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              correlatie.beschrijving,
              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: correlatie.correlatieSterkte.abs(),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(kleur),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatroonCard extends StatelessWidget {
  final Patroon patroon;

  const PatroonCard({super.key, required this.patroon});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patroon.beschrijving),
                  const SizedBox(height: 4),
                  Text(
                    'Frequentie: ${patroon.frequentie}x • Betrouwbaarheid: ${(patroon.betrouwbaarheid * 100).toInt()}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icoon;
  final String titel;
  final String beschrijving;

  const InfoCard({
    super.key,
    required this.icoon,
    required this.titel,
    required this.beschrijving,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icoon, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    beschrijving,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CorrelatiesSamenvatting extends StatelessWidget {
  final List<Correlatie> correlaties;

  const _CorrelatiesSamenvatting({required this.correlaties});

  @override
  Widget build(BuildContext context) {
    final poitieveCorrelaties = correlaties.where((c) => c.correlatieSterkte > 0.3).toList();
    final negatievelatiaties = correlaties.where((c) => c.correlatieSterkte < -0.3).toList();

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${negatievelatiaties.length}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const Text('Voorzorgsmaatregelen', style: TextStyle(fontSize: 12, color: Colors.red)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${poitieveCorrelaties.length}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const Text('Aanbevolen', style: TextStyle(fontSize: 12, color: Colors.green)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${correlaties.length}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    const Text('Totaal', style: TextStyle(fontSize: 12, color: Colors.orange)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BevindingenOverzicht extends StatelessWidget {
  final List<String> aanbevelingen;
  final List<Correlatie> correlaties;
  final List<Patroon> patronen;

  const _BevindingenOverzicht({
    required this.aanbevelingen,
    required this.correlaties,
    required this.patronen,
  });

  @override
  Widget build(BuildContext context) {
    final poitieveVoedsel = correlaties.where((c) => c.correlatieSterkte < -0.3).length;
    final negatieveVoedsel = correlaties.where((c) => c.correlatieSterkte > 0.3).length;

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights, color: Colors.green, size: 24),
                SizedBox(width: 12),
                Text(
                  'Analyse Samenvatting',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${patronen.length}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Text('Patronen', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '$poitieveVoedsel',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const Text('Positief', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '$negatieveVoedsel',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const Text('Voorzorg', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCorrelatiesVisueel extends StatelessWidget {
  final List<Correlatie> correlaties;

  const _TopCorrelatiesVisueel({required this.correlaties});

  Color _getColorForSterkte(double sterkte) {
    if (sterkte > 0.5) return Colors.red;
    if (sterkte > 0.3) return Colors.orange;
    if (sterkte < -0.5) return Colors.green;
    if (sterkte < -0.3) return Colors.lightGreen;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sterkste Verbanden:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            ...correlaties.map((correlatie) {
              final percentage = (correlatie.correlatieSterkte.abs() * 100).toInt();
              final color = _getColorForSterkte(correlatie.correlatieSterkte);
              final isPositive = correlatie.correlatieSterkte > 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                correlatie.voedselItem,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${isPositive ? '⬆️ Verhoogt' : '⬇️ Verlaagt'} ${correlatie.symptoom}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withAlpha(50),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$percentage%',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: correlatie.correlatieSterkte.abs(),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class DagenOverzichtCard extends StatelessWidget {
  final List<DagboekEntry> entries;

  const DagenOverzichtCard({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEntries = [...entries]..sort((a, b) => b.datum.compareTo(a.datum));

    return Card(
      elevation: 2,
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dagelijkse Overzicht',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedEntries.length,
              separatorBuilder: (_, __) => const Divider(height: 8),
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                final ingredienten = entry.voedselEntries
                    .map((v) => v.beschrijving)
                    .join(', ');
                
                final eczeem = entry.gezondheidsMetrics.isNotEmpty
                    ? entry.gezondheidsMetrics.first
                    : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Datum
                    Text(
                      '${entry.datum.day} ${_getMaandNaam(entry.datum.month)} ${entry.datum.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Ingrediënten
                    if (ingredienten.isNotEmpty)
                      Text(
                        '🍽️ $ingredienten',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Eczeem
                    if (eczeem != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '🔴 Eczeem: Ernstig ${eczeem.eczeemErnstig}/10 • Jeuk ${eczeem.eczeemJeuken}/10',
                          style: TextStyle(fontSize: 12, color: Colors.red[700]),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getMaandNaam(int maand) {
    const maanden = [
      'januari', 'februari', 'maart', 'april', 'mei', 'juni',
      'juli', 'augustus', 'september', 'oktober', 'november', 'december'
    ];
    return maanden[maand - 1];
  }
}
