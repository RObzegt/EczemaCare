import '../models/dagboek_entry.dart';
import '../models/analyse_resultaat.dart';

/// VERBETERDE VERSIE van AI Analyse Service
/// Fixes: Betere handling van meerdere allergenen tegelijk
class AIAnalyseServiceImproved {
  static final AIAnalyseServiceImproved _instance = AIAnalyseServiceImproved._internal();
  factory AIAnalyseServiceImproved() => _instance;
  AIAnalyseServiceImproved._internal();

  // ... [Andere functies blijven hetzelfde] ...

  /// VERBETERDE correlatie berekening die meerdere allergenen goed handelt
  List<Correlatie> _berekenEczeemCorrelatiesVerbeterd(List<DagboekEntry> entries) {
    List<Correlatie> correlaties = [];

    if (entries.isEmpty) return correlaties;

    // Bekende allergenen
    final knownAllergens = {
      'Melk': ['Melk', 'Yoghurt', 'Kaas', 'Boter', 'Honing'],
      'Gluten': ['Brood', 'Pasta', 'Toast', 'Pannenkoeken'],
      'Noten': ['Noten', 'Pindas'],
      'Eieren': ['Ei'],
    };

    // STAP 1: Bepaal voor elke dag welke allergenen aanwezig zijn
    final dagenMetAllergenen = <DagboekEntry, Set<String>>{};
    
    for (final entry in entries) {
      final allergeenSet = <String>{};
      
      for (final allergenEntry in knownAllergens.entries) {
        final allergenNaam = allergenEntry.key;
        final ingredients = allergenEntry.value.map((e) => e.toLowerCase()).toList();
        
        // Check of dit allergen op deze dag gegeten is
        final heeftAllergen = entry.voedselEntries.any((ve) => 
            ve.ingredienten.any((ing) => ingredients.contains(ing.trim().toLowerCase())));
        
        if (heeftAllergen) {
          allergeenSet.add(allergenNaam);
        }
      }
      
      dagenMetAllergenen[entry] = allergeenSet;
    }

    // STAP 2: Voor elk allergen, vergelijk ALLEEN dagen zonder andere allergenen
    for (final allergenEntry in knownAllergens.entries) {
      final allergenNaam = allergenEntry.key;
      
      // Dagen met ALLEEN dit allergen (geen andere allergenen)
      final dagenAlleenDitAllergen = entries.where((entry) {
        final allergenen = dagenMetAllergenen[entry]!;
        return allergenen.contains(allergenNaam) && allergenen.length == 1;
      }).toList();
      
      // Dagen met dit allergen (ook in combinatie met anderen)
      final dagenMetAllergen = entries.where((entry) {
        return dagenMetAllergenen[entry]!.contains(allergenNaam);
      }).toList();
      
      // Dagen ZONDER allergenen (schone baseline)
      final dagenZonderAllergenen = entries.where((entry) {
        return dagenMetAllergenen[entry]!.isEmpty;
      }).toList();

      // Minimum data check
      if (dagenMetAllergen.length < 2 || dagenZonderAllergenen.isEmpty) continue;

      // METHODE 1: Vergelijk met allergen vs zonder ALLE allergenen (conservatief)
      final eczeemMetAllergen = _berekenGemiddeldeEczeem(dagenMetAllergen);
      final eczeemSchoon = _berekenGemiddeldeEczeem(dagenZonderAllergenen);
      
      final verschil = eczeemMetAllergen - eczeemSchoon;
      final percentageVerschil = eczeemSchoon > 0 
          ? (verschil.abs() / eczeemSchoon * 100).clamp(0, 200) 
          : 0.0;

      // Drempel: >40% verschil
      if (percentageVerschil >= 40 && verschil > 0) {
        final sterkte = (verschil / 10.0).clamp(-1.0, 1.0);
        
        // Extra info: aantal dagen met ALLEEN dit allergen
        final alleenInfo = dagenAlleenDitAllergen.isNotEmpty 
            ? " [${dagenAlleenDitAllergen.length}x alleen]" 
            : " [altijd in combinatie]";
        
        final beschrijving = "Waarschuwing: $allergenNaam verergert eczeem "
            "(${eczeemMetAllergen.toStringAsFixed(1)}/10 vs "
            "${eczeemSchoon.toStringAsFixed(1)}/10, "
            "+${percentageVerschil.toStringAsFixed(0)}%)$alleenInfo";

        correlaties.add(Correlatie(
          voedselItem: allergenNaam,
          symptoom: "Eczeem",
          correlatieSterkte: sterkte,
          beschrijving: beschrijving,
        ));
      }
    }

    // STAP 3: Check voor combinatie-effecten
    final combinatieCorrelaties = _checkCombinatieEffecten(
      entries, 
      dagenMetAllergenen, 
      knownAllergens
    );
    
    correlaties.addAll(combinatieCorrelaties);

    // Sorteer op sterkte
    correlaties.sort((a, b) => b.correlatieSterkte.abs().compareTo(a.correlatieSterkte.abs()));
    
    return correlaties;
  }

  /// Check voor combinatie-effecten (bv. Melk + Gluten samen erger dan apart)
  List<Correlatie> _checkCombinatieEffecten(
    List<DagboekEntry> entries,
    Map<DagboekEntry, Set<String>> dagenMetAllergenen,
    Map<String, List<String>> knownAllergens,
  ) {
    List<Correlatie> combinaties = [];

    // Veelvoorkomende combinaties om te testen
    final teTestenCombinaties = [
      ['Melk', 'Gluten'],
      ['Melk', 'Eieren'],
      ['Gluten', 'Eieren'],
      ['Noten', 'Melk'],
    ];

    for (final combinatie in teTestenCombinaties) {
      // Dagen met BEIDE allergenen
      final dagenMetCombinatie = entries.where((entry) {
        final allergenen = dagenMetAllergenen[entry]!;
        return combinatie.every((a) => allergenen.contains(a));
      }).toList();

      // Dagen met ALLEEN eerste allergen
      final dagenMetEerste = entries.where((entry) {
        final allergenen = dagenMetAllergenen[entry]!;
        return allergenen.contains(combinatie[0]) && 
               !allergenen.contains(combinatie[1]) &&
               allergenen.length == 1;
      }).toList();

      // Dagen met ALLEEN tweede allergen
      final dagenMetTweede = entries.where((entry) {
        final allergenen = dagenMetAllergenen[entry]!;
        return allergenen.contains(combinatie[1]) && 
               !allergenen.contains(combinatie[0]) &&
               allergenen.length == 1;
      }).toList();

      // Check of combinatie erger is dan individueel
      if (dagenMetCombinatie.length >= 2 && 
          dagenMetEerste.isNotEmpty && 
          dagenMetTweede.isNotEmpty) {
        
        final eczeemCombinatie = _berekenGemiddeldeEczeem(dagenMetCombinatie);
        final eczeemEerste = _berekenGemiddeldeEczeem(dagenMetEerste);
        final eczeemTweede = _berekenGemiddeldeEczeem(dagenMetTweede);
        final eczeemGemiddeldeAlleen = (eczeemEerste + eczeemTweede) / 2;

        // Is combinatie significant erger dan gemiddelde van beiden apart?
        final verschil = eczeemCombinatie - eczeemGemiddeldeAlleen;
        
        if (verschil > 1.5) { // Minstens 1.5 punten erger
          final sterkte = (verschil / 10.0).clamp(-1.0, 1.0);
          final combiNaam = "${combinatie[0]} + ${combinatie[1]}";
          
          final beschrijving = "⚠️ COMBINATIE-EFFECT: $combiNaam samen erger "
              "(${eczeemCombinatie.toStringAsFixed(1)}/10 vs "
              "${eczeemGemiddeldeAlleen.toStringAsFixed(1)}/10 apart)";

          combinaties.add(Correlatie(
            voedselItem: combiNaam,
            symptoom: "Eczeem",
            correlatieSterkte: sterkte,
            beschrijving: beschrijving,
          ));
        }
      }
    }

    return combinaties;
  }

  /// Bereken gemiddelde eczeem
  double _berekenGemiddeldeEczeem(List<DagboekEntry> entries) {
    final alleMetrics = entries.expand((e) => e.gezondheidsMetrics).toList();
    if (alleMetrics.isEmpty) return 0;
    
    final allEczeem = [
      ...alleMetrics.map((m) => m.eczeemErnstig),
      ...alleMetrics.map((m) => m.eczeemJeuken),
    ];
    
    return allEczeem.reduce((a, b) => a + b) / allEczeem.length;
  }

  /// Helper: Bereken weeknummer van een datum
  int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }
}

// GEBRUIK:
// In plaats van de oude versie, gebruik deze verbeterde versie
// De verbeterde versie:
// 1. Isoleert allergenen beter
// 2. Gebruikt alleen "schone" dagen zonder allergenen als baseline
// 3. Detecteert combinatie-effecten
// 4. Geeft extra info over hoe vaak allergen alleen voorkomt
