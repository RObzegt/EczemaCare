import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analyse_resultaat.dart';

class GrafiekenView extends StatelessWidget {
  final List<DagGrafiekData> dagData;
  final List<WeekGrafiekData> weekData;
  final List<MaandGrafiekData> maandData;
  final String topAllergen;

  const GrafiekenView({
    super.key,
    required this.dagData,
    required this.weekData,
    required this.maandData,
    this.topAllergen = 'Allergen',
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 $topAllergen vs Eczeem Correlatie',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Dagelijkse grafiek
          if (dagData.isNotEmpty) ...[
            const Text(
              'Dagelijks Overzicht',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDagGrafiek(),
            const SizedBox(height: 24),
          ],

          // Wekelijks grafiek
          if (weekData.isNotEmpty) ...[
            const Text(
              'Wekelijks Overzicht',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildWeekGrafiek(),
            const SizedBox(height: 24),
          ],

          // Maandelijks grafiek
          if (maandData.isNotEmpty) ...[
            const Text(
              'Maandelijks Overzicht',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildMaandGrafiek(),
            const SizedBox(height: 24),
          ],

          // Legenda
          _buildLegenda(),
        ],
      ),
    );
  }

  Widget _buildDagGrafiek() {
    if (dagData.isEmpty) return const SizedBox.shrink();

    final displayData = dagData.length > 14 ? dagData.sublist(dagData.length - 14) : dagData;
    
    final spots1 = <FlSpot>[];
    final spots2 = <FlSpot>[];

    for (int i = 0; i < displayData.length; i++) {
      spots1.add(FlSpot(i.toDouble(), displayData[i].allergenIntake));
      spots2.add(FlSpot(i.toDouble(), displayData[i].eczeemLevel.clamp(0, 10)));
    }

    // Dynamische maxY berekening (minimaal 10 voor de schaal 0-10)
    final maxValue = [
      ...spots1.map((s) => s.y),
      ...spots2.map((s) => s.y),
    ].reduce((a, b) => a > b ? a : b);
    final maxY = maxValue > 9 ? (maxValue + 1).ceilToDouble() : 10.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legenda
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('$topAllergen intake (# producten)', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Eczeem (0-10)', style: TextStyle(fontSize: 11, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: displayData.length > 7 ? 2 : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= displayData.length) return const SizedBox.shrink();
                          final date = displayData[index].datum;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots1,
                      isCurved: true,
                      color: Colors.blue,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: spots2,
                      isCurved: true,
                      color: Colors.red,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: 0,
                  maxY: maxY,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Laatste 14 dagen (${displayData.length} dagen)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📊 ${topAllergen}inname = aantal ${topAllergen.toLowerCase()}-gerelateerde ingrediënten per dag:\n'
                  '• Punten gebaseerd op aanwezigheid in maaltijden\n'
                  '• Schaal: 0-10\n'
                  '\n'
                  '💡 Correlatie: Hoge ${topAllergen.toLowerCase()}inname meestal samen met lager of hoger eczeem',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekGrafiek() {
    if (weekData.isEmpty) return const SizedBox.shrink();

    final weekLabels = <String>[];
    for (int i = 0; i < weekData.length; i++) {
      weekLabels.add('W${weekData[i].weekNum}');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legenda
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('Gem. $topAllergen', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Gem. eczeem', style: TextStyle(fontSize: 11, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= weekLabels.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              weekLabels[index],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: List.generate(
                    weekData.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: weekData[index].gemiddeldeAllergenIntake,
                          color: Colors.blue,
                          width: 8,
                        ),
                        BarChartRodData(
                          toY: weekData[index].gemiddeldeEczeem.clamp(0, 10),
                          color: Colors.red,
                          width: 8,
                        ),
                      ],
                    ),
                  ),
                  minY: 0,
                  maxY: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${weekData.length} weken data',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaandGrafiek() {
    if (maandData.isEmpty) return const SizedBox.shrink();

    final maandLabels = <String>[];
    for (int i = 0; i < maandData.length; i++) {
      maandLabels.add(maandData[i].maandNaam.substring(0, 3));
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legenda
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('Gem. $topAllergen', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Gem. eczeem', style: TextStyle(fontSize: 11, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= maandLabels.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              maandLabels[index],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: List.generate(
                    maandData.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: maandData[index].gemiddeldeAllergenIntake,
                          color: Colors.blue,
                          width: 8,
                        ),
                        BarChartRodData(
                          toY: maandData[index].gemiddeldeEczeem.clamp(0, 10),
                          color: Colors.red,
                          width: 8,
                        ),
                      ],
                    ),
                  ),
                  minY: 0,
                  maxY: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${maandData.length} maanden data',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegenda() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Legenda',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$topAllergen intake (0-10)', style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Eczeem niveau (0-10)', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '💡 Hoge correlatie: Als de $topAllergen-lijnen omhoog gaan en Eczeem-lijnen ook omhoog gaan, wijst dit op een mogelijke trigger.',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
