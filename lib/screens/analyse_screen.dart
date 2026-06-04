import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/dagboek_provider.dart';
import '../models/analyse_resultaat.dart';
import '../models/dagboek_entry.dart';
import 'grafiek_view.dart';
import '../widgets/app_logo.dart';
import '../services/ai_analyse_service.dart';

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
        title: const AppLogo(subtitle: 'Analyse'),
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                  
                  // Trend alleen bij voldoende data (≥7 dagen) en een gelogd ingrediënt
                  if (_toonTrendAnalyse(provider.huidigAnalyseResultaat!, entries)) ...[
                    const _SectionLabel('TREND ANALYSE'),
                    GrafiekenView(
                      dagData: provider.huidigAnalyseResultaat!.dagData,
                      weekData: provider.huidigAnalyseResultaat!.weekData,
                      maandData: provider.huidigAnalyseResultaat!.maandData,
                      topAllergen: provider.huidigAnalyseResultaat!.topAllergen,
                      selectedPeriod: _selectedPeriod,
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
            color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected 
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
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

  int _telUniekeDagen(List<DagboekEntry> entries) {
    return entries
        .map((e) => DateTime(e.datum.year, e.datum.month, e.datum.day))
        .toSet()
        .length;
  }

  bool _heeftGenoegData(List<DagboekEntry> entries) {
    return _telUniekeDagen(entries) >= AIAnalyseService.minDagenVoorAnalyse;
  }

  bool _toonTrendAnalyse(AnalyseResultaat resultaat, List<DagboekEntry> entries) {
    if (!_heeftGenoegData(entries)) return false;
    if (resultaat.topAllergen == 'Onbekend') return false;
    return resultaat.dagData.isNotEmpty ||
        resultaat.weekData.isNotEmpty ||
        resultaat.maandData.isNotEmpty;
  }

  Widget _buildAnalysisResults(AnalyseResultaat resultaat, List<DagboekEntry> entries) {
    if (!_heeftGenoegData(entries) || resultaat.correlaties.isEmpty) {
      return InfoCard(
        icoon: Icons.info,
        titel: 'Onvoldoende data',
        beschrijving: _heeftGenoegData(entries)
            ? 'Nog niet genoeg data om betrouwbare eczeem-triggers te identificeren.'
            : 'Log minimaal ${AIAnalyseService.minDagenVoorAnalyse} dagen voedsel en symptomen om betrouwbare triggers en trendanalyse te zien.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patronen (Alleen patronen tonen zoals gevraagd)
        if (resultaat.patronen.isNotEmpty) ...[
          const _SectionLabel('GEDETECTEERDE PATRONEN'),
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
          const _SectionLabel('BETROUWBARE BRONNEN'),
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
            Text(bron.instantie, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              _buildEczeemStat('ECZEEM', gemErnstig, Colors.red[400]!),
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
            color: color.withValues(alpha: 0.1),
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
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.5))
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
              'Gezondheidsoverzicht',
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
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class GeenDataView extends StatelessWidget {
  const GeenDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Nog geen data',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Voeg eerst voedsel en gezondheidsdata toe om analyse te kunnen uitvoeren.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}


class PatroonCard extends StatelessWidget {
  final Patroon patroon;

  const PatroonCard({super.key, required this.patroon});

  @override
  Widget build(BuildContext context) {
    final betrouwbaarheid = (patroon.betrouwbaarheid * 100).toInt();
    final color = betrouwbaarheid >= 70 ? Colors.green : (betrouwbaarheid >= 40 ? Colors.orange : Colors.blueGrey);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: color.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.pattern_rounded, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patroon.beschrijving,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.repeat_rounded, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${patroon.frequentie}× voorkomend',
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$betrouwbaarheid% zekerheid',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                        ),
                      ),
                    ],
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
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      color: primary.withValues(alpha: 0.06),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icoon, color: primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titel,
                    style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    beschrijving,
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
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

