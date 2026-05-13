import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dagboek_provider.dart';
import '../models/dagboek_entry.dart';
import 'package:intl/intl.dart';
import 'bewerk_screen.dart';
import 'profiel_screen.dart';
import '../widgets/app_logo.dart';

enum DatumFilter { alles, aangepast }

class DagboekScreen extends StatefulWidget {
  const DagboekScreen({super.key});

  @override
  State<DagboekScreen> createState() => _DagboekScreenState();
}

class _DagboekScreenState extends State<DagboekScreen> {
  DatumFilter _actieveFilter = DatumFilter.alles;
  DateTimeRange? _aangepastBereik;

  void _selecteerAangepastBereik() {
    final nu = DateTime.now();
    DateTime vanDatum = _aangepastBereik?.start ?? nu.subtract(const Duration(days: 30));
    DateTime totDatum = _aangepastBereik?.end ?? nu;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final df = DateFormat('d MMMM yyyy', 'nl_NL');
            final primary = Theme.of(context).colorScheme.primary;

            Future<void> kiesDatum({required bool isVan}) async {
              final gekozen = await showDatePicker(
                context: context,
                initialDate: isVan ? vanDatum : totDatum,
                firstDate: DateTime(2020, 1, 1),
                lastDate: nu,
                locale: const Locale('nl', 'NL'),
                helpText: isVan ? 'Kies startdatum' : 'Kies einddatum',
                cancelText: 'Annuleren',
                confirmText: 'OK',
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: primary,
                        onPrimary: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (gekozen != null) {
                setSheetState(() {
                  if (isVan) {
                    vanDatum = gekozen;
                    // Ensure totDatum is not before vanDatum
                    if (totDatum.isBefore(vanDatum)) totDatum = vanDatum;
                  } else {
                    totDatum = gekozen;
                    // Ensure vanDatum is not after totDatum
                    if (vanDatum.isAfter(totDatum)) vanDatum = totDatum;
                  }
                });
              }
            }

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Row(
                    children: [
                      Icon(Icons.date_range_rounded, color: primary, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Filter op periode',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Van datum
                  _buildDatumKiezer(
                    label: 'Van',
                    datum: df.format(vanDatum),
                    primary: primary,
                    onTap: () => kiesDatum(isVan: true),
                  ),
                  const SizedBox(height: 12),
                  // Tot datum
                  _buildDatumKiezer(
                    label: 'Tot',
                    datum: df.format(totDatum),
                    primary: primary,
                    onTap: () => kiesDatum(isVan: false),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() => _actieveFilter = DatumFilter.alles);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primary,
                            side: BorderSide(color: primary.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _aangepastBereik = DateTimeRange(start: vanDatum, end: totDatum);
                              _actieveFilter = DatumFilter.aangepast;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Toepassen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDatumKiezer({
    required String label,
    required String datum,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                datum,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),
            Icon(Icons.calendar_today_rounded, size: 18, color: primary),
          ],
        ),
      ),
    );
  }

  List<DateTime> _filterDatums(List<DateTime> datums) {
    switch (_actieveFilter) {
      case DatumFilter.alles:
        return datums;
      case DatumFilter.aangepast:
        if (_aangepastBereik == null) return datums;
        final start = DateTime(_aangepastBereik!.start.year, _aangepastBereik!.start.month, _aangepastBereik!.start.day);
        final eind = DateTime(_aangepastBereik!.end.year, _aangepastBereik!.end.month, _aangepastBereik!.end.day).add(const Duration(days: 1));
        return datums.where((d) {
          final dag = DateTime(d.year, d.month, d.day);
          return !dag.isBefore(start) && dag.isBefore(eind);
        }).toList();
    }
  }

  Widget _buildFilterBar() {
    final primary = Theme.of(context).colorScheme.primary;

    String aangepastLabel = 'Periode';
    if (_actieveFilter == DatumFilter.aangepast && _aangepastBereik != null) {
      final df = DateFormat('d MMM', 'nl_NL');
      aangepastLabel = '${df.format(_aangepastBereik!.start)} – ${df.format(_aangepastBereik!.end)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, size: 18, color: primary),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Alles', DatumFilter.alles, primary),
                  const SizedBox(width: 6),
                  _buildFilterChip(aangepastLabel, DatumFilter.aangepast, primary, icon: Icons.date_range_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, DatumFilter filter, Color primary, {IconData? icon}) {
    final isActief = _actieveFilter == filter;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (filter == DatumFilter.aangepast) {
            _selecteerAangepastBereik();
          } else {
            setState(() => _actieveFilter = filter);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: icon != null ? 10 : 14, vertical: 7),
          decoration: BoxDecoration(
            color: isActief ? primary : primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActief ? primary : primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: isActief ? Colors.white : primary),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActief ? Colors.white : primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppUitlegDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoe werkt de app?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TriggerTrace helpt je eczeem en voeding in beeld te brengen, zodat je beter ziet wat bij jouw klachten past.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _uitlegSectie(
                context,
                'Dagboek',
                'Hier zie je je dagen in het overzicht. Per dag noteer je wat je eet (inclusief ingrediënten), je huid en slaap. Zo bouw je een tijdlijn om patronen te herkennen.',
              ),
              _uitlegSectie(
                context,
                'Eliminatie',
                'Start een test om bepaalde ingrediënten een tijd te vermijden en ze daarna gecontroleerd weer toe te voegen (provocatie). Zo kun je nagaan of iets je eczeem beïnvloedt.',
              ),
              _uitlegSectie(
                context,
                'Analyse',
                'Op basis van je ingevoerde gegevens zoekt de app samenhang tussen voeding en je symptomen, zodat je sneller richting krijgt bij wat je probeert.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  Widget _uitlegSectie(BuildContext context, String titel, String tekst) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titel,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tekst,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(subtitle: 'Dagboek'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Uitleg over de app',
            onPressed: () => _showAppUitlegDialog(context),
          ),
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
                  Icon(Icons.medical_services_outlined, size: 72, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Geen medische logs gevonden',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.outline),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Begin met het toevoegen van je eerste entry',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7)),
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

          // Geen filters meer nodig voor abonnementen, gebruik direct de datums
          final List<DateTime> gefilterdeDatums = _filterDatums(entryDatums);
          if (gefilterdeDatums.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_clock_rounded, size: 72, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Geen recente logs gevonden',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.outline),
                  ),
                  const SizedBox(height: 8),

                ],
              ),
            );
          }

          final sortedDates = gefilterdeDatums.map((d) => DateFormat('d MMMM yyyy', 'nl_NL').format(d)).toList();

          return Column(
            children: [
              // Date filter bar
              _buildFilterBar(),
              // Entries list
              Expanded(
                child: gefilterdeDatums.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 56, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'Geen gegevens in deze periode',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.outline),
                          ),
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: () => setState(() => _actieveFilter = DatumFilter.alles),
                            icon: const Icon(Icons.restart_alt_rounded, size: 18),
                            label: const Text('Toon alles'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: sortedDates.length,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemBuilder: (context, index) {
                        final dateStr = sortedDates[index];
                        final dayEntries = groupedEntries[dateStr]!;
                        final firstEntry = dayEntries.first;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Separation Header
                            _buildDayHeader(context, firstEntry),
                            const SizedBox(height: 8),
                            ...dayEntries.asMap().entries.map((entryMap) {
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
                            }),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
              ),
            ],
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
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
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

  @override
  Widget build(BuildContext context) {
    Color statusColor = eczeemErnstig > 7 
        ? Colors.red 
        : (eczeemErnstig > 3 ? Colors.orange : Colors.teal);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
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
                color: statusColor.withValues(alpha: 0.8),
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
                            children: widget.entry.voedselEntries.map((e) {
                              final heeftNaam = e.beschrijving.isNotEmpty &&
                                  e.beschrijving != (e.ingredienten.isNotEmpty ? e.ingredienten.first : '');
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(e.categorie.icoon, size: 12, color: e.categorie.kleur),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            heeftNaam ? e.beschrijving : e.ingredienten.join(", "),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (heeftNaam && e.ingredienten.isNotEmpty)
                                            Text(
                                              e.ingredienten.join(", "),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
              'Eczeem', 
              '${metric.eczeemErnstig}', 
              metric.eczeemErnstig > 7 ? Colors.red : (metric.eczeemErnstig > 3 ? Colors.orange : Colors.green),
            ),
            const SizedBox(width: 8),
            _buildMetricTile(
              Icons.circle, 
              'Jeuk', 
              '${metric.eczeemJeuken}', 
              Colors.orange[400]!,
            ),
            const SizedBox(width: 8),
            _buildMetricTile(
              Icons.circle, 
              'Roodheid', 
              '${metric.roodheid}', 
              Colors.red[400]!,
            ),
            const SizedBox(width: 8),
            _buildMetricTile(
              Icons.circle, 
              'Droogheid', 
              '${metric.droogheid}', 
              Colors.lightBlue[400]!,
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
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
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
                color: color.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
