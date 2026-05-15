import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  final AIAnalyseService _analyseService = AIAnalyseService();
  static const String _storageKey = 'dagboek_entries';
  static const String _testStorageKey = 'eliminatie_tests';
  static const String _subscriptionKey = 'subscription_level';
  static const String _allergenKey = 'user_allergens';
  static const String _darkModeKey = 'dark_mode';

  List<String> _userAllergens = [];
  bool _isDarkMode = false;
  
  // Mapping van veelvoorkomende voedingsmiddelen naar hun voedingscategorieën
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
  bool get isDarkMode => _isDarkMode;
  
  bool get isGratis => false;
  bool get isBasis => false;
  bool get isPremium => true;
  
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
    
    if (_dagboekEntries.isNotEmpty && _dagboekEntries.first.gezondheidsMetrics.isNotEmpty) {
      final m = _dagboekEntries.first.gezondheidsMetrics.first;
      debugPrint('First entry loaded - Eczeem Ernstig: ${m.eczeemErnstig}, Mild: ${m.eczeemMild}, Geen: ${m.geenEczeem}');
    }
    
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

      // Inladen voeding
      _userAllergens = prefs.getStringList(_allergenKey) ?? [];
      debugPrint('Voeding geladen: $_userAllergens');

      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;

      await _verwijderOudeDemoData(prefs);
    } catch (e) {
      debugPrint('❌ FOUT bij laden van opslag: $e');
    }
  }

  /// Verwijdert eenmalig opgeslagen voorbeeld-demo uit oudere app-versies.
  Future<void> _verwijderOudeDemoData(SharedPreferences prefs) async {
    const legacyDemoIdsKey = 'demo_entry_ids';
    const legacyDemoEnabledKey = 'demo_data_enabled';

    final storedIds = prefs.getStringList(legacyDemoIdsKey) ?? const <String>[];
    final idsToRemove = <String>{...storedIds};

    if (idsToRemove.isEmpty &&
        _dagboekEntries.length == 13 &&
        _heeftVoorbeeldDataHandtekening()) {
      idsToRemove.addAll(_dagboekEntries.map((e) => e.id));
    }

    if (idsToRemove.isNotEmpty) {
      _dagboekEntries.removeWhere((e) => idsToRemove.contains(e.id));
      _sorteerdagboekEntries();
      final jsonData = _dagboekEntries.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonData));
      debugPrint('Oude demo-/voorbeelddata verwijderd (${idsToRemove.length} dagboekitems)');
    }

    await prefs.remove(legacyDemoEnabledKey);
    await prefs.remove(legacyDemoIdsKey);
  }

  bool _heeftVoorbeeldDataHandtekening() {
    bool has(String needle) {
      for (final e in _dagboekEntries) {
        for (final v in e.voedselEntries) {
          if (v.beschrijving == needle) return true;
        }
      }
      return false;
    }

    return has('Havermout met banaan') && has('Yoghurt met granola') && has('Toast met ei');
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

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  // Voeding management
  Future<void> toggleAllergen(String allergeen) async {
    if (_userAllergens.contains(allergeen)) {
      _userAllergens.remove(allergeen);
    } else {
      _userAllergens.add(allergeen);
    }
    await _slaOpInOpslag();
    notifyListeners();
  }

  List<String> checkForAllergens(String text, {List<String>? allergensOverride}) {
    final activeAllergens = allergensOverride ?? _userAllergens;
    if (text.isEmpty || activeAllergens.isEmpty) return [];
    
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

    // Check directe matches met actieve voeding
    for (var allergeen in activeAllergens) {
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
          if (activeAllergens.contains(a)) {
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
    String? dagboekEntryId,
  }) async {
    final nieuweEntry = VoedselEntry(
      categorie: categorie,
      beschrijving: beschrijving,
      tijdstip: datum ?? DateTime.now(),
      ingredienten: ingredienten,
      notities: notities,
    );

    _voegVoedselEntryToe(nieuweEntry, datum ?? DateTime.now(), dagboekEntryId: dagboekEntryId);
    await _slaOpInOpslag();
    debugPrint('✅ Voedsel toegevoegd en opgeslagen');
    notifyListeners();
  }

  void _voegVoedselEntryToe(VoedselEntry entry, DateTime datum, {String? dagboekEntryId}) {
    final index = dagboekEntryId != null
        ? _vindDagboekIndexVoorEntryId(dagboekEntryId)
        : _vindDagboekIndexVoorDatum(datum);

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
    final index = _vindDagboekIndexVoorDatum(datumVoorEntry);

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
      final allergenOnlyEntries = _buildAllergenOnlyEntries(dagboekEntries);
      _huidigAnalyseResultaat = await _analyseService.analyseerData(allergenOnlyEntries);
    } catch (e) {
      debugPrint('Analyse fout: $e');
    } finally {
      _isAnalyseBezig = false;
      notifyListeners();
    }
  }

  List<DagboekEntry> _buildAllergenOnlyEntries(List<DagboekEntry> source) {
    // Only analyze allergens the user explicitly selected.
    const fallbackAllergens = [
      'Melk',
      'Ei',
      'Gluten',
      'Noten',
      'Pinda',
      'Soja',
      'Vis',
      'Schaaldieren',
    ];
    final activeAllergens = _userAllergens.isEmpty ? fallbackAllergens : _userAllergens;

    final result = <DagboekEntry>[];
    for (final entry in source) {
      final ingredientsText = entry.voedselEntries.expand((ve) => ve.ingredienten).join(' ');
      final detected = checkForAllergens(ingredientsText, allergensOverride: activeAllergens);

      result.add(
        DagboekEntry(
          datum: entry.datum,
          voedselEntries: [
            VoedselEntry(
              categorie: VoedselCategorie.snack,
              beschrijving: 'Voeding',
              ingredienten: detected,
            ),
          ],
          gezondheidsMetrics: entry.gezondheidsMetrics,
        ),
      );
    }
    return result;
  }

  // Verwijder dagboek entry
  Future<void> verwijderDagboekEntry(int index) async {
    final visible = dagboekEntries;
    if (index >= 0 && index < visible.length) {
      final id = visible[index].id;
      _dagboekEntries.removeWhere((e) => e.id == id);
      await _slaOpInOpslag();
      notifyListeners();
    }
  }

  // Force save (voor directe wijzigingen in entries)
  Future<void> forceSave() async {
    await _slaOpInOpslag();
    notifyListeners();
  }

  /// Verplaatst een dagboekregel naar een andere kalenderdag (zelfde id, tijd van de dag behouden).
  Future<void> wijzigDagboekEntryKalenderdatum(String entryId, DateTime nieuweKalenderDag) async {
    final i = _vindDagboekIndexVoorEntryId(entryId);
    if (i == null) return;
    final e = _dagboekEntries[i];
    final old = e.datum;
    final nieuwDatum = DateTime(
      nieuweKalenderDag.year,
      nieuweKalenderDag.month,
      nieuweKalenderDag.day,
      old.hour,
      old.minute,
      old.second,
      old.millisecond,
    );
    if (_isSameDay(old, nieuwDatum)) return;

    final shiftedVoedsel = e.voedselEntries.map((v) {
      final t = v.tijdstip;
      return VoedselEntry(
        id: v.id,
        categorie: v.categorie,
        beschrijving: v.beschrijving,
        tijdstip: DateTime(nieuwDatum.year, nieuwDatum.month, nieuwDatum.day, t.hour, t.minute, t.second, t.millisecond),
        ingredienten: List<String>.from(v.ingredienten),
        notities: v.notities,
      );
    }).toList();

    final shiftedMetrics = e.gezondheidsMetrics.map((m) {
      final t = m.tijdstip;
      return GezondheidsMetric(
        id: m.id,
        tijdstip: DateTime(nieuwDatum.year, nieuwDatum.month, nieuwDatum.day, t.hour, t.minute, t.second, t.millisecond),
        eczeemErnstig: m.eczeemErnstig,
        eczeemJeuken: m.eczeemJeuken,
        eczeemMild: m.eczeemMild,
        slaapKwaliteit: m.slaapKwaliteit,
        geenEczeem: m.geenEczeem,
        roodheid: m.roodheid,
        droogheid: m.droogheid,
        schilfering: m.schilfering,
        medicatieGebruikt: m.medicatieGebruikt,
        notities: m.notities,
      );
    }).toList();

    _dagboekEntries[i] = e.copyWith(datum: nieuwDatum, voedselEntries: shiftedVoedsel, gezondheidsMetrics: shiftedMetrics);
    _sorteerdagboekEntries();
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
    String? dagboekEntryId,
  }) async {
    final index = dagboekEntryId != null
        ? _vindDagboekIndexVoorEntryId(dagboekEntryId)
        : _vindDagboekIndexVoorDatum(datum);
    
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
          tijdstip: _dagboekEntries[index].datum,
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
    String? dagboekEntryId,
  }) async {
    final dagIndex = dagboekEntryId != null
        ? _vindDagboekIndexVoorEntryId(dagboekEntryId)
        : _vindDagboekIndexVoorDatum(datum);
    
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
    String? dagboekEntryId,
  }) async {
    final dagIndex = dagboekEntryId != null
        ? _vindDagboekIndexVoorEntryId(dagboekEntryId)
        : _vindDagboekIndexVoorDatum(datum);
    
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

  Future<void> voegVoedingToeAanTest(String id, String allergeen) async {
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
  int? _vindDagboekIndexVoorEntryId(String id) {
    for (int i = 0; i < _dagboekEntries.length; i++) {
      if (_dagboekEntries[i].id == id) return i;
    }
    return null;
  }

  int? _vindDagboekIndexVoorDatum(DateTime datum) {
    for (int i = 0; i < _dagboekEntries.length; i++) {
      if (_isSameDay(_dagboekEntries[i].datum, datum)) return i;
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
    final index = _vindDagboekIndexVoorDatum(datum);
    
    if (index != null) {
      for (final voedselEntry in _dagboekEntries[index].voedselEntries) {
        set.addAll(voedselEntry.ingredienten);
      }
    }
    
    return set;
  }

  DagboekEntry? getEntryForDate(DateTime datum) {
    final index = _vindDagboekIndexVoorDatum(datum);
    if (index != null) {
      return _dagboekEntries[index];
    }
    return null;
  }

  DagboekEntry? getDagboekEntryById(String id) {
    for (final e in _dagboekEntries) {
      if (e.id == id) return e;
    }
    return null;
  }

  // Krijg unieke ingrediënten uit het hele dagboek
  List<String> getAllIngredients() {
    final set = <String>{};
    for (final entry in dagboekEntries) {
      for (final voedselEntry in entry.voedselEntries) {
        set.addAll(voedselEntry.ingredienten);
      }
    }
    final result = set.toList();
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }
}
