import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dagboek_provider.dart';
import '../models/dagboek_entry.dart';
import 'package:intl/intl.dart';
import 'analyse_screen.dart';
import 'bewerk_screen.dart';
import 'profiel_screen.dart';

class DagboekScreen extends StatelessWidget {
  const DagboekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn Dagboek'),
        actions: [
          _SubscriptionToggle(),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.person_outline_rounded),
              tooltip: 'Mijn Profiel',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfielScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<DagboekProvider>(
        builder: (context, provider, child) {
          if (provider.dagboekEntries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services_outlined, size: 72, color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Geen medische logs gevonden',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.outline),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Begin met het toevoegen van je eerste entry',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline.withOpacity(0.7)),
                  ),
                ],
              ),
            );
          }

          // Grouping entries by day
          final Map<String, List<DagboekEntry>> groupedEntries = {};
          for (var entry in provider.dagboekEntries) {
            final dateKey = entry.geformateerdeDatum;
            if (!groupedEntries.containsKey(dateKey)) {
              groupedEntries[dateKey] = [];
            }
            groupedEntries[dateKey]!.add(entry);
          }

          final entryDatums = provider.dagboekEntries.map((e) => e.datum).toSet().toList();
          entryDatums.sort((a, b) => b.compareTo(a));

          // Filters for Basis sub: only last 7 days
          List<DateTime> gefilterdeDatums = entryDatums;
          bool heeftVerborgenEntries = false;
          
          if (provider.isBasis) {
            final nu = DateTime.now();
            final grens = DateTime(nu.year, nu.month, nu.day).subtract(const Duration(days: 7));
            gefilterdeDatums = entryDatums.where((d) => d.isAfter(grens) || d.isAtSameMomentAs(grens)).toList();
            heeftVerborgenEntries = entryDatums.length > gefilterdeDatums.length;
          }

          if (gefilterdeDatums.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_clock_rounded, size: 72, color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Geen recente logs gevonden',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.outline),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Met het Basis abonnement zie je de laatste 7 dagen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kies Premium voor onbeperkt inzicht.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline.withOpacity(0.7)),
                  ),
                ],
              ),
            );
          }

          final sortedDates = gefilterdeDatums.map((d) => DateFormat('d MMMM yyyy', 'nl_NL').format(d)).toList();

          return ListView.builder(
            itemCount: sortedDates.length + (heeftVerborgenEntries ? 1 : 0),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemBuilder: (context, index) {
              if (heeftVerborgenEntries && index == 0) {
                return _buildRestrictionCard(context);
              }

              final dayIndex = heeftVerborgenEntries ? index - 1 : index;
              final dateStr = sortedDates[dayIndex];
              final dayEntries = groupedEntries[dateStr]!;
              final firstEntry = dayEntries.first;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Separation Header
                  _buildDayHeader(context, firstEntry),
                  const SizedBox(height: 8),
                  ...dayEntries.asMap().entries.map((entryMap) {
                    final index = entryMap.key;
                    final entry = entryMap.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DagboekRijCard(
                        entry: entry,
                        provider: provider,
                        showDate: dayEntries.length > 1, // Only show time/sub-date if multiple entries
                        onDelete: () {
                          // Find original index in provider
                          final originalIndex = provider.dagboekEntries.indexOf(entry);
                          _confirmDelete(context, provider, originalIndex);
                        },
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDayHeader(BuildContext context, DagboekEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.15),
            Theme.of(context).colorScheme.primary.withOpacity(0.02),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            entry.geformateerdeDatum.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Text(
            entry.dagVanWeek,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictionCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      color: Colors.amber.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.lock_clock_rounded, color: Colors.amber.shade800),
            const SizedBox(height: 8),
            const Text(
              'Oudere resultaten zijn verborgen',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Met het Basis abonnement zie je de laatste 7 dagen. Kies Premium voor onbeperkt inzicht.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DagboekProvider provider, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verwijderen'),
        content: const Text('Weet je zeker dat je deze entry wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              provider.verwijderDagboekEntry(index);
              Navigator.pop(context);
            },
            child: const Text('Verwijderen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class DagboekRijCard extends StatefulWidget {
  final DagboekEntry entry;
  final DagboekProvider provider;
  final VoidCallback onDelete;
  final bool showDate;

  const DagboekRijCard({
    super.key,
    required this.entry,
    required this.provider,
    required this.onDelete,
    this.showDate = true,
  });

  @override
  State<DagboekRijCard> createState() => _DagboekRijCardState();
}

class _DagboekRijCardState extends State<DagboekRijCard> {
  // Get fresh metrics every time from the entry - don't cache!
  int get eczeemErnstig {
    if (widget.entry.gezondheidsMetrics.isNotEmpty) {
      return widget.entry.gezondheidsMetrics.first.eczeemErnstig;
    }
    return 0;
  }

  int get eczeemJeuken {
    if (widget.entry.gezondheidsMetrics.isNotEmpty) {
      return widget.entry.gezondheidsMetrics.first.eczeemJeuken;
    }
    return 0;
  }

  int get eczeemMild {
    if (widget.entry.gezondheidsMetrics.isNotEmpty) {
      return widget.entry.gezondheidsMetrics.first.eczeemMild;
    }
    return 5;
  }

  int get geenEczeem {
    if (widget.entry.gezondheidsMetrics.isNotEmpty) {
      return widget.entry.gezondheidsMetrics.first.geenEczeem;
    }
    return 5;
  }

  void _showEditDialog() {
    int tempEczeem = eczeemErnstig;
    int tempJeuken = eczeemJeuken;
    int tempEnergie = eczeemMild;
    int tempStress = geenEczeem;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Gezondheid bijwerken'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSliderRowDialog(
                  '🔴 Eczeem Ernstig',
                  tempEczeem,
                  (val) {
                    setDialogState(() => tempEczeem = val.toInt());
                  },
                ),
                const SizedBox(height: 12),
                _buildSliderRowDialog(
                  '🔴 Eczeem Jeuk',
                  tempJeuken,
                  (val) {
                    setDialogState(() => tempJeuken = val.toInt());
                  },
                ),
                const SizedBox(height: 12),
                _buildSliderRowDialog(
                  '🟡 Eczeem - Mild',
                  tempEnergie,
                  (val) {
                    setDialogState(() => tempEnergie = val.toInt());
                  },
                ),
                const SizedBox(height: 12),
                _buildSliderRowDialog(
                  'Geen eczeem',
                  tempStress,
                  (val) {
                    setDialogState(() => tempStress = val.toInt());
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update provider - no need to update state since we read fresh values
                widget.provider.voegGezondheidsMetricToe(
                  eczeemErnstig: tempEczeem,
                  eczeemJeuken: tempJeuken,
                  eczeemMild: tempEnergie,
                  slaapKwaliteit: 5,
                  geenEczeem: tempStress,
                  roodheid: 0,
                  droogheid: 0,
                  schilfering: 0,
                  medicatieGebruikt: false,
                  datum: widget.entry.datum,
                );
                Navigator.pop(context);
                // Widget will rebuild automatically and show fresh values
              },
              child: const Text('Opslaan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRowDialog(String label, int value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text('$value/10', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: '$value',
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = eczeemErnstig > 7 
        ? Colors.red 
        : (eczeemErnstig > 3 ? Colors.orange : Colors.teal);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Color Indicator Bar (Medical look)
              Container(
                width: 6,
                color: statusColor.withOpacity(0.8),
              ),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BewerkScreen(entry: widget.entry),
                      ),
                    );
                    
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (widget.showDate)
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 14, color: Colors.blueGrey[300]),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.entry.geformateerdeDatum,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey[400],
                                    ),
                                  ),
                                ],
                              )
                            else
                              const SizedBox.shrink(),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: Colors.blueGrey[200], size: 20),
                              onPressed: widget.onDelete,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        if (widget.showDate) const SizedBox(height: 8),
                        
                        // Main content - Food
                        if (widget.entry.voedselEntries.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.entry.voedselEntries
                                .map((e) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(e.categorie.icoon, size: 12, color: e.categorie.kleur),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              e.ingredienten.isNotEmpty ? e.ingredienten.join(", ") : e.beschrijving,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Health metrics
                        _buildModernMetrics(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernMetrics() {
    if (widget.entry.gezondheidsMetrics.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9), style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_chart_rounded, size: 16, color: Colors.blueGrey[200]),
            const SizedBox(width: 8),
            Text(
              'Gezondheidsgegevens toevoegen',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey[300],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final metric = widget.entry.gezondheidsMetrics.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'SYMPTOOM MONITOR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            if (!widget.showDate) // Show time only if grouped
              Text(
                widget.entry.datum.toString().substring(11, 16),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey[300]),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildMetricTile(
              Icons.warning_amber_rounded, 
              'Ernstig', 
              '${metric.eczeemErnstig}', 
              metric.eczeemErnstig > 7 ? Colors.red : (metric.eczeemErnstig > 3 ? Colors.orange : Colors.green),
            ),
            const SizedBox(width: 8),
            _buildMetricTile(
              Icons.info_outline_rounded, 
              'Jeuk', 
              '${metric.eczeemJeuken}', 
              Colors.orange,
            ),
            const SizedBox(width: 8),
            _buildMetricTile(
              Icons.circle_outlined, 
              'Mild', 
              '${metric.eczeemMild}', 
              Colors.blueGrey,
            ),
            const SizedBox(width: 8),
            _buildMetricTile(
              Icons.check_circle_outline_rounded, 
              'Rustig', 
              '${metric.geenEczeem}', 
              Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: color.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DagboekProvider>(
      builder: (context, provider, child) {
        String label = 'GRATIS';
        Color color = Colors.grey;
        if (provider.isBasis) {
          label = 'BASIS';
          color = Colors.blue;
        } else if (provider.isPremium) {
          label = 'PREMIUM';
          color = Colors.teal;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: InkWell(
            onTap: () => provider.rotateSubscriptionLevel(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
