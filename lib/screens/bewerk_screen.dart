import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/dagboek_entry.dart';
import '../models/voedsel_entry.dart';
import '../models/voedsel_categorie.dart';
import '../providers/dagboek_provider.dart';
import '../widgets/home_button.dart';

class BewerkScreen extends StatefulWidget {
  final DagboekEntry entry;
  
  const BewerkScreen({super.key, required this.entry});

  @override
  State<BewerkScreen> createState() => _BewerkScreenState();
}

class _BewerkScreenState extends State<BewerkScreen> {
  late final String _dagboekEntryId;
  late DateTime _vasteKalenderdatum;

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
    _dagboekEntryId = widget.entry.id;
    final d = widget.entry.datum;
    _vasteKalenderdatum = DateTime(d.year, d.month, d.day);

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
      _parseNotities(metric.notities ?? '');
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

  void _parseNotities(String raw) {
    final freeText = raw
        .split('\n')
        .where((line) => !line.startsWith('Factoren: '))
        .join('\n')
        .trim();
    _notitiesController.text = freeText;
  }

  String _buildNotities() => _notitiesController.text.trim();

  /// Huidige kalenderdag + oorspronkelijke kloktijd (voor opslaan en voedsel).
  DateTime get _effectieveEntryDatum {
    final t = widget.entry.datum;
    return DateTime(
      _vasteKalenderdatum.year,
      _vasteKalenderdatum.month,
      _vasteKalenderdatum.day,
      t.hour,
      t.minute,
      t.second,
      t.millisecond,
    );
  }

  Future<void> _pickDatum() async {
    final nu = DateTime.now();
    final primary = Theme.of(context).colorScheme.primary;
    var initial = _vasteKalenderdatum;
    if (initial.isAfter(nu)) initial = DateTime(nu.year, nu.month, nu.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: nu,
      locale: const Locale('nl', 'NL'),
      helpText: 'Kies dagboekdag',
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
    if (picked == null || !mounted) return;
    final nieuw = DateTime(picked.year, picked.month, picked.day);
    if (nieuw.year == _vasteKalenderdatum.year &&
        nieuw.month == _vasteKalenderdatum.month &&
        nieuw.day == _vasteKalenderdatum.day) {
      return;
    }

    setState(() {
      _vasteKalenderdatum = nieuw;
    });

    await context.read<DagboekProvider>().wijzigDagboekEntryKalenderdatum(_dagboekEntryId, _vasteKalenderdatum);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dagboekdag aangepast'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF0D9488),
      ),
    );
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
      datum: _effectieveEntryDatum,
      dagboekEntryId: _dagboekEntryId,
      eczeemErnstig: _eczeemErnstig.round(),
      eczeemJeuken: _eczeemJeuk.round(),
      eczeemMild: _eczeemMild.round(),
      slaapKwaliteit: _slaapKwaliteit.round(),
      geenEczeem: _geenEczeem.round(),
      roodheid: _roodheid.round(),
      droogheid: _droogheid.round(),
      schilfering: _schilfering.round(),
      medicatieGebruikt: _medicatieGebruikt,
      notities: _buildNotities().isEmpty ? null : _buildNotities(),
    );

    final updatedEntry = provider.getDagboekEntryById(_dagboekEntryId);
    if (updatedEntry == null) {
      debugPrint('❌ ENTRY NIET GEVONDEN NA OPSLAAN');
    } else if (updatedEntry.gezondheidsMetrics.isEmpty) {
      debugPrint('❌ GEEN METRICS NA OPSLAAN - MOGELIJK PROBLEEM');
    } else {
      final m = updatedEntry.gezondheidsMetrics.first;
      debugPrint('✅ NA OPSLAAN: Ernstig=${m.eczeemErnstig}, Mild=${m.eczeemMild}, Geen=${m.geenEczeem}, Slaap=${m.slaapKwaliteit}');
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Wijzigingen opgeslagen!'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF0D9488),
      ),
    );

    Navigator.pop(context, true);
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

  void _showAddFoodDialog(BuildContext context) {
    final naamController = TextEditingController();
    final ingredientenController = TextEditingController();
    VoedselCategorie selectedCategorie = VoedselCategorie.snack;
    bool listenerAdded = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (!listenerAdded) {
            ingredientenController.addListener(() => setDialogState(() {}));
            listenerAdded = true;
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
                    initialValue: selectedCategorie,
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
                      if (value != null) setDialogState(() => selectedCategorie = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: naamController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Maaltijdnaam (optioneel)',
                      border: OutlineInputBorder(),
                      hintText: 'bijv. Tosti, Smoothie...',
                    ),
                  ),
                  const SizedBox(height: 12),
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
                    final naam = naamController.text.trim();
                    context.read<DagboekProvider>().voegVoedselToe(
                      datum: _effectieveEntryDatum,
                      dagboekEntryId: _dagboekEntryId,
                      categorie: selectedCategorie,
                      beschrijving: naam.isNotEmpty ? naam : ingredienten.first,
                      ingredienten: ingredienten,
                    );

                    Navigator.pop(context);
                    setState(() {});

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
    final heeftNaam = currentEntry.beschrijving.isNotEmpty &&
        currentEntry.beschrijving != (currentEntry.ingredienten.isNotEmpty ? currentEntry.ingredienten.first : '');
    final naamController = TextEditingController(text: heeftNaam ? currentEntry.beschrijving : '');
    final ingredientenController = TextEditingController(text: currentEntry.ingredienten.join(', '));
    VoedselCategorie selectedCategorie = currentEntry.categorie;
    bool listenerAdded = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (!listenerAdded) {
            ingredientenController.addListener(() => setDialogState(() {}));
            listenerAdded = true;
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
                    initialValue: selectedCategorie,
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
                      if (value != null) setDialogState(() => selectedCategorie = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: naamController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Maaltijdnaam (optioneel)',
                      border: OutlineInputBorder(),
                      hintText: 'bijv. Tosti, Smoothie...',
                    ),
                  ),
                  const SizedBox(height: 12),
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
                            datum: _effectieveEntryDatum,
                            dagboekEntryId: _dagboekEntryId,
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
                  final naam = naamController.text.trim();
                  context.read<DagboekProvider>().updateVoedselEntry(
                    datum: _effectieveEntryDatum,
                    dagboekEntryId: _dagboekEntryId,
                    voedselIndex: index,
                    categorie: selectedCategorie,
                    beschrijving: naam.isNotEmpty ? naam : ingredienten.first,
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
        title: const Text('Gegevens Bewerken'),
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
            // Date header (aanpasbaar)
            Material(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _pickDatum,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 20, color: Theme.of(context).colorScheme.onPrimary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('d MMMM yyyy', 'nl_NL').format(_vasteKalenderdatum),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE', 'nl_NL').format(_vasteKalenderdatum),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tik om datum te wijzigen',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_calendar_rounded, size: 18, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Info message
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                border: Border.all(color: const Color(0xFFCCFBF1)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded, 
                    color: Colors.teal.shade700
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Je kunt hier zowel gezondheidsdata als voedselitems aanpassen (Klik op een item).',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ),
                ],
              ),
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
                                const Spacer(),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showAddFoodDialog(context),
                                  icon: Icon(Icons.add_circle_outline_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                                ),
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
                              children: widget.entry.voedselEntries.expand((e) {
                                final index = widget.entry.voedselEntries.indexOf(e);
                                // Show each ingredient as a separate chip
                                if (e.ingredienten.isEmpty) {
                                  // Fallback: show beschrijving if no ingredients
                                  return [
                                    InkWell(
                                      onTap: () => _showEditSingleFoodDialog(context, index, e),
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
                                            const SizedBox(width: 6),
                                            Icon(Icons.edit_rounded, size: 12, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ];
                                }
                                return e.ingredienten.map((ing) {
                                  return InkWell(
                                    onTap: () => _showEditSingleFoodDialog(context, index, e),
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
                                            ing,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(Icons.edit_rounded, size: 12, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)),
                                        ],
                                      ),
                                    ),
                                  );
                                });
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
              'Eczeem',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red),
            ),
            const SizedBox(height: 2),
            _buildSlider(
              label: 'Ernst (0-10)',
              value: _eczeemErnstig,
              color: Colors.red,
              icon: Icons.warning_amber_rounded,
              onChanged: _setErnstig,
            ),

            const SizedBox(height: 4),
            Text('Symptomen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 2),
            _buildSlider(
              label: 'Jeuk',
              value: _eczeemJeuk,
              color: Colors.orange[400]!,
              icon: Icons.circle,
              onChanged: (v) => setState(() => _eczeemJeuk = v),
            ),
            _buildSlider(
              label: 'Roodheid',
              value: _roodheid,
              color: Colors.red[400]!,
              icon: Icons.circle,
              onChanged: (v) => setState(() => _roodheid = v),
            ),
            _buildSlider(
              label: 'Droogheid',
              value: _droogheid,
              color: Colors.lightBlue[400]!,
              icon: Icons.circle,
              onChanged: (v) => setState(() => _droogheid = v),
            ),
            _buildSlider(
              label: 'Schilfering',
              value: _schilfering,
              color: Colors.brown[300]!,
              icon: Icons.circle,
              onChanged: (v) => setState(() => _schilfering = v),
            ),

            const SizedBox(height: 10),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Medicatie gebruikt?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Zalf of medicijnen vandaag gebruikt', style: TextStyle(fontSize: 11)),
              value: _medicatieGebruikt,
              activeColor: Colors.teal,
              onChanged: (v) => setState(() => _medicatieGebruikt = v ?? false),
            ),
            
            const Divider(height: 20),

                  const Text('Notities', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notitiesController,
                    decoration: InputDecoration(
                      hintText: 'Schrijf hier je opmerkingen...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D2D2D) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      ),
                      prefixIcon: Icon(Icons.notes_rounded, color: Theme.of(context).colorScheme.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    maxLines: 3,
                    minLines: 2,
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
                Icon(icon, size: 10, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: color.withValues(alpha: 0.7),
            inactiveTrackColor: color.withValues(alpha: 0.08),
            thumbColor: Colors.white,
            overlayColor: color.withValues(alpha: 0.08),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
              elevation: 3,
              pressedElevation: 6,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
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
        const SizedBox(height: 2),
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
                  'Voeding gedetecteerd!',
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
