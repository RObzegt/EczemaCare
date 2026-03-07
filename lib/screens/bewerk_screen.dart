import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/dagboek_entry.dart';
import '../models/voedsel_entry.dart';
import '../models/voedsel_categorie.dart';
import '../providers/dagboek_provider.dart';
import '../debug_helper.dart';
import '../widgets/home_button.dart';

class BewerkScreen extends StatefulWidget {
  final DagboekEntry entry;
  
  const BewerkScreen({super.key, required this.entry});

  @override
  State<BewerkScreen> createState() => _BewerkScreenState();
}

class _BewerkScreenState extends State<BewerkScreen> {
  // Health metrics
  late double _eczeemErnstig;
  late double _eczeemJeuk;
  late double _eczeemMild;
  late double _geenEczeem;
  late double _slaapKwaliteit;
  late double _roodheid;
  late double _droogheid;
  late double _schilfering;
  late bool _medicatieGebruikt;
  
  final TextEditingController _notitiesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Load existing health data
    if (widget.entry.gezondheidsMetrics.isNotEmpty) {
      final metric = widget.entry.gezondheidsMetrics.first;
      _eczeemErnstig = metric.eczeemErnstig.toDouble();
      _eczeemJeuk = metric.eczeemJeuken.toDouble();
      _eczeemMild = metric.eczeemMild.toDouble();
      _geenEczeem = metric.geenEczeem.toDouble();
      _slaapKwaliteit = metric.slaapKwaliteit.toDouble();
      _roodheid = metric.roodheid.toDouble();
      _droogheid = metric.droogheid.toDouble();
      _schilfering = metric.schilfering.toDouble();
      _medicatieGebruikt = metric.medicatieGebruikt;
      _notitiesController.text = metric.notities ?? '';
    } else {
      _eczeemErnstig = 5.0;
      _eczeemJeuk = 0.0;
      _eczeemMild = 5.0;
      _geenEczeem = 5.0;
      _slaapKwaliteit = 5.0;
      _roodheid = 0.0;
      _droogheid = 0.0;
      _schilfering = 0.0;
      _medicatieGebruikt = false;
    }
  }

  @override
  void dispose() {
    _notitiesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final provider = context.read<DagboekProvider>();
    
    debugPrint('=== SAVING CHANGES FROM BEWERK SCREEN ===');
    
    await provider.updateGezondheidsMetric(
      datum: widget.entry.datum,
      eczeemErnstig: _eczeemErnstig.round(),
      eczeemJeuken: _eczeemJeuk.round(),
      eczeemMild: _eczeemMild.round(),
      slaapKwaliteit: _slaapKwaliteit.round(),
      geenEczeem: _geenEczeem.round(),
      roodheid: _roodheid.round(),
      droogheid: _droogheid.round(),
      schilfering: _schilfering.round(),
      medicatieGebruikt: _medicatieGebruikt,
      notities: _notitiesController.text.isEmpty ? null : _notitiesController.text,
    );

    final updatedEntry = provider.getEntryForDate(widget.entry.datum);
    if (updatedEntry == null) {
      debugPrint('❌ ENTRY NIET GEVONDEN NA OPSLAAN');
    } else if (updatedEntry.gezondheidsMetrics.isEmpty) {
      debugPrint('❌ GEEN METRICS NA OPSLAAN - MOGELIJK PROBLEEM');
    } else {
      final m = updatedEntry.gezondheidsMetrics.first;
      debugPrint('✅ NA OPSLAAN: Ernstig=${m.eczeemErnstig}, Mild=${m.eczeemMild}, Geen=${m.geenEczeem}, Slaap=${m.slaapKwaliteit}');
    }

    // Debug: Check what was actually saved
    Future.delayed(const Duration(milliseconds: 200), () {
      DebugHelper.printStorageData();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Wijzigingen opgeslagen!'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF0D9488),
      ),
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _setErnstig(double value) {
    setState(() {
      _eczeemErnstig = value;
      if (value >= 10) {
        _eczeemMild = 0;
        _geenEczeem = 0;
      }
    });
  }

  void _setMild(double value) {
    setState(() {
      _eczeemMild = value;
      if (value > 0 && _eczeemErnstig >= 10) {
        _eczeemErnstig = 9;
      }
      if (_eczeemMild > 0 && _geenEczeem >= 10) {
        _geenEczeem = 9;
      }
    });
  }

  void _setGeenEczeem(double value) {
    setState(() {
      _geenEczeem = value;
      if (value >= 10) {
        _eczeemErnstig = 0;
        _eczeemMild = 0;
      }
    });
  }

  void _deleteVoedselEntry(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verwijderen'),
        content: const Text('Weet je zeker dat je dit voedselitem wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.entry.voedselEntries.removeAt(index);
              });
              context.read<DagboekProvider>().forceSave();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Voedselitem verwijderd!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Verwijderen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  void _showEditFoodDialog(BuildContext context) {
    if (context.read<DagboekProvider>().subscriptionLevel == SubscriptionLevel.gratis) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upgrade naar Basis'),
          content: const Text('Met een Basis of Premium abonnement kun je geregistreerde voeding bewerken en verfijnen.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
            ElevatedButton(
              onPressed: () {
                context.read<DagboekProvider>().setSubscriptionLevel(SubscriptionLevel.basis);
                Navigator.pop(context);
              }, 
              child: const Text('Upgrade Nu')
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Klik op een specifiek item hieronder om het te bewerken'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddFoodDialog(BuildContext context) {
    if (context.read<DagboekProvider>().subscriptionLevel == SubscriptionLevel.gratis) {
      _showEditFoodDialog(context); // Shows upgrade dialog
      return;
    }

    final beschrijvingController = TextEditingController();
    final ingredientenController = TextEditingController();
    VoedselCategorie selectedCategorie = VoedselCategorie.snack;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Listen for changes to trigger allergen re-check
          if (!ingredientenController.hasListeners) {
            ingredientenController.addListener(() => setDialogState(() {}));
          }

          final detectedAllergens = context.read<DagboekProvider>().checkForAllergens(
            ingredientenController.text
          );

          return AlertDialog(
            title: const Text('Nieuw Voedsel Toevoegen'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (detectedAllergens.isNotEmpty) _buildAllergenWarning(detectedAllergens),
                  DropdownButtonFormField<VoedselCategorie>(
                  value: selectedCategorie,
                  decoration: const InputDecoration(
                    labelText: 'Categorie',
                    border: OutlineInputBorder(),
                  ),
                  items: VoedselCategorie.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(cat.icoon, color: cat.kleur, size: 20),
                          const SizedBox(width: 8),
                          Text(cat.naam),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedCategorie = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ingredientenController,
                  decoration: const InputDecoration(
                    labelText: 'Ingrediënten (komma gescheiden)',
                    border: OutlineInputBorder(),
                    hintText: 'bijv: Appel, Kaneel',
                  ),
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
                final ingredienten = ingredientenController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                if (ingredienten.isNotEmpty) {
                  context.read<DagboekProvider>().voegVoedselToe(
                    datum: widget.entry.datum,
                    categorie: selectedCategorie,
                    beschrijving: ingredienten.first,
                    ingredienten: ingredienten,
                  );

                  Navigator.pop(context);
                  setState(() {}); // Refresh UI
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Voedselitem toegevoegd!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Toevoegen'),
            ),
          ],
        );
      },
    ),
  );
}

  void _showEditSingleFoodDialog(BuildContext context, int index, VoedselEntry currentEntry) {
    final beschrijvingController = TextEditingController(text: currentEntry.beschrijving);
    final ingredientenController = TextEditingController(text: currentEntry.ingredienten.join(', '));
    VoedselCategorie selectedCategorie = currentEntry.categorie;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Listen for changes to trigger allergen re-check
          if (!ingredientenController.hasListeners) {
            ingredientenController.addListener(() => setDialogState(() {}));
          }

          final detectedAllergens = context.read<DagboekProvider>().checkForAllergens(
            ingredientenController.text
          );

          return AlertDialog(
            title: const Text('Voedsel bewerken'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (detectedAllergens.isNotEmpty) _buildAllergenWarning(detectedAllergens),
                  DropdownButtonFormField<VoedselCategorie>(
                    value: selectedCategorie,
                    decoration: const InputDecoration(
                      labelText: 'Categorie',
                      border: OutlineInputBorder(),
                    ),
                    items: VoedselCategorie.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(cat.icoon, color: cat.kleur, size: 20),
                            const SizedBox(width: 8),
                            Text(cat.naam),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedCategorie = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ingredientenController,
                    decoration: const InputDecoration(
                      labelText: 'Ingrediënten (komma gescheiden)',
                      border: OutlineInputBorder(),
                      hintText: 'bijv: Haver, Melk, Banaan',
                    ),
                  ),
                ],
              ),
            ),
          actions: [
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (confirmContext) => AlertDialog(
                    title: const Text('Verwijderen'),
                    content: const Text('Weet je zeker dat je dit item wilt verwijderen uit het dagboek?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(confirmContext), child: const Text('Nee')),
                      TextButton(
                        onPressed: () {
                          context.read<DagboekProvider>().verwijderVoedselItem(
                            datum: widget.entry.datum,
                            voedselIndex: index,
                          );
                          Navigator.pop(confirmContext); // Dialog 2
                          Navigator.pop(context); // Dialog 1
                          setState(() {});
                        }, 
                        child: const Text('Ja, Verwijderen', style: TextStyle(color: Colors.red))
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Verwijderen', style: TextStyle(color: Colors.red)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren'),
            ),
            ElevatedButton(
              onPressed: () {
                final ingredienten = ingredientenController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                if (ingredienten.isNotEmpty) {
                  context.read<DagboekProvider>().updateVoedselEntry(
                    datum: widget.entry.datum,
                    voedselIndex: index,
                    categorie: selectedCategorie,
                    beschrijving: ingredienten.first,
                    ingredienten: ingredienten,
                    notities: currentEntry.notities,
                  );

                  Navigator.pop(context);
                  setState(() {}); // Refresh the UI
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Voedselitem bijgewerkt!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Opslaan'),
            ),
          ],
        );
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Bewerken'),
        actions: [
          const HomeButton(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 1,
              ),
              child: const Text('Opslaan'),
            ),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600), // Makes it look "smaller" on web
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Date header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entry.geformateerdeDatum,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    widget.entry.dagVanWeek,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Info message
            Consumer<DagboekProvider>(
              builder: (context, provider, child) {
                final canEdit = provider.subscriptionLevel != SubscriptionLevel.gratis;
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: canEdit ? const Color(0xFFF0FDFA) : const Color(0xFFFFF7ED),
                    border: Border.all(color: canEdit ? const Color(0xFFCCFBF1) : const Color(0xFFFDE68A)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        canEdit ? Icons.edit_note_rounded : Icons.info_outline, 
                        color: canEdit ? Colors.teal.shade700 : Colors.amber.shade700
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          canEdit 
                              ? 'Je kunt hier zowel gezondheidsdata als voedselitems aanpassen (Klik op een item).' 
                              : 'Je kunt hier de gezondheidsdata aanpassen. Upgrade naar Basis voor volledige voedsel-bewerking.',
                          style: TextStyle(
                            fontSize: 11,
                            color: canEdit ? Colors.teal.shade900 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Health section card
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Compact food summary
                  // Brief food summary (Phase 3: Smaller & Detailed)
                  Consumer<DagboekProvider>(
                    builder: (context, provider, child) {
                      final isGratis = provider.subscriptionLevel == SubscriptionLevel.gratis;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.restaurant_menu_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'GEREGISTREERDE VOEDING',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context).colorScheme.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (isGratis) ...[
                                  const Spacer(),
                                  const Icon(Icons.lock_outline_rounded, size: 12, color: Colors.amber),
                                ] else ...[
                                  const Spacer(),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showAddFoodDialog(context),
                                    icon: Icon(Icons.add_circle_outline_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (widget.entry.voedselEntries.isEmpty)
                               Padding(
                                 padding: const EdgeInsets.symmetric(vertical: 8),
                                 child: Center(
                                   child: Text(
                                     'Geen voeding geregistreerd voor deze dag.',
                                     style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                                   ),
                                 ),
                               ),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: widget.entry.voedselEntries.asMap().entries.map((entry) {
                                final index = entry.key;
                                final e = entry.value;
                                return InkWell(
                                  onTap: isGratis 
                                      ? () => _showEditFoodDialog(context) // Shows the "click 3 dots" info or teaser
                                      : () => _showEditSingleFoodDialog(context, index, e),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          e.beschrijving,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                        ),
                                        if (!isGratis) ...[
                                          const SizedBox(width: 6),
                                          Icon(Icons.edit_rounded, size: 12, color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

            // Health metrics (editable)
            const Text(
              'Gezondheidsdata',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),

            // Ernstig
            _buildSlider(
              label: '🔴 Ernstig',
              value: _eczeemErnstig,
              color: Colors.red,
              icon: Icons.warning,
              onChanged: _setErnstig,
            ),
            const SizedBox(height: 6),

            // Jeuk
            _buildSlider(
              label: '🟠 Jeuk',
              value: _eczeemJeuk,
              color: Colors.orange,
              icon: Icons.info_outline,
              onChanged: (v) => setState(() => _eczeemJeuk = v),
            ),
            const SizedBox(height: 6),

            // Mild
            _buildSlider(
              label: '🟡 Mild',
              value: _eczeemMild,
              color: Colors.yellow.shade700,
              icon: Icons.circle,
              onChanged: _setMild,
            ),
            const SizedBox(height: 6),

            // Rustig
            _buildSlider(
              label: '🟢 Rustig',
              value: _geenEczeem,
              color: Colors.green,
              icon: Icons.check_circle,
              onChanged: _setGeenEczeem,
            ),
            
            const Divider(height: 32),
            const Text('Klinische Symptomen (Specialist)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            _buildSlider(
              label: '🔥 Roodheid',
              value: _roodheid,
              color: Colors.red[400]!,
              icon: Icons.local_fire_department,
              onChanged: (v) => setState(() => _roodheid = v),
            ),
            _buildSlider(
              label: '❄️ Droogheid',
              value: _droogheid,
              color: Colors.lightBlue[400]!,
              icon: Icons.water_drop,
              onChanged: (v) => setState(() => _droogheid = v),
            ),
            _buildSlider(
              label: '⚖️ Schilfering',
              value: _schilfering,
              color: Colors.brown[400]!,
              icon: Icons.layers,
              onChanged: (v) => setState(() => _schilfering = v),
            ),
            
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Medicatie gebruikt?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Zalf of medicijnen vandaag gebruikt', style: TextStyle(fontSize: 11)),
              value: _medicatieGebruikt,
              activeColor: Colors.teal,
              onChanged: (v) => setState(() => _medicatieGebruikt = v ?? false),
            ),
            
            const Divider(height: 32),
            const SizedBox(height: 6),

            // Slaap
            _buildSlider(
              label: 'Slaapkwaliteit',
              value: _slaapKwaliteit,
              color: Colors.blue,
              icon: Icons.bedtime,
              onChanged: (value) => setState(() => _slaapKwaliteit = value),
            ),
            const SizedBox(height: 8),

                  // Notes (compact)
                  TextField(
                    controller: _notitiesController,
                    decoration: const InputDecoration(
                      labelText: 'Notities',
                      hintText: 'Extra opmerkingen...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'Wijzigingen Opslaan',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildSlider({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value.round().toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12, // Thick modern track
            activeTrackColor: color.withOpacity(0.8),
            inactiveTrackColor: color.withOpacity(0.1),
            thumbColor: Colors.white,
            overlayColor: color.withOpacity(0.1),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 4,
              pressedElevation: 8,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAllergenWarning(List<String> allergens) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Allergenen gedetecteerd!',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Text(
                  'Let op: Dit bevat mogelijk ${allergens.join(", ")}.',
                  style: TextStyle(color: Colors.red[900], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
