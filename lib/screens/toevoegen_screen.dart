import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dagboek_provider.dart';
import '../models/voedsel_categorie.dart';
import '../widgets/home_button.dart';
import '../widgets/app_logo.dart';

class ToevoegenScreen extends StatefulWidget {
  const ToevoegenScreen({super.key});

  @override
  State<ToevoegenScreen> createState() => _ToevoegenScreenState();
}

class _ToevoegenScreenState extends State<ToevoegenScreen> {
  int _selectedIndex = 0;
  final _voedselFormKey = GlobalKey<_VoegVoedselToeFormState>();
  final _gezondheidsFormKey = GlobalKey<_VoegGezondheidsMetricToeFormState>();

  void _opslaanHandler() {
    if (_selectedIndex == 0) {
      _voedselFormKey.currentState?._voegToe();
    } else {
      _gezondheidsFormKey.currentState?._voegToe();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(subtitle: 'Toevoegen'),
        actions: [
          const HomeButton(),
          Consumer<DagboekProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  onPressed: _opslaanHandler,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 1,
                  ),
                  child: const Text('Opslaan'),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<DagboekProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: SegmentedButton<int>(
                      style: ButtonStyle(
                        side: WidgetStateProperty.all(BorderSide.none),
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
                            }
                            return const Color(0xFFF1F5F9);
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return Theme.of(context).colorScheme.primary;
                            }
                            return Colors.blueGrey;
                          },
                        ),
                      ),
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Voeding'), icon: Icon(Icons.restaurant_menu_rounded)),
                        ButtonSegment(value: 1, label: Text('Gezondheid'), icon: Icon(Icons.favorite_rounded)),
                      ],
                      selected: {_selectedIndex},
                      onSelectionChanged: (value) {
                        setState(() {
                          _selectedIndex = value.first;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        VoegVoedselToeForm(key: _voedselFormKey),
                        VoegGezondheidsMetricToeForm(key: _gezondheidsFormKey),
                      ],
                    ),
                  ),
                ],
              ),

            ],
          );
        },
      ),
    );
  }
}

class VoegVoedselToeForm extends StatefulWidget {
  const VoegVoedselToeForm({super.key});

  @override
  State<VoegVoedselToeForm> createState() => _VoegVoedselToeFormState();
  
  void voegToe() {
    _VoegVoedselToeFormState? state = key is GlobalKey
        ? (key as GlobalKey).currentState as _VoegVoedselToeFormState?
        : null;
    state?._voegToe();
  }
}

class _VoegVoedselToeFormState extends State<VoegVoedselToeForm> {
  final _formKey = GlobalKey<FormState>();
  VoedselCategorie _geselecteerdeCategorie = VoedselCategorie.ontbijt;
  final _beschrijvingController = TextEditingController();
  final _notitiesController = TextEditingController();
  List<String> _ingredienten = [];
  DateTime _gekozenDatum = DateTime.now();
  static const List<String> _snelleAllergenen = [
    'Melk',
    'Gluten',
    'Noten',
    'Ei',
    'Soja',
    'Vis',
    'Schaaldieren',
  ];

  final _ingredientFocusNode = FocusNode();
  final _ingredientTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ingredientTextController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _beschrijvingController.dispose();
    _notitiesController.dispose();
    _ingredientFocusNode.dispose();
    _ingredientTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingredientenSuggesties = context.watch<DagboekProvider>().getAllIngredients();
    final detectedAllergens = context.watch<DagboekProvider>().checkForAllergens(
      _ingredienten.join(' ')
    );

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (detectedAllergens.isNotEmpty) _buildAllergenWarning(detectedAllergens),
          const Text('Categorie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<VoedselCategorie>(
            initialValue: _geselecteerdeCategorie,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: VoedselCategorie.values.map((categorie) {
              return DropdownMenuItem(
                value: categorie,
                child: Row(
                  children: [
                    Icon(categorie.icoon, color: categorie.kleur, size: 20),
                    const SizedBox(width: 12),
                    Text(categorie.naam),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _geselecteerdeCategorie = value);
              }
            },
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          const SizedBox(height: 12),
          const Text('Snelle allergenen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _snelleAllergenen.map((allerg) {
              final isSelected = _ingredienten.contains(allerg);
              return FilterChip(
                label: Text(
                  allerg,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _addIngredient(allerg);
                  } else {
                    setState(() => _ingredienten.remove(allerg));
                  }
                },
                selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ingrediënten', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (_ingredienten.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _ingredienten.clear()),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Wis alles', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Added Ingredients List (MOVED UP)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: _ingredienten.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '🥗 Nog geen ingrediënten toegevoegd',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ingredienten.map((ingredient) {
                      return Chip(
                        label: Text(
                          ingredient,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimaryContainer
                          ),
                        ),
                        onDeleted: () {
                          setState(() => _ingredienten.remove(ingredient));
                        },
                        deleteIcon: const Icon(Icons.close, size: 16),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 12),

          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();
              if (query.isEmpty) {
                return const Iterable<String>.empty();
              }
              return ingredientenSuggesties.where((option) {
                return option.toLowerCase().contains(query) && !_ingredienten.contains(option);
              });
            },
            onSelected: (selection) {
              _addIngredient(selection);
              _ingredientFocusNode.requestFocus();
            },
            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
              // Sync textController with our state controller if needed, but safer to let Autocomplete manage its own
              return TextFormField(
                controller: textController,
                focusNode: _ingredientFocusNode,
                decoration: InputDecoration(
                  labelText: 'Voeg ingrediënt toe',
                  hintText: 'Typ bijv. Tomaat, Kaas...',
                  prefixIcon: const Icon(Icons.add_circle_outline, size: 20),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _addIngredient(textController.text);
                      textController.clear();
                      _ingredientFocusNode.requestFocus();
                    },
                  ),
                ),
                onFieldSubmitted: (val) {
                  _addIngredient(val);
                  textController.clear();
                  _ingredientFocusNode.requestFocus();
                },
              );
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tijdstip'),
            subtitle: Text('${_gekozenDatum.day}-${_gekozenDatum.month}-${_gekozenDatum.year} ${_gekozenDatum.hour}:${_gekozenDatum.minute.toString().padLeft(2, '0')}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _gekozenDatum,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (!mounted) return;
              if (date == null) return;
              final time = await showTimePicker(
                // ignore: use_build_context_synchronously
                context: context,
                initialTime: TimeOfDay.fromDateTime(_gekozenDatum),
              );
              if (!mounted) return;
              if (time != null) {
                setState(() {
                  _gekozenDatum = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                });
              }
            },
          ),
          const SizedBox(height: 16),
          const Text('Notities (optioneel)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
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
        ],
      ),
    );
  }

  Future<void> _voegToe() async {
    if (_ingredienten.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Voeg a.u.b. ten minste één ingrediënt toe'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Gebruik eerste ingrediënt als beschrijving
    final beschrijving = _ingredienten.first;

    await context.read<DagboekProvider>().voegVoedselToe(
          categorie: _geselecteerdeCategorie,
          beschrijving: beschrijving,
          ingredienten: _ingredienten,
          notities: _notitiesController.text.isEmpty ? null : _notitiesController.text,
          datum: _gekozenDatum,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Voedsel toegevoegd en opgeslagen!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );

    // Reset form
    _notitiesController.clear();
    setState(() {
      _ingredienten = [];
      _gekozenDatum = DateTime.now();
    });
  }

  void _addIngredient(String tekst) {
    final ingredient = tekst.trim();
    if (ingredient.isNotEmpty && !_ingredienten.contains(ingredient)) {
      setState(() {
        _ingredienten.add(ingredient);
      });
    }
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

class VoegGezondheidsMetricToeForm extends StatefulWidget {
  const VoegGezondheidsMetricToeForm({super.key});

  @override
  State<VoegGezondheidsMetricToeForm> createState() => _VoegGezondheidsMetricToeFormState();
  
  void voegToe() {
    _VoegGezondheidsMetricToeFormState? state = key is GlobalKey
        ? (key as GlobalKey).currentState as _VoegGezondheidsMetricToeFormState?
        : null;
    state?._voegToe();
  }
}

class _VoegGezondheidsMetricToeFormState extends State<VoegGezondheidsMetricToeForm> {
  // Focused eczema UI state
  double _eczeemSeverity = 0; // 0-10 (Ernstig)
  double _jeukSeverity = 0; // 0-10
  double _mildSeverity = 5; // 0-10
  double _rustigSeverity = 5; // 0-10 (Geen eczeem)
  double _roodheid = 0; // 0-10
  double _droogheid = 0; // 0-10
  double _schilfering = 0; // 0-10
  bool _medicatieGebruikt = false;

  Widget _buildMedicalSlider(String label, double waarde, ValueChanged<double> onChanged, Color kleur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(
              waarde.round().toString(),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kleur),
            ),
          ],
        ),
        Slider(
          value: waarde,
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: kleur,
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rustig', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            Text('Heftig', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  final _notitiesController = TextEditingController();
  DateTime _gekozenDatum = DateTime.now();

  @override
  void dispose() {
    _notitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Haal ingredienten van vandaag
    final ingredientenVandaag = context
        .watch<DagboekProvider>()
        .getIngredientsForDay(_gekozenDatum);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Datum
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Datum & tijd', style: TextStyle(fontSize: 13)),
          subtitle: Text('${_gekozenDatum.day}-${_gekozenDatum.month}-${_gekozenDatum.year} ${_gekozenDatum.hour}:${_gekozenDatum.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.calendar_today, size: 20),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _gekozenDatum,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (!mounted) return;
            if (date == null) return;
            final time = await showTimePicker(
              // ignore: use_build_context_synchronously
              context: context,
              initialTime: TimeOfDay.fromDateTime(_gekozenDatum),
            );
            if (!mounted) return;
            if (time != null) {
              setState(() {
                _gekozenDatum = DateTime(date.year, date.month, date.day, time.hour, time.minute);
              });
            }
          },
        ),
        const SizedBox(height: 8),

        // Toon ingredienten van vandaag als context
        if (ingredientenVandaag.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    const Text(
                      'GEGETEN VANDAAG',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.0),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: ingredientenVandaag.map((ingredient) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        ingredient,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Eczeem groep
        const Text('Eczeem', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red)),
        const SizedBox(height: 4),
        _buildMedicalSlider('Ernst (0-10)', _eczeemSeverity, (value) => setState(() => _eczeemSeverity = value), Colors.red),

        const SizedBox(height: 4),
        Text('Symptomen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 2),
        _buildMedicalSlider('Jeuk', _jeukSeverity, (value) => setState(() => _jeukSeverity = value), Colors.orange[400]!),
        _buildMedicalSlider('Roodheid', _roodheid, (s) => setState(() => _roodheid = s), Colors.red[400]!),
        _buildMedicalSlider('Droogheid', _droogheid, (s) => setState(() => _droogheid = s), Colors.lightBlue[400]!),
        _buildMedicalSlider('Schilfering', _schilfering, (s) => setState(() => _schilfering = s), Colors.brown[300]!),

        const SizedBox(height: 16),
        
        // Medicatie toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _medicatieGebruikt ? Colors.teal[50] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _medicatieGebruikt ? Colors.teal[200]! : Colors.grey[300]!),
          ),
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Medicinale zalf/medicatie gebruikt?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Vandaag hormonale of andere medicatie gebruikt?', style: TextStyle(fontSize: 11)),
            value: _medicatieGebruikt,
            activeColor: Colors.teal,
            onChanged: (v) => setState(() => _medicatieGebruikt = v ?? false),
          ),
        ),
        
        const SizedBox(height: 24),

        // Notities
        const Text('Notities', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
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
          style: const TextStyle(fontSize: 13),
          maxLines: 3,
          minLines: 2,
        ),
      ],
    );
  }

  Future<void> _voegToe() async {
    final notitiesToSave = _notitiesController.text.trim();

    await context.read<DagboekProvider>().voegGezondheidsMetricToe(
          eczeemErnstig: _eczeemSeverity.round().clamp(0, 10),
          eczeemJeuken: _jeukSeverity.round().clamp(0, 10),
          eczeemMild: _mildSeverity.round().clamp(0, 10),
          slaapKwaliteit: 5,
          geenEczeem: _rustigSeverity.round().clamp(0, 10),
          roodheid: _roodheid.round(),
          droogheid: _droogheid.round(),
          schilfering: _schilfering.round(),
          medicatieGebruikt: _medicatieGebruikt,
          notities: notitiesToSave.isEmpty ? null : notitiesToSave,
          datum: _gekozenDatum,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Gezondheidsdata toegevoegd en opgeslagen!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );

    // Reset form
    setState(() {
      _eczeemSeverity = 0;
      _jeukSeverity = 0;
      _mildSeverity = 5;
      _rustigSeverity = 5;
      _roodheid = 0;
      _droogheid = 0;
      _schilfering = 0;
      _medicatieGebruikt = false;
      _gekozenDatum = DateTime.now();
    });
    _notitiesController.clear();
  }

}
