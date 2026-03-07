import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dagboek_provider.dart';
import '../models/eliminatie_test.dart';
import '../widgets/home_button.dart';

class EliminatieScreen extends StatelessWidget {
  const EliminatieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eliminatie & Provocatie'),
        actions: [
          const HomeButton(),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Consumer<DagboekProvider>(
        builder: (context, provider, child) {
          if (!provider.isPremium) {
            return _buildPremiumTeaser(context);
          }

          final tests = provider.eliminatieTests;
          final actieveTest = provider.actieveTest;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              if (actieveTest != null) ...[
                _buildSectionTitle('Actieve Test'),
                const SizedBox(height: 12),
                _buildTestCard(context, actieveTest, isActief: true),
              ] else ...[
                _buildEmptyActieveTest(context),
              ],
              const SizedBox(height: 32),
              if (tests.where((t) => !t.isActief).isNotEmpty) ...[
                _buildSectionTitle('Geschiedenis'),
                const SizedBox(height: 12),
                ...tests
                    .where((t) => !t.isActief)
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildTestCard(context, t, isActief: false),
                        )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStartTestDialog(context),
        label: const Text('Nieuwe Test'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Eliminatie Dieet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Spoor triggers op door specifieke allergenen tijdelijk te vermijden.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildEmptyActieveTest(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.science_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Geen actieve eliminatie test',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start een nieuwe test om te ontdekken welke voedingsmiddelen invloed hebben op je eczeem.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, EliminatieTest test, {required bool isActief}) {
    final durationInDays = DateTime.now().difference(test.startDatum).inDays;
    final elimProgress = (durationInDays / test.doelDagen).clamp(0.0, 1.0);
    
    // Allergenen die nog niet geprovokeerd zijn (of worden)
    final geprovokeerdeNamen = test.provocaties.map((p) => p.allergen).toSet();
    final beschikbareAllergenen = test.allergenen.where((a) => !geprovokeerdeNamen.contains(a)).toList();
    
    return Card(
      elevation: isActief ? 6 : 1,
      shadowColor: isActief ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isActief 
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActief ? Icons.biotech_rounded : Icons.history_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActief ? 'ACTIEVE TEST' : 'AFGERONDE TEST',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '${test.startDatum.day}-${test.startDatum.month}-${test.startDatum.year}',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey[400], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (isActief)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                    onPressed: () => _confirmStopTest(context, test.id),
                    tooltip: 'Stop test',
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                    onPressed: () => context.read<DagboekProvider>().verwijderEliminatieTest(test.id),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            const Text(
              'ELIMINATIE TARGETS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...test.allergenen.map((a) {
                  final wordtGeprovokeerd = test.provocaties.any((p) => p.allergen == a);
                  
                  return Container(
                    padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          a,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (isActief && !wordtGeprovokeerd)
                          IconButton(
                            icon: const Icon(Icons.science_outlined, size: 16),
                            color: Colors.indigo,
                            onPressed: () => _showStartProvocatieDialog(context, test.id, test.allergenen, initialAllergen: a),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            tooltip: 'Start provocatie voor $a',
                          ),
                        if (wordtGeprovokeerd)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                          ),
                      ],
                    ),
                  );
                }),
                if (isActief)
                  InkWell(
                    onTap: () => _showAddAllergenDialog(context, test.id, test.allergenen),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal[200]!, style: BorderStyle.solid),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 14, color: Colors.teal),
                          SizedBox(width: 4),
                          Text('Voeg toe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            if (isActief) ...[
              const SizedBox(height: 24),
              _buildPhaseIndicator(context, test),
              const SizedBox(height: 24),
              
              _buildEliminatieProgress(context, test, durationInDays, elimProgress),
              
              if (test.provocaties.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.play_circle_outline, size: 16, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      'PROVOCATIE LOG',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.indigo, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...test.provocaties.map((p) {
                  final pDays = DateTime.now().difference(p.startDatum).inDays;
                  final pProgress = (pDays / p.duurDagen).clamp(0.0, 1.0);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.withOpacity(0.1)),
                    ),
                    child: _buildProvocatieProgress(
                      context, 
                      p.allergen, 
                      pDays, 
                      p.duurDagen, 
                      pProgress,
                      Colors.indigo,
                      onStop: p.isAfgerond ? null : () => context.read<DagboekProvider>().stopProvocatie(test.id, p.allergen)
                    ),
                  );
                }),
              ],

              if (beschikbareAllergenen.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showStartProvocatieDialog(context, test.id, beschikbareAllergenen),
                    icon: const Icon(Icons.science_rounded, size: 18),
                    label: const Text('PROVOCATIE STARTEN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],

            if (test.notities != null && test.notities!.isNotEmpty) ...[
              const Divider(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      test.notities!,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
            
            if (!isActief) ...[
               const SizedBox(height: 16),
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.grey[100],
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.done_all_rounded, size: 16, color: Colors.green),
                     const SizedBox(width: 8),
                     Text(
                       'Test voltooid na ${test.eindDatum?.difference(test.startDatum).inDays} dagen',
                       style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                     ),
                   ],
                 ),
               ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseIndicator(BuildContext context, EliminatieTest test) {
    bool inProvocatie = test.provocaties.any((p) => !p.isAfgerond);
    
    return Row(
      children: [
        _buildPhaseStep(context, 'ELIMINATIE', !inProvocatie, true),
        Expanded(child: Container(height: 2, color: inProvocatie ? Colors.indigo.withOpacity(0.3) : Colors.teal.withOpacity(0.3))),
        _buildPhaseStep(context, 'PROVOCATIE', inProvocatie, false),
      ],
    );
  }

  Widget _buildPhaseStep(BuildContext context, String label, bool isCurrent, bool isFirst) {
    Color color = isFirst ? Colors.teal : Colors.indigo;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isCurrent ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
            boxShadow: isCurrent ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)] : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isCurrent ? Colors.white : color,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEliminatieProgress(BuildContext context, EliminatieTest test, int current, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ELIMINATIE FASE VOORTGANG',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 0.5),
            ),
            Text(
              '$current / ${test.doelDagen} DAGEN',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[700]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.teal[400]!, Colors.teal[600]!]),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProvocatieProgress(
    BuildContext context, 
    String allergen, 
    int current, 
    int total, 
    double progress, 
    Color color,
    {VoidCallback? onStop}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Provocatie: $allergen',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            if (onStop != null)
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                onPressed: onStop,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Afronden',
              )
            else
              const Icon(Icons.verified_rounded, color: Colors.green, size: 20),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$current / $total d',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmStopTest(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Stoppen?'),
        content: const Text('Weet je zeker dat je deze eliminatie test wilt beëindigen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuleren')),
          TextButton(
            onPressed: () {
              context.read<DagboekProvider>().stopEliminatieTest(id);
              Navigator.pop(context);
            },
            child: const Text('Stop Test', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showStartProvocatieDialog(BuildContext context, String testId, List<String> allergenen, {String? initialAllergen}) {
    final durationController = TextEditingController(text: '5');
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(initialAllergen != null ? 'Provocatie: $initialAllergen' : 'Provocatie Starten'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (initialAllergen == null) ...[
                  const Text(
                    'Kies een ingrediënt om weer te introduceren.',
                    style: TextStyle(fontSize: 13),
                  ),
                ] else ...[
                  const Text(
                    'Stel de duur in voor deze provocatie.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duur in dagen',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (initialAllergen == null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'SELECTEER ALLERGEEN:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allergenen.map((a) => ActionChip(
                      label: Text(a),
                      backgroundColor: Colors.indigo.withOpacity(0.05),
                      onPressed: () {
                        final dagen = int.tryParse(durationController.text) ?? 5;
                        context.read<DagboekProvider>().startProvocatie(testId, a, duurDagen: dagen);
                        Navigator.pop(context);
                      },
                    )).toList(),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuleren'),
              ),
              if (initialAllergen != null)
                ElevatedButton(
                  onPressed: () {
                    final dagen = int.tryParse(durationController.text) ?? 5;
                    context.read<DagboekProvider>().startProvocatie(testId, initialAllergen, duurDagen: dagen);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  child: const Text('Starten'),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showAddAllergenDialog(BuildContext context, String testId, List<String> huidigeAllergenen) {
    final suggesties = ['Melk', 'Ei', 'Gluten', 'Noten', 'Pinda', 'Soja', 'Vis', 'Schaaldieren', 'Suiker', 'Lactose']
        .where((s) => !huidigeAllergenen.contains(s))
        .toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingrediënt Toevoegen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (suggesties.isEmpty)
              const Text('Alle standaard ingrediënten zijn al toegevoegd.')
            else ...[
              const Text(
                'Kies een ingrediënt om toe te voegen aan de eliminatie:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggesties.map((s) => ActionChip(
                  label: Text(s),
                  onPressed: () {
                    context.read<DagboekProvider>().voegAllergeenToeAanTest(testId, s);
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
            ],
          ],
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

  void _showStartTestDialog(BuildContext context) {
    final notesController = TextEditingController();
    final durationController = TextEditingController(text: '21');
    final commonAllergens = ['Melk', 'Ei', 'Gluten', 'Noten', 'Pinda', 'Soja', 'Vis', 'Schaaldieren', 'Suiker', 'Lactose'];
    final selectedAllergens = <String>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Nieuwe Eliminatie Test'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecteer de ingrediënten die je wilt elimineren:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: commonAllergens.map((a) {
                      final isSelected = selectedAllergens.contains(a);
                      return FilterChip(
                        label: Text(a),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedAllergens.add(a);
                            } else {
                              selectedAllergens.remove(a);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Doel (aantal dagen)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notities (optioneel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
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
                onPressed: selectedAllergens.isEmpty 
                  ? null 
                  : () {
                    final dagen = int.tryParse(durationController.text) ?? 21;
                    context.read<DagboekProvider>().startEliminatieTest(
                      selectedAllergens.toList(),
                      doelDagen: dagen,
                      notities: notesController.text,
                    );
                    Navigator.pop(context);
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Starten'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumTeaser(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eliminatie & Provocatie'),
        actions: const [HomeButton()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.science_rounded, size: 80, color: Colors.indigo),
              ),
              const SizedBox(height: 32),
              const Text(
                'Premium Functie',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Neem Premium voor volledige eliminatie en provocatie test mogelijkheden.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.blueGrey, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<DagboekProvider>().setSubscriptionLevel(SubscriptionLevel.premium);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Upgrade naar Premium', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Of kies voor Basis voor 7 dagen dagboek historie.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wat is een Eliminatie Dieet?'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Een eliminatiedieet is een methode om voedselovergevoeligheden te identificeren.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. **Fase 1: Eliminatie**: Vermijd het verdachte voedingsmiddel volledig (standaard 21 dagen, aanpasbaar).'),
              const SizedBox(height: 8),
              Text('2. **Fase 2: Provocatie**: Introduceer elk ingrediënt één voor één weer (standaard 5 dagen, aanpasbaar).'),
              const SizedBox(height: 8),
              Text('3. **Fase 3: Analyse**: Kijk of de symptomen terugkeren bij een specifieke provocatie.'),
              SizedBox(height: 12),
              Text(
                'Tijdens het schema kun je extra ingrediënten toevoegen aan de actieve test.',
                style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              SizedBox(height: 8),
              Text(
                'Let op: Raadpleeg bij ernstige allergieën altijd een arts of diëtist.',
                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Duidelijk'),
          ),
        ],
      ),
    );
  }
}
