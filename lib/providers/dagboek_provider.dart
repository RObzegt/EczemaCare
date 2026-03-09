import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/dagboek_entry.dart';
import '../models/voedsel_entry.dart';
import '../models/voedsel_categorie.dart';
import '../models/gezondheids_metric.dart';
import '../models/analyse_resultaat.dart';
import '../models/eliminatie_test.dart';
import '../services/ai_analyse_service.dart';

import 'package:uuid/uuid.dart';

enum SubscriptionLevel { gratis, basis, premium }

class DagboekProvider extends ChangeNotifier {
  List<DagboekEntry> _dagboekEntries = [];
  List<EliminatieTest> _eliminatieTests = [];
  AnalyseResultaat? _huidigAnalyseResultaat;
  bool _isAnalyseBezig = false;
  SubscriptionLevel _subscriptionLevel = SubscriptionLevel.gratis;
  bool _isGeinitialiseerd = false;

  final AIAnalyseService _analyseService = AIAnalyseService();
  static const String _storageKey = 'dagboek_entries';
  static const String _testStorageKey = 'eliminatie_tests';
  static const String _initKey = 'dagboek_initialized';
  static const String _subscriptionKey = 'subscription_level';
  static const String _allergenKey = 'user_allergens';

  List<String> _userAllergens = [];
  
  // Mapping van veelvoorkomende voedingsmiddelen naar hun allergenen
  final Map<String, List<String>> _allergenMapping = {
    // Zuivel / Melk
    'yoghurt': ['Melk'],
    'kwark': ['Melk'],
    'kaas': ['Melk'],
    'melk': ['Melk'],
    'boter': ['Melk'],
    'slagroom': ['Melk'],
    'room': ['Melk'],
    'vla': ['Melk'],
    'wei': ['Melk'],
    'caseïne': ['Melk'],
    
    // Ei
    'ei': ['Ei'],
    'eiwitten': ['Ei'],
    'omelet': ['Ei'],
    'mayonaise': ['Ei'],
    'meringue': ['Ei'],
    
    // Gluten / Tarwe
    'brood': ['Gluten'],
    'pasta': ['Gluten'],
    'tarwe': ['Gluten'],
    'spelt': ['Gluten'],
    'rogge': ['Gluten'],
    'gerst': ['Gluten'],
    'couscous': ['Gluten'],
    'bloem': ['Gluten'],
    
    // Noten
    'noten': ['Noten'],
    'amandel': ['Noten'],
    'cashew': ['Noten'],
    'hazelnoot': ['Noten'],
    'walnoot': ['Noten'],
    'pistache': ['Noten'],
    
    // Pinda
    'pinda': ['Pinda'],
    'pindakaas': ['Pinda'],
    
    // Soja
    'soja': ['Soja'],
    'soya': ['Soja'],
    'tofu': ['Soja'],
    'tempeh': ['Soja'],
    'edamame': ['Soja'],
    
    // Vis & Schaal/Weekdieren
    'vis': ['Vis'],
    'zalm': ['Vis'],
    'tonijn': ['Vis'],
    'kabeljauw': ['Vis'],
    'garnalen': ['Schaaldieren'],
    'shrimp': ['Schaaldieren'],
    'mosselen': ['Schaaldieren'],
    
    // Samengestelde producten (voorbeelden)
    'pannenkoek': ['Melk', 'Ei', 'Gluten'],
    'pizza': ['Gluten', 'Melk'],
  };

  List<DagboekEntry> get dagboekEntries => _dagboekEntries;
  List<EliminatieTest> get eliminatieTests => _eliminatieTests;
  AnalyseResultaat? get huidigAnalyseResultaat => _huidigAnalyseResultaat;
  bool get isAnalyseBezig => _isAnalyseBezig;
  SubscriptionLevel get subscriptionLevel => _subscriptionLevel;
  List<String> get userAllergens => _userAllergens;
  
  bool get isGratis => _subscriptionLevel == SubscriptionLevel.gratis;
  bool get isBasis => _subscriptionLevel == SubscriptionLevel.basis;
  bool get isPremium => _subscriptionLevel == SubscriptionLevel.premium;
  
  // Actieve test helper
  EliminatieTest? get actieveTest => _eliminatieTests.isNotEmpty && _eliminatieTests.any((t) => t.isActief) 
      ? _eliminatieTests.firstWhere((t) => t.isActief) 
      : null;

  DagboekProvider() {
    _laadData();
  }

  Future<void> setSubscriptionLevel(SubscriptionLevel level) async {
    _subscriptionLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_subscriptionKey, level.index);
    notifyListeners();
  }

  Future<void> rotateSubscriptionLevel() async {
    final nextIndex = (_subscriptionLevel.index + 1) % SubscriptionLevel.values.length;
    await setSubscriptionLevel(SubscriptionLevel.values[nextIndex]);
  }

  Future<void> _laadData() async {
    debugPrint('=== START LOADING DATA ===');
    await _laadVanOpslag();
    
    debugPrint('After loading from storage, entries count: ${_dagboekEntries.length}');
    
    // Alleen sample data laden als nog nooit geïnitialiseerd
    if (_dagboekEntries.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final wasGeinitialiseerd = prefs.getBool(_initKey) ?? false;
      
      if (!wasGeinitialiseerd) {
        debugPrint('Eerste keer opstarten - laden sample data');
        _laadVoorbeeldData();
        await _slaOpInOpslag();
        await prefs.setBool(_initKey, true);
      } else {
        debugPrint('App al geïnitialiseerd maar geen data - gebruiker heeft mogelijk alles verwijderd');
      }
    } else {
      // Print first entry health data for debugging
      if (_dagboekEntries.isNotEmpty && _dagboekEntries.first.gezondheidsMetrics.isNotEmpty) {
        final m = _dagboekEntries.first.gezondheidsMetrics.first;
        debugPrint('First entry loaded - Eczeem Ernstig: ${m.eczeemErnstig}, Mild: ${m.eczeemMild}, Geen: ${m.geenEczeem}');
      }
    }
    
    _isGeinitialiseerd = true;
    notifyListeners();
    debugPrint('=== END LOADING DATA ===');
  }

  Future<void> _laadVanOpslag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      debugPrint('=== LADEN VAN OPSLAG ===');
      debugPrint('Key: $_storageKey');
      debugPrint('Data gevonden: ${jsonString != null ? "JA (${jsonString.length} chars)" : "NEE"}');
      
      if (jsonString != null) {
        final jsonData = jsonDecode(jsonString) as List;
        _dagboekEntries = jsonData
            .map((item) => DagboekEntry.fromJson(item as Map<String, dynamic>))
            .toList();
        _sorteerdagboekEntries();
        debugPrint('${_dagboekEntries.length} entries geladen');
      }

      final testJsonString = prefs.getString(_testStorageKey);
      if (testJsonString != null) {
        final testJsonData = jsonDecode(testJsonString) as List;
        _eliminatieTests = testJsonData
            .map((item) => EliminatieTest.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('${_eliminatieTests.length} eliminatie tests geladen');
      }

      // Inladen abonnement
      final subLevelIndex = prefs.getInt(_subscriptionKey) ?? 0;
      _subscriptionLevel = SubscriptionLevel.values[subLevelIndex.clamp(0, SubscriptionLevel.values.length - 1)];
      debugPrint('Subscription level geladen: $_subscriptionLevel');

      // Inladen allergenen
      _userAllergens = prefs.getStringList(_allergenKey) ?? [];
      debugPrint('Allergenen geladen: $_userAllergens');

    } catch (e) {
      debugPrint('❌ FOUT bij laden van opslag: $e');
    }
  }

  Future<void> _slaOpInOpslag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = _dagboekEntries.map((e) => e.toJson()).toList();
      final jsonString = jsonEncode(jsonData);
      await prefs.setString(_storageKey, jsonString);
      
      final testJsonData = _eliminatieTests.map((e) => e.toJson()).toList();
      final testJsonString = jsonEncode(testJsonData);
      await prefs.setString(_testStorageKey, testJsonString);

      await prefs.setStringList(_allergenKey, _userAllergens);
      
      debugPrint('✅ Data opgeslagen');
    } catch (e) {
      debugPrint('❌ FOUT bij opslaan in opslag: $e');
    }
  }

  // Allergeen management
  Future<void> toggleAllergen(String allergeen) async {
    if (_userAllergens.contains(allergeen)) {
      _userAllergens.remove(allergeen);
    } else {
      _userAllergens.add(allergeen);
    }
    await _slaOpInOpslag();
    notifyListeners();
  }

  List<String> checkForAllergens(String text) {
    if (text.isEmpty || _userAllergens.isEmpty) return [];
    
    final lowerText = text.toLowerCase();
    final detected = <String>{};
    
    // Plantaardige 'melk' varianten die GEEN zuivel bevatten
    final plantMilks = ['soja', 'soya', 'haver', 'amandel', 'kokos', 'rijst', 'cashew', 'spelt', 'erwten', 'pistache'];
    
    // Helper om te checken of 'melk' in de tekst staat, maar niet als onderdeel van een plant-melk
    bool hasDairyMilk(String input) {
      if (!input.contains('melk')) return false;
      
      String testText = input;
      for (var p in plantMilks) {
        testText = testText.replaceAll('${p}melk', 'PLANT_DRINK');
      }
      
      // Als er na het verwijderen van plant-melken nog steeds 'melk' staat (bv 'koemelk' of los 'melk'), is het zuivel
      return testText.contains('melk');
    }

    // Check directe matches met actieve allergenen
    for (var allergeen in _userAllergens) {
      final lowerA = allergeen.toLowerCase();
      if (lowerA == 'melk') {
        if (hasDairyMilk(lowerText)) detected.add(allergeen);
      } else if (lowerText.contains(lowerA)) {
        detected.add(allergeen);
      }
    }
    
    // Check mapping
    _allergenMapping.forEach((key, allergenen) {
      if (lowerText.contains(key)) {
        // Speciale check voor de sleutel 'melk' zelf in de mapping
        if (key == 'melk') {
          if (!hasDairyMilk(lowerText)) return; 
        }

        for (var a in allergenen) {
          if (_userAllergens.contains(a)) {
            detected.add(a);
          }
        }
      }
    });
    
    return detected.toList();
  }

  // Voeg voedsel toe
  Future<void> voegVoedselToe({
    required VoedselCategorie categorie,
    required String beschrijving,
    required List<String> ingredienten,
    String? notities,
    DateTime? datum,
  }) async {
    final nieuweEntry = VoedselEntry(
      categorie: categorie,
      beschrijving: beschrijving,
      tijdstip: datum ?? DateTime.now(),
      ingredienten: ingredienten,
      notities: notities,
    );

    _voegVoedselEntryToe(nieuweEntry, datum ?? DateTime.now());
    await _slaOpInOpslag();
    debugPrint('✅ Voedsel toegevoegd en opgeslagen');
    notifyListeners();
  }

  void _voegVoedselEntryToe(VoedselEntry entry, DateTime datum) {
    final index = _vindDagboekEntry(datum);

    if (index != null) {
      _dagboekEntries[index].voedselEntries.add(entry);
    } else {
      _dagboekEntries.add(DagboekEntry(
        datum: datum,
        voedselEntries: [entry],
        gezondheidsMetrics: [],
      ));
    }

    _sorteerdagboekEntries();
  }

  // Voeg gezondheidsmetric toe
  Future<void> voegGezondheidsMetricToe({
    required int eczeemErnstig,
    required int eczeemJeuken,
    required int eczeemMild,
    required int slaapKwaliteit,
    required int geenEczeem,
    required int roodheid,
    required int droogheid,
    required int schilfering,
    required bool medicatieGebruikt,
    String? notities,
    DateTime? datum,
  }) async {
    final nieuweMetric = GezondheidsMetric(
      tijdstip: datum ?? DateTime.now(),
      eczeemErnstig: eczeemErnstig,
      eczeemJeuken: eczeemJeuken,
      eczeemMild: eczeemMild,
      slaapKwaliteit: slaapKwaliteit,
      geenEczeem: geenEczeem,
      roodheid: roodheid,
      droogheid: droogheid,
      schilfering: schilfering,
      medicatieGebruikt: medicatieGebruikt,
      notities: notities,
    );

    final datumVoorEntry = datum ?? DateTime.now();
    final index = _vindDagboekEntry(datumVoorEntry);

    if (index != null) {
      // Vervang bestaande metrics voor deze dag
      _dagboekEntries[index].gezondheidsMetrics.clear();
      _dagboekEntries[index].gezondheidsMetrics.add(nieuweMetric);
    } else {
      _dagboekEntries.add(DagboekEntry(
        datum: datumVoorEntry,
        voedselEntries: [],
        gezondheidsMetrics: [nieuweMetric],
      ));
    }

    _sorteerdagboekEntries();
    await _slaOpInOpslag();
    notifyListeners();
  }

  // Voer analyse uit
  Future<void> voerAnalyseUit() async {
    _isAnalyseBezig = true;
    notifyListeners();

    try {
      _huidigAnalyseResultaat = await _analyseService.analyseerData(_dagboekEntries);
    } catch (e) {
      debugPrint('Analyse fout: $e');
    } finally {
      _isAnalyseBezig = false;
      notifyListeners();
    }
  }

  // Verwijder dagboek entry
  Future<void> verwijderDagboekEntry(int index) async {
    if (index >= 0 && index < _dagboekEntries.length) {
      _dagboekEntries.removeAt(index);
      await _slaOpInOpslag();
      notifyListeners();
    }
  }

  // Force save (voor directe wijzigingen in entries)
  Future<void> forceSave() async {
    await _slaOpInOpslag();
    notifyListeners();
  }

  // Update gezondheidsmetrics voor een specifieke dag
  Future<void> updateGezondheidsMetric({
    required DateTime datum,
    required int eczeemErnstig,
    required int eczeemJeuken,
    required int eczeemMild,
    required int slaapKwaliteit,
    required int geenEczeem,
    required int roodheid,
    required int droogheid,
    required int schilfering,
    required bool medicatieGebruikt,
    String? notities,
  }) async {
    final index = _vindDagboekEntry(datum);
    
    debugPrint('=== UPDATE GEZONDHEIDSMETRIC ===');
    debugPrint('Datum: $datum');
    debugPrint('Index gevonden: $index');
    
    if (index != null) {
      if (_dagboekEntries[index].gezondheidsMetrics.isNotEmpty) {
        // Update existing metric
        final bestaandeMetric = _dagboekEntries[index].gezondheidsMetrics.first;
        _dagboekEntries[index].gezondheidsMetrics[0] = GezondheidsMetric(
          id: bestaandeMetric.id,
          tijdstip: bestaandeMetric.tijdstip,
          eczeemErnstig: eczeemErnstig,
          eczeemJeuken: eczeemJeuken,
          eczeemMild: eczeemMild,
          slaapKwaliteit: slaapKwaliteit,
          geenEczeem: geenEczeem,
          roodheid: roodheid,
          droogheid: droogheid,
          schilfering: schilfering,
          medicatieGebruikt: medicatieGebruikt,
          notities: notities ?? bestaandeMetric.notities,
        );
      } else {
        // Add metric when none exists yet
        _dagboekEntries[index].gezondheidsMetrics.add(GezondheidsMetric(
          tijdstip: datum,
          eczeemErnstig: eczeemErnstig,
          eczeemJeuken: eczeemJeuken,
          eczeemMild: eczeemMild,
          slaapKwaliteit: slaapKwaliteit,
          geenEczeem: geenEczeem,
          roodheid: roodheid,
          droogheid: droogheid,
          schilfering: schilfering,
          medicatieGebruikt: medicatieGebruikt,
          notities: notities,
        ));
      }
      
      await _slaOpInOpslag();
      debugPrint('✅ Gezondheidsmetric bijgewerkt en opgeslagen');
      notifyListeners();
    } else {
      debugPrint('❌ FOUT: Kan entry niet vinden voor deze datum');
    }
  }

  // Update voedsel entry
  Future<void> updateVoedselEntry({
    required DateTime datum,
    required int voedselIndex,
    required VoedselCategorie categorie,
    required String beschrijving,
    required List<String> ingredienten,
    String? notities,
  }) async {
    final dagIndex = _vindDagboekEntry(datum);
    
    if (dagIndex != null && 
        voedselIndex >= 0 && 
        voedselIndex < _dagboekEntries[dagIndex].voedselEntries.length) {
      
      final bestaandeEntry = _dagboekEntries[dagIndex].voedselEntries[voedselIndex];
      _dagboekEntries[dagIndex].voedselEntries[voedselIndex] = VoedselEntry(
        id: bestaandeEntry.id,
        categorie: categorie,
        beschrijving: beschrijving,
        tijdstip: bestaandeEntry.tijdstip,
        ingredienten: ingredienten,
        notities: notities ?? bestaandeEntry.notities,
      );
      
      await _slaOpInOpslag();
      notifyListeners();
    }
  }

  // Verwijder specifiek voedsel item
  Future<void> verwijderVoedselItem({
    required DateTime datum,
    required int voedselIndex,
  }) async {
    final dagIndex = _vindDagboekEntry(datum);
    
    if (dagIndex != null && 
        voedselIndex >= 0 && 
        voedselIndex < _dagboekEntries[dagIndex].voedselEntries.length) {
      
      _dagboekEntries[dagIndex].voedselEntries.removeAt(voedselIndex);
      
      await _slaOpInOpslag();
      notifyListeners();
    }
  }

  // Eliminatie Test Management
  Future<void> startEliminatieTest(List<String> allergenen, {int doelDagen = 21, String? notities}) async {
    // Stop eventuele andere actieve tests
    for (int i = 0; i < _eliminatieTests.length; i++) {
      if (_eliminatieTests[i].isActief) {
        _eliminatieTests[i] = _eliminatieTests[i].copyWith(
          isActief: false, 
          eindDatum: DateTime.now()
        );
      }
    }

    final nieuweTest = EliminatieTest(
      id: const Uuid().v4(),
      allergenen: allergenen,
      startDatum: DateTime.now(),
      doelDagen: doelDagen,
      notities: notities,
    );

    _eliminatieTests.add(nieuweTest);
    await _slaOpInOpslag();
    notifyListeners();
  }

  Future<void> voegAllergeenToeAanTest(String id, String allergeen) async {
    final index = _eliminatieTests.indexWhere((t) => t.id == id);
    if (index != -1) {
      final huidigeAllergenen = List<String>.from(_eliminatieTests[index].allergenen);
      if (!huidigeAllergenen.contains(allergeen)) {
        huidigeAllergenen.add(allergeen);
        _eliminatieTests[index] = _eliminatieTests[index].copyWith(allergenen: huidigeAllergenen);
        await _slaOpInOpslag();
        notifyListeners();
      }
    }
  }

  Future<void> stopEliminatieTest(String id) async {
    final index = _eliminatieTests.indexWhere((t) => t.id == id);
    if (index != -1) {
      _eliminatieTests[index] = _eliminatieTests[index].copyWith(
        isActief: false,
        eindDatum: DateTime.now(),
      );
      await _slaOpInOpslag();
      notifyListeners();
    }
  }

  Future<void> verwijderEliminatieTest(String id) async {
    _eliminatieTests.removeWhere((t) => t.id == id);
    await _slaOpInOpslag();
    notifyListeners();
  }

  // Provocatie Management
  Future<void> startProvocatie(String testId, String allergeen, {int duurDagen = 5}) async {
    final index = _eliminatieTests.indexWhere((t) => t.id == testId);
    if (index != -1) {
      final nieuweProvocatie = ProvocatieEntry(
        allergen: allergeen,
        startDatum: DateTime.now(),
        duurDagen: duurDagen,
        isAfgerond: false,
      );

      final nieuweLijst = List<ProvocatieEntry>.from(_eliminatieTests[index].provocaties);
      nieuweLijst.add(nieuweProvocatie);

      _eliminatieTests[index] = _eliminatieTests[index].copyWith(provocaties: nieuweLijst);
      await _slaOpInOpslag();
      notifyListeners();
    }
  }

  Future<void> stopProvocatie(String testId, String allergeen) async {
    final index = _eliminatieTests.indexWhere((t) => t.id == testId);
    if (index != -1) {
      final nieuweLijst = _eliminatieTests[index].provocaties.map((p) {
        if (p.allergen == allergeen && !p.isAfgerond) {
          return p.copyWith(isAfgerond: true);
        }
        return p;
      }).toList();

      _eliminatieTests[index] = _eliminatieTests[index].copyWith(provocaties: nieuweLijst);
      await _slaOpInOpslag();
      notifyListeners();
    }
  }
  // Helper functies
  int? _vindDagboekEntry(DateTime datum) {
    for (int i = 0; i < _dagboekEntries.length; i++) {
      if (_isSameDay(_dagboekEntries[i].datum, datum)) {
        return i;
      }
    }
    return null;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _sorteerdagboekEntries() {
    _dagboekEntries.sort((a, b) => b.datum.compareTo(a.datum));
  }

  // Krijg alle ingrediënten van een specifieke dag
  Set<String> getIngredientsForDay(DateTime datum) {
    final set = <String>{};
    final index = _vindDagboekEntry(datum);
    
    if (index != null) {
      for (final voedselEntry in _dagboekEntries[index].voedselEntries) {
        set.addAll(voedselEntry.ingredienten);
      }
    }
    
    return set;
  }

  DagboekEntry? getEntryForDate(DateTime datum) {
    final index = _vindDagboekEntry(datum);
    if (index != null) {
      return _dagboekEntries[index];
    }
    return null;
  }

  // Krijg unieke ingrediënten uit het hele dagboek
  List<String> getAllIngredients() {
    final set = <String>{};
    for (final entry in _dagboekEntries) {
      for (final voedselEntry in entry.voedselEntries) {
        set.addAll(voedselEntry.ingredienten);
      }
    }
    final result = set.toList();
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  // Voorbeelddata
  void _laadVoorbeeldData() {
    final vandaag = DateTime.now();
    final random = Random();

    // Ingrediënten lijsten
    final ontbijtIngr = [
      ["Haver", "Melk", "Banaan"],
      ["Yoghurt", "Melk", "Granola"],
      ["Brood", "Ei", "Boter"],
      ["Haver", "Aardbeien", "Honing"],
      ["Toast", "Jam", "Boter"],
      ["Pannenkoekenbeslag", "Melk", "Ei"],
      ["Havermout", "Kokosmelk", "Noten"],
    ];

    final dinerIngr = [
      ["Kip", "Rijst", "Broccoli"],
      ["Pasta", "Tomatensaus", "Kaas"],
      ["Zalm", "Aardappelen", "Sperziebonen"],
      ["Rundvlees", "Wortels", "Ui"],
      ["Kalkoen", "Wilde rijst", "Paddenstoelen"],
      ["Tofu", "Brocoli", "Sesamolie"],
      ["Vis", "Groenten", "Citroensap"],
      ["Lamsvlees", "Aardappelen", "Knoflook"],
    ];

    // Dag 1 (vandaag)
    _dagboekEntries.add(DagboekEntry(
      datum: vandaag,
      voedselEntries: [
        VoedselEntry(
          categorie: VoedselCategorie.ontbijt,
          beschrijving: "Havermout met banaan",
          ingredienten: ["Haver", "Banaan", "Melk"],
        ),
        VoedselEntry(
          categorie: VoedselCategorie.lunch,
          beschrijving: "Salade met kip",
          ingredienten: ["Sla", "Kip", "Tomaat"],
        ),
      ],
        gezondheidsMetrics: [
        GezondheidsMetric(
          eczeemErnstig: 2,
          eczeemJeuken: 3,
          eczeemMild: 7,
          slaapKwaliteit: 8,
          geenEczeem: 3,
        ),
      ],
    ));

    // Dag 2 (gisteren) - Hoog eczeem voor verificatie
    _dagboekEntries.add(DagboekEntry(
      datum: vandaag.subtract(const Duration(days: 1)),
      voedselEntries: [
        VoedselEntry(
          categorie: VoedselCategorie.ontbijt,
          beschrijving: "Yoghurt met granola",
          ingredienten: ["Yoghurt", "Granola", "Honing"],
        ),
        VoedselEntry(
          categorie: VoedselCategorie.diner,
          beschrijving: "Pasta met tomatensaus",
          ingredienten: ["Pasta", "Tomaat", "Basilicum"],
        ),
      ],
        gezondheidsMetrics: [
        GezondheidsMetric(
          eczeemErnstig: 10,  // TEST: Moet nu ook als 10 op de grafiek verschijnen!
          eczeemJeuken: 9,
          eczeemMild: 1,
          slaapKwaliteit: 2,
          geenEczeem: 0,
        ),
      ],
    ));

    // Dag 3 (2 dagen geleden)
    _dagboekEntries.add(DagboekEntry(
      datum: vandaag.subtract(const Duration(days: 2)),
      voedselEntries: [
        VoedselEntry(
          categorie: VoedselCategorie.ontbijt,
          beschrijving: "Toast met ei",
          ingredienten: ["Brood", "Ei"],
        ),
        VoedselEntry(
          categorie: VoedselCategorie.snack,
          beschrijving: "Appel",
          ingredienten: ["Appel"],
        ),
        VoedselEntry(
          categorie: VoedselCategorie.diner,
          beschrijving: "Rijst met groenten",
          ingredienten: ["Rijst", "Broccoli", "Wortel"],
        ),
      ],
        gezondheidsMetrics: [
        GezondheidsMetric(
          eczeemErnstig: 1,
          eczeemJeuken: 2,
          eczeemMild: 8,
          slaapKwaliteit: 7,
          geenEczeem: 2,
        ),
      ],
    ));

    // 10 willekeurige dagen met ontbijt en diner
    for (int i = 3; i < 13; i++) {
      final datum = vandaag.subtract(Duration(days: i));
      final ontbijtIdx = random.nextInt(ontbijtIngr.length);
      final dinerIdx = random.nextInt(dinerIngr.length);

      // Random eczema waarden (hoger met melk/zuivel, lager zonder)
      final heeftMelk = ontbijtIngr[ontbijtIdx].contains("Melk") ||
          ontbijtIngr[ontbijtIdx].contains("Yoghurt") ||
          dinerIngr[dinerIdx].contains("Melk");
      
      final eczeemErnstig = heeftMelk 
          ? 4 + random.nextInt(4)  // 4-7 met melk
          : 1 + random.nextInt(3); // 1-3 zonder melk
      
      final eczeemJeuken = heeftMelk 
          ? 5 + random.nextInt(3)  // 5-7 met melk
          : 1 + random.nextInt(3); // 1-3 zonder melk

      _dagboekEntries.add(DagboekEntry(
        datum: datum,
        voedselEntries: [
          VoedselEntry(
            categorie: VoedselCategorie.ontbijt,
            beschrijving: _createBeschrijving(ontbijtIngr[ontbijtIdx]),
            ingredienten: ontbijtIngr[ontbijtIdx],
          ),
          VoedselEntry(
            categorie: VoedselCategorie.diner,
            beschrijving: _createBeschrijving(dinerIngr[dinerIdx]),
            ingredienten: dinerIngr[dinerIdx],
          ),
        ],
        gezondheidsMetrics: [
          GezondheidsMetric(
            eczeemErnstig: eczeemErnstig,
            eczeemJeuken: eczeemJeuken,
            eczeemMild: 3 + random.nextInt(6),
            slaapKwaliteit: 4 + random.nextInt(5),
            geenEczeem: 2 + random.nextInt(6),
          ),
        ],
      ));
    }

    _sorteerdagboekEntries();
  }

  String _createBeschrijving(List<String> ingredienten) {
    if (ingredienten.length >= 2) {
      return "${ingredienten[0]} met ${ingredienten.sublist(1).join(', ')}";
    }
    return ingredienten.first;
  }
}
