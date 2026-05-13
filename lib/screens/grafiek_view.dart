import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analyse_resultaat.dart';

class GrafiekenView extends StatelessWidget {
  final List<DagGrafiekData> dagData;
  final List<WeekGrafiekData> weekData;
  final List<MaandGrafiekData> maandData;
  final String topAllergen;
  final String selectedPeriod; // 'all' | 'week' | 'month'

  const GrafiekenView({
    super.key,
    required this.dagData,
    required this.weekData,
    required this.maandData,
    this.topAllergen = 'Allergen',
    this.selectedPeriod = 'all',
  });

  // Dag-data gefilterd op geselecteerde periode
  List<DagGrafiekData> get _gefilterdeDagData {
    final maxDagen = selectedPeriod == 'week' ? 7 : (selectedPeriod == 'month' ? 30 : 14);
    return dagData.length > maxDagen ? dagData.sublist(dagData.length - maxDagen) : dagData;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final allergenKleur = primary;
    const eczeemKleur = Color(0xFFEF4444);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.show_chart_rounded, size: 18, color: primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$topAllergen vs Eczeem',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    Text(
                      _periodeLabel,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Legenda — één keer bovenaan, gedeeld door alle grafieken
        _buildLegenda(context, allergenKleur, eczeemKleur),
        const SizedBox(height: 16),

        // Daggrafiek — altijd tonen (week/month/all)
        if (_gefilterdeDagData.isNotEmpty) ...[
          _buildSectieLabel(context, _dagGrafiekTitel),
          const SizedBox(height: 8),
          _buildDagGrafiek(context, allergenKleur, eczeemKleur),
          const SizedBox(height: 24),
        ],

        // Weekgrafiek — tonen bij 'month' en 'all'
        if ((selectedPeriod == 'month' || selectedPeriod == 'all') && weekData.isNotEmpty) ...[
          _buildSectieLabel(context, 'Wekelijks gemiddelde'),
          const SizedBox(height: 8),
          _buildWeekGrafiek(context, allergenKleur, eczeemKleur),
          const SizedBox(height: 24),
        ],

        // Maandgrafiek — alleen bij 'all'
        if (selectedPeriod == 'all' && maandData.isNotEmpty) ...[
          _buildSectieLabel(context, 'Maandelijks gemiddelde'),
          const SizedBox(height: 8),
          _buildMaandGrafiek(context, allergenKleur, eczeemKleur),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  String get _periodeLabel {
    switch (selectedPeriod) {
      case 'week':  return 'Afgelopen 7 dagen';
      case 'month': return 'Afgelopen 30 dagen';
      default:      return 'Alle beschikbare data';
    }
  }

  String get _dagGrafiekTitel {
    switch (selectedPeriod) {
      case 'week':  return 'Dagelijks — deze week';
      case 'month': return 'Dagelijks — deze maand';
      default:      return 'Dagelijks — laatste 14 dagen';
    }
  }

  Widget _buildSectieLabel(BuildContext context, String tekst) {
    return Text(
      tekst.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildLegenda(BuildContext context, Color allergenKleur, Color eczeemKleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendaItem(allergenKleur, topAllergen, rondGestippeld: false),
          const SizedBox(width: 20),
          _legendaItem(eczeemKleur, 'Eczeem (0–10)', rondGestippeld: false),
        ],
      ),
    );
  }

  Widget _legendaItem(Color kleur, String label, {required bool rondGestippeld}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 4,
          decoration: BoxDecoration(
            color: kleur,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kleur)),
      ],
    );
  }

  Widget _buildDagGrafiek(BuildContext context, Color allergenKleur, Color eczeemKleur) {
    final data = _gefilterdeDagData;
    final spots1 = <FlSpot>[];
    final spots2 = <FlSpot>[];

    for (int i = 0; i < data.length; i++) {
      spots1.add(FlSpot(i.toDouble(), data[i].allergenIntake));
      spots2.add(FlSpot(i.toDouble(), data[i].eczeemLevel.clamp(0, 10).toDouble()));
    }

    final maxVal = [...spots1.map((s) => s.y), ...spots2.map((s) => s.y)]
        .fold(0.0, (a, b) => a > b ? a : b);
    final maxY = (maxVal > 9 ? maxVal + 1 : 10.0).ceilToDouble();

    // Interval voor as-labels: laat niet meer dan 7 labels toe
    final labelInterval = (data.length / 6).ceil().toDouble().clamp(1.0, 999.0);
    final toonDots = data.length <= 10;

    return _grafiekKaart(
      context: context,
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 5,
              getDrawingHorizontalLine: (v) => FlLine(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: labelInterval,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= data.length) return const SizedBox.shrink();
                    final d = data[idx].datum;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${d.day}/${d.month}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: maxY / 5,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
                left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots1,
                isCurved: true,
                color: allergenKleur,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: toonDots,
                  getDotPainter: (s, p, bar, i) => FlDotCirclePainter(radius: 4, color: allergenKleur, strokeWidth: 2, strokeColor: Colors.white),
                ),
                belowBarData: BarAreaData(show: true, color: allergenKleur.withValues(alpha: 0.06)),
              ),
              LineChartBarData(
                spots: spots2,
                isCurved: true,
                color: eczeemKleur,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: toonDots,
                  getDotPainter: (s, p, bar, i) => FlDotCirclePainter(radius: 4, color: eczeemKleur, strokeWidth: 2, strokeColor: Colors.white),
                ),
                belowBarData: BarAreaData(show: true, color: eczeemKleur.withValues(alpha: 0.04)),
              ),
            ],
            minY: 0,
            maxY: maxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Theme.of(context).colorScheme.inverseSurface,
                getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                  final label = spot.barIndex == 0 ? topAllergen : 'Eczeem';
                  return LineTooltipItem(
                    '$label: ${spot.y.toStringAsFixed(1)}',
                    TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontSize: 12, fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      voetnoot: '${data.length} ${data.length == 1 ? 'dag' : 'dagen'}',
    );
  }

  Widget _buildWeekGrafiek(BuildContext context, Color allergenKleur, Color eczeemKleur) {
    final barBreedte = weekData.length > 8 ? 6.0 : (weekData.length > 4 ? 10.0 : 14.0);

    return _grafiekKaart(
      context: context,
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 2,
              getDrawingHorizontalLine: (v) => FlLine(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= weekData.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'W${weekData[idx].weekNum}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 2,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
                left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
              ),
            ),
            barGroups: List.generate(weekData.length, (i) => BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(toY: weekData[i].gemiddeldeAllergenIntake, color: allergenKleur, width: barBreedte, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                BarChartRodData(toY: weekData[i].gemiddeldeEczeem.clamp(0, 10).toDouble(), color: eczeemKleur, width: barBreedte, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
              ],
            )),
            minY: 0,
            maxY: 10,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Theme.of(context).colorScheme.inverseSurface,
                getTooltipItem: (group, groupIdx, rod, rodIdx) {
                  final label = rodIdx == 0 ? topAllergen : 'Eczeem';
                  return BarTooltipItem(
                    '$label: ${rod.toY.toStringAsFixed(1)}',
                    TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontSize: 12, fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      voetnoot: '${weekData.length} ${weekData.length == 1 ? 'week' : 'weken'}',
    );
  }

  Widget _buildMaandGrafiek(BuildContext context, Color allergenKleur, Color eczeemKleur) {
    final barBreedte = maandData.length > 8 ? 6.0 : (maandData.length > 4 ? 10.0 : 14.0);

    return _grafiekKaart(
      context: context,
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 2,
              getDrawingHorizontalLine: (v) => FlLine(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= maandData.length) return const SizedBox.shrink();
                    final naam = maandData[idx].maandNaam;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        naam.length > 3 ? naam.substring(0, 3) : naam,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 2,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
                left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
              ),
            ),
            barGroups: List.generate(maandData.length, (i) => BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(toY: maandData[i].gemiddeldeAllergenIntake, color: allergenKleur, width: barBreedte, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                BarChartRodData(toY: maandData[i].gemiddeldeEczeem.clamp(0, 10).toDouble(), color: eczeemKleur, width: barBreedte, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
              ],
            )),
            minY: 0,
            maxY: 10,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Theme.of(context).colorScheme.inverseSurface,
                getTooltipItem: (group, groupIdx, rod, rodIdx) {
                  final label = rodIdx == 0 ? topAllergen : 'Eczeem';
                  return BarTooltipItem(
                    '$label: ${rod.toY.toStringAsFixed(1)}',
                    TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontSize: 12, fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      voetnoot: '${maandData.length} ${maandData.length == 1 ? 'maand' : 'maanden'}',
    );
  }

  Widget _grafiekKaart({required BuildContext context, required Widget child, required String voetnoot}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          const SizedBox(height: 8),
          Text(voetnoot, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
