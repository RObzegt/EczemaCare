import '../models/dagboek_entry.dart';
import '../models/analyse_resultaat.dart';

class AIAnalyseService {
  static final AIAnalyseService _instance = AIAnalyseService._internal();
  factory AIAnalyseService() => _instance;
  AIAnalyseService._internal();

  /// Minimaal aantal unieke dagboekdagen voor betrouwbare analyse en trendgrafieken.
  static const int minDagenVoorAnalyse = 7;

  // Hoofdanalyse functie - focus op verergering
  Future<AnalyseResultaat> analyseerData(List<DagboekEntry> dagboekEntries) async {
    // Simuleer async processing
    await Future.delayed(const Duration(milliseconds: 1500));

    final uniekeDagen = _telUniekeDagen(dagboekEntries);
    final genoegData = uniekeDagen >= minDagenVoorAnalyse;
    final genuttigdeIngredienten = _verzamelGenuttigdeIngredienten(dagboekEntries);

    final patronen = _vindEczeemPatronen(dagboekEntries);
    final correlaties = genoegData
        ? _berekenEczeemCorrelaties(dagboekEntries)
        : <Correlatie>[];
    
    // Voeg verergerende correlaties toe aan patronen
    for (final corr in correlaties) {
      if (corr.correlatieSterkte > 0.3 && corr.voedselItem != "Klinisch" && corr.voedselItem != "Behandeling") {
        final itemLower = corr.voedselItem.toLowerCase();
        patronen.add(Patroon(
          beschrijving: '⚠️ Verergering bij: ${corr.voedselItem}',
          frequentie: dagboekEntries.where((e) => e.voedselEntries.any((ve) => 
            ve.ingredienten.any((ing) => ing.trim().toLowerCase() == itemLower))).length,
          betrouwbaarheid: corr.correlatieSterkte.abs(),
        ));
      }
    }

    final aanbevelingen = _genereerEczeemAanbevelingen(correlaties);
    
    // Trend: alleen een ingrediënt dat daadwerkelijk in het dagboek staat
    String topAllergen = 'Onbekend';
    if (genoegData && genuttigdeIngredienten.isNotEmpty) {
      if (correlaties.isNotEmpty) {
        final metData = correlaties
            .where((c) => genuttigdeIngredienten.contains(c.voedselItem.toLowerCase()))
            .toList();
        if (metData.isNotEmpty) {
          final sterksteCorrelatie = metData.reduce((a, b) =>
              a.correlatieSterkte.abs() > b.correlatieSterkte.abs() ? a : b);
          topAllergen = sterksteCorrelatie.voedselItem;
        }
      }
      if (topAllergen == 'Onbekend') {
        topAllergen = _vindMeestVoorkomendIngredient(dagboekEntries);
      }
    }

    final trendIngredient = topAllergen != 'Onbekend' &&
            genuttigdeIngredienten.contains(topAllergen.toLowerCase())
        ? topAllergen
        : null;

    final dagData = trendIngredient != null
        ? _berekenDagGrafiekData(dagboekEntries, trendIngredient)
        : <DagGrafiekData>[];
    final weekData = trendIngredient != null
        ? _berekenWeekGrafiekData(dagboekEntries, trendIngredient)
        : <WeekGrafiekData>[];
    final maandData = trendIngredient != null
        ? _berekenMaandGrafiekData(dagboekEntries, trendIngredient)
        : <MaandGrafiekData>[];

    return AnalyseResultaat(
      patronen: patronen,
      correlaties: correlaties,
      aanbevelingen: aanbevelingen,
      dagData: dagData,
      weekData: weekData,
      maandData: maandData,
      topAllergen: topAllergen,
      medicalSources: _getMedischeBronnen(),
    );
  }

  List<MedischeBron> _getMedischeBronnen() {
    return [
      MedischeBron(
        titel: 'Eczeem (Atopisch)',
        url: 'https://www.umcutrecht.nl/nl/ziekte/eczeem',
        instantie: 'UMC Utrecht',
        beschrijving: 'Uitgebreide patiënteninformatie over oorzaken, symptomen en behandelingen van eczeem.',
      ),
      MedischeBron(
        titel: 'NHG-Standaard Eczeem',
        url: 'https://richtlijnen.nhg.org/standaarden/eczeem',
        instantie: 'NHG',
        beschrijving: 'De officiële medische richtlijn voor huisartsen over de behandeling van eczeem.',
      ),
      MedischeBron(
        titel: 'Leven met eczeem',
        url: 'https://www.vmce.nl/',
        instantie: 'VMCE',
        beschrijving: 'Vereniging voor Mensen met Constitutioneel Eczeem; belangenbehartiging en lotgenotencontact.',
      ),
    ];
  }

  // Eczeem-specifieke patroon detectie - Alleen verergering
  List<Patroon> _vindEczeemPatronen(List<DagboekEntry> entries) {
    List<Patroon> patronen = [];

    if (entries.isEmpty) return patronen;

    // Eczeem ernst (Alleen bij hoge waarden tonen als 'verergering')
    final eczeemWaardes = entries
        .expand((e) => e.gezondheidsMetrics.map((m) => m.eczeemErnstig))
        .toList();
    if (eczeemWaardes.isNotEmpty) {
      final maxErnstig = eczeemWaardes.reduce((a, b) => a > b ? a : b);
      
      if (maxErnstig >= 7) {
        patronen.add(Patroon(
          beschrijving: 'Ernstige pieken waargenomen (${maxErnstig.toInt()}/10)',
          frequentie: eczeemWaardes.where((e) => e >= 7).length,
          betrouwbaarheid: 0.9,
        ));
      }
    }

    // Medicatie die niet voldoende werkt als verergerings-indicatie?
    // Of juist focussen op voedselpieken.

    return patronen;
  }

  // VERBETERDE eczeem correlaties - handelt meerdere voedingsmiddelen correct
  List<Correlatie> _berekenEczeemCorrelaties(List<DagboekEntry> entries) {
    List<Correlatie> correlaties = [];

    if (entries.isEmpty) return correlaties;

    // 1. Verzamel alle unieke ingrediënten die voorkomen
    final alleIngredienten = <String>{};
    for (final entry in entries) {
      for (final voedsel in entry.voedselEntries) {
        for (final ing in voedsel.ingredienten) {
          final trimmed = ing.trim();
          if (trimmed.isNotEmpty) {
            // Sla op als lowercase in de set om duplicaten door casing te voorkomen
            alleIngredienten.add(trimmed.toLowerCase());
          }
        }
      }
    }

    // 2. Bereken correlatie voor ELK ingrediënt
    for (final ingredient in alleIngredienten) {
      final dagenMetIngredient = entries.where((e) => 
        e.voedselEntries.any((ve) => ve.ingredienten.any((i) => i.trim().toLowerCase() == ingredient.toLowerCase()))
      ).toList();

      final dagenZonderIngredient = entries.where((e) => 
        !e.voedselEntries.any((ve) => ve.ingredienten.any((i) => i.trim().toLowerCase() == ingredient.toLowerCase()))
      ).toList();

      if (dagenMetIngredient.length >= 2 && dagenZonderIngredient.isNotEmpty) {
        final gemEczeemMet = _berekenGemiddeldeEczeem(dagenMetIngredient);
        final gemEczeemZonder = _berekenGemiddeldeEczeem(dagenZonderIngredient);
        
        final verschil = gemEczeemMet - gemEczeemZonder;
        
        if (verschil.abs() > 0.8) { // Significante afwijking
          // Maak de eerste letter een hoofdletter voor nette weergave
          final displayName = ingredient.isNotEmpty 
              ? ingredient[0].toUpperCase() + ingredient.substring(1)
              : ingredient;

          correlaties.add(Correlatie(
            voedselItem: displayName,
            symptoom: "Eczeem",
            correlatieSterkte: (verschil / 10.0).clamp(-1.0, 1.0),
            beschrijving: "${verschil > 0 ? '⚠️' : '✅'} $displayName: Gemiddeld ${gemEczeemMet.toStringAsFixed(1)} vs ${gemEczeemZonder.toStringAsFixed(1)} zonder.",
          ));
        }
      }
    }

    // Let op: op verzoek analyseren we alleen voeding (geen medicatie/klinische onderdelen).

    // Sorteer op sterkte
    correlaties.sort((a, b) => b.correlatieSterkte.abs().compareTo(a.correlatieSterkte.abs()));
    return correlaties;
  }

  // Eczeem aanbevelingen - Verwijderd op verzoek: alleen patronen gewenst
  List<String> _genereerEczeemAanbevelingen(List<Correlatie> correlaties) {
    return [];
  }

  // Helper Functies
  double _berekenGemiddeldeEczeem(List<DagboekEntry> entries) {
    final alleMetrics = entries.expand((e) => e.gezondheidsMetrics).toList();
    if (alleMetrics.isEmpty) return 0;
    
    final allScores = <double>[];
    for (final m in alleMetrics) {
      // Gebruik de 'Piek Ernst' (maximaal van alle indicatoren)
      // Dit zorgt ervoor dat een score van 10 ook echt als 10 op de grafiek verschijnt
      final score = [
        m.eczeemErnstig.toDouble(),
        m.eczeemJeuken.toDouble(),
        m.roodheid.toDouble(),
        m.droogheid.toDouble(),
        m.schilfering.toDouble(),
      ].reduce((a, b) => a > b ? a : b);
      
      allScores.add(score);
    }
    
    return allScores.reduce((a, b) => a + b) / allScores.length;
  }

  int _telUniekeDagen(List<DagboekEntry> entries) {
    return entries
        .map((e) => DateTime(e.datum.year, e.datum.month, e.datum.day))
        .toSet()
        .length;
  }

  Set<String> _verzamelGenuttigdeIngredienten(List<DagboekEntry> entries) {
    final ingredienten = <String>{};
    for (final entry in entries) {
      for (final voedsel in entry.voedselEntries) {
        for (final ing in voedsel.ingredienten) {
          final trimmed = ing.trim();
          if (trimmed.isNotEmpty) {
            ingredienten.add(trimmed.toLowerCase());
          }
        }
      }
    }
    return ingredienten;
  }

  bool _ingredientGenuttigd(String ingredient, String target) {
    return ingredient.trim().toLowerCase() == target.trim().toLowerCase();
  }

  double _berekenIngredientIntakeOpDag(DagboekEntry entry, String ingredient) {
    double intake = 0;
    for (final voedsel in entry.voedselEntries) {
      for (final ing in voedsel.ingredienten) {
        if (_ingredientGenuttigd(ing, ingredient)) {
          intake += 2;
        }
      }
    }
    return intake.clamp(0, 10).toDouble();
  }

  // Grafiek data generering — alleen exact gelogd ingrediënt
  List<DagGrafiekData> _berekenDagGrafiekData(List<DagboekEntry> entries, String ingredient) {
    final sortedEntries = List<DagboekEntry>.from(entries)
      ..sort((a, b) => a.datum.compareTo(b.datum));
    
    return sortedEntries.map((entry) {
      final allergenIntake = _berekenIngredientIntakeOpDag(entry, ingredient);
      
      // Eczeem level bepalen
      final eczeemLevel = _berekenGemiddeldeEczeem([entry]);
      
      // Week nummer
      final weekNum = getWeekNumber(entry.datum);
      
      return DagGrafiekData(
        datum: entry.datum,
        weekNum: weekNum,
        allergenIntake: allergenIntake,
        eczeemLevel: eczeemLevel,
      );
    }).toList();
  }

  List<WeekGrafiekData> _berekenWeekGrafiekData(List<DagboekEntry> entries, String ingredient) {
    final weekMap = <int, List<DagboekEntry>>{};
    
    for (final entry in entries) {
      final weekNum = getWeekNumber(entry.datum);
      weekMap.putIfAbsent(weekNum, () => []).add(entry);
    }
    
    return weekMap.entries.map((e) {
      final weekNum = e.key;
      final weekEntries = e.value;
      
      double totalAllergen = 0;
      for (final entry in weekEntries) {
        totalAllergen += _berekenIngredientIntakeOpDag(entry, ingredient);
      }
      final gemiddeldeAllergen = (totalAllergen / weekEntries.length).clamp(0, 10).toDouble();
      
      final gemiddeldeEczeem = _berekenGemiddeldeEczeem(weekEntries);
      final startDate = weekEntries.first.datum;
      
      return WeekGrafiekData(
        weekNum: weekNum,
        jaar: startDate.year,
        startDatum: startDate,
        gemiddeldeAllergenIntake: gemiddeldeAllergen,
        gemiddeldeEczeem: gemiddeldeEczeem,
        aantalDagen: weekEntries.length,
      );
    }).toList()
      ..sort((a, b) => a.weekNum.compareTo(b.weekNum));
  }

  List<MaandGrafiekData> _berekenMaandGrafiekData(List<DagboekEntry> entries, String ingredient) {
    final maandMap = <String, List<DagboekEntry>>{};
    final maandNamenNL = [
      '', 'Januari', 'Februari', 'Maart', 'April', 'Mei', 'Juni',
      'Juli', 'Augustus', 'September', 'Oktober', 'November', 'December'
    ];
    
    for (final entry in entries) {
      final key = '${entry.datum.year}-${entry.datum.month}';
      maandMap.putIfAbsent(key, () => []).add(entry);
    }
    
    return maandMap.entries.map((e) {
      final parts = e.key.split('-');
      final jaar = int.parse(parts[0]);
      final maand = int.parse(parts[1]);
      final maandEntries = e.value;
      
      double totalAllergen = 0;
      for (final entry in maandEntries) {
        totalAllergen += _berekenIngredientIntakeOpDag(entry, ingredient);
      }
      final gemiddeldeAllergen = (totalAllergen / maandEntries.length).clamp(0, 10).toDouble();
      
      final gemiddeldeEczeem = _berekenGemiddeldeEczeem(maandEntries);
      
      return MaandGrafiekData(
        maand: maand,
        jaar: jaar,
        maandNaam: maandNamenNL[maand],
        gemiddeldeAllergenIntake: gemiddeldeAllergen,
        gemiddeldeEczeem: gemiddeldeEczeem,
        aantalDagen: maandEntries.length,
      );
    }).toList()
      ..sort((a, b) {
        final cmp = a.jaar.compareTo(b.jaar);
        if (cmp != 0) return cmp;
        return a.maand.compareTo(b.maand);
      });
  }

  // Helper: meest gelogde ingrediënt (geen allergen-categorieën)
  String _vindMeestVoorkomendIngredient(List<DagboekEntry> entries) {
    if (entries.isEmpty) return 'Onbekend';

    final counts = <String, int>{};
    final displayNamen = <String, String>{};

    for (final entry in entries) {
      for (final ve in entry.voedselEntries) {
        for (final ing in ve.ingredienten) {
          final trimmed = ing.trim();
          if (trimmed.isEmpty) continue;
          final key = trimmed.toLowerCase();
          counts[key] = (counts[key] ?? 0) + 1;
          displayNamen.putIfAbsent(
            key,
            () => trimmed[0].toUpperCase() + trimmed.substring(1),
          );
        }
      }
    }

    if (counts.isEmpty) return 'Onbekend';

    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return displayNamen[top.key] ?? top.key;
  }

  // Helper: Bereken weeknummer van een datum
  int getWeekNumber(DateTime date) {
    // ISO 8601 week number calculation
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }
}
