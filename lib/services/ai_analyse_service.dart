import '../models/dagboek_entry.dart';
import '../models/analyse_resultaat.dart';

class AIAnalyseService {
  static final AIAnalyseService _instance = AIAnalyseService._internal();
  factory AIAnalyseService() => _instance;
  AIAnalyseService._internal();

  // Hoofdanalyse functie - focus op verergering
  Future<AnalyseResultaat> analyseerData(List<DagboekEntry> dagboekEntries) async {
    // Simuleer async processing
    await Future.delayed(const Duration(milliseconds: 1500));

    final patronen = _vindEczeemPatronen(dagboekEntries);
    final correlaties = _berekenEczeemCorrelaties(dagboekEntries);
    
    // Voeg verergerende correlaties toe aan patronen
    for (final corr in correlaties) {
      if (corr.correlatieSterkte > 0.3 && corr.voedselItem != "Klinisch" && corr.voedselItem != "Behandeling") {
        final itemLower = corr.voedselItem.toLowerCase();
        patronen.add(Patroon(
          beschrijving: '⚠️ Verergering bij: ${corr.voedselItem}',
          frequentie: dagboekEntries.where((e) => e.voedselEntries.any((ve) => 
            ve.ingredienten.any((ing) => ing.toLowerCase() == itemLower))).length,
          betrouwbaarheid: corr.correlatieSterkte.abs(),
        ));
      }
    }

    final aanbevelingen = _genereerEczeemAanbevelingen(correlaties);
    
    // Bepaal het top allergen uit correlaties
    String topAllergen = 'Onbekend';
    if (correlaties.isNotEmpty) {
      final sterksteCorrelatie = correlaties.reduce((a, b) => 
          a.correlatieSterkte.abs() > b.correlatieSterkte.abs() ? a : b);
      topAllergen = sterksteCorrelatie.voedselItem;
    } else {
      // Fallback: toon het meest voorkomende allergen voor de grafiek
      topAllergen = _vindMeestVoorkomendeAllergen(dagboekEntries);
    }
    
    final dagData = _berekenDagGrafiekData(dagboekEntries, topAllergen);
    final weekData = _berekenWeekGrafiekData(dagboekEntries, topAllergen);
    final maandData = _berekenMaandGrafiekData(dagboekEntries, topAllergen);

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
          beschrijving: '🔴 Ernstige pieken waargenomen (${maxErnstig.toInt()}/10)',
          frequentie: eczeemWaardes.where((e) => e >= 7).length,
          betrouwbaarheid: 0.9,
        ));
      }
    }

    // Medicatie die niet voldoende werkt als verergerings-indicatie?
    // Of juist focussen op voedselpieken.

    return patronen;
  }

  // VERBETERDE eczeem correlaties - handelt meerdere allergenen correct
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

    // 3. Analyseer Medicatie Effectiviteit
    final dagenMetMedicatie = entries.where((e) => e.gezondheidsMetrics.any((m) => m.medicatieGebruikt)).toList();
    final dagenZonderMedicatie = entries.where((e) => e.gezondheidsMetrics.any((m) => !m.medicatieGebruikt)).toList();

    if (dagenMetMedicatie.isNotEmpty && dagenZonderMedicatie.isNotEmpty) {
      final gemEczeemMetMed = _berekenGemiddeldeEczeem(dagenMetMedicatie);
      final gemEczeemZonderMed = _berekenGemiddeldeEczeem(dagenZonderMedicatie);
      final effect = gemEczeemZonderMed - gemEczeemMetMed;

      if (effect > 0.3) {
        correlaties.add(Correlatie(
          voedselItem: "Behandeling",
          symptoom: "Medicatie",
          correlatieSterkte: -(effect / 10.0).clamp(-1.0, 1.0),
          beschrijving: "🛡️ Medicatie helpt: Symptomen dalen met ${effect.toStringAsFixed(1)} punten op dagen van gebruik.",
        ));
      }
    }

    // 4. Analyseer Klinische Tekenen
    _voegKlinischeAnalyseToe(entries, correlaties);

    // Sorteer op sterkte
    correlaties.sort((a, b) => b.correlatieSterkte.abs().compareTo(a.correlatieSterkte.abs()));
    return correlaties;
  }


  // Helper om de grootste klinische klacht te vinden
  void _voegKlinischeAnalyseToe(List<DagboekEntry> entries, List<Correlatie> correlaties) {
    final metrics = entries.expand((e) => e.gezondheidsMetrics).toList();
    if (metrics.isEmpty) return;

    final gemRood = metrics.map((m) => m.roodheid).reduce((a, b) => a + b) / metrics.length;
    final gemDroog = metrics.map((m) => m.droogheid).reduce((a, b) => a + b) / metrics.length;
    final gemSchilfer = metrics.map((m) => m.schilfering).reduce((a, b) => a + b) / metrics.length;

    if (gemRood > 3) {
      correlaties.add(Correlatie(
        voedselItem: "Gezondheid",
        symptoom: "Roodheid",
        correlatieSterkte: 0.7,
        beschrijving: "🔥 Roodheid is een prominente klacht (gem. ${gemRood.toStringAsFixed(1)}/10).",
      ));
    }
    if (gemDroog > 3) {
      correlaties.add(Correlatie(
        voedselItem: "Gezondheid",
        symptoom: "Droogheid",
        correlatieSterkte: 0.7,
        beschrijving: "❄️ Hoge mate van droogheid waargenomen (gem. ${gemDroog.toStringAsFixed(1)}/10).",
      ));
    }
    if (gemSchilfer > 3) {
      correlaties.add(Correlatie(
        voedselItem: "Gezondheid",
        symptoom: "Schilfering",
        correlatieSterkte: 0.7,
        beschrijving: "⚖️ Schilfering is aanwezig (gem. ${gemSchilfer.toStringAsFixed(1)}/10).",
      ));
    }
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

  // Grafiek data generering
  List<DagGrafiekData> _berekenDagGrafiekData(List<DagboekEntry> entries, String topAllergen) {
    final sortedEntries = List<DagboekEntry>.from(entries)
      ..sort((a, b) => a.datum.compareTo(b.datum));
    
    final allergenLijst = _getAllergenIngredients(topAllergen);
    final allergenKeywords = allergenLijst.map((e) => e.toLowerCase()).toList();
    
    // Zorg dat het topAllergen zelf ook in de keywords staat (voor specifieke ingrediënten)
    if (!allergenKeywords.contains(topAllergen.toLowerCase())) {
      allergenKeywords.add(topAllergen.toLowerCase());
    }
    
    return sortedEntries.map((entry) {
      // Allergen intake bepalen
      double allergenIntake = 0;
      for (final voedsel in entry.voedselEntries) {
        for (final ingredient in voedsel.ingredienten) {
          final lowerIng = ingredient.toLowerCase();
          if (allergenKeywords.any((kw) => lowerIng.contains(kw))) {
            allergenIntake += 2;
          }
        }
      }
      allergenIntake = allergenIntake.clamp(0, 10).toDouble();
      
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

  List<WeekGrafiekData> _berekenWeekGrafiekData(List<DagboekEntry> entries, String topAllergen) {
    final weekMap = <int, List<DagboekEntry>>{};
    
    for (final entry in entries) {
      final weekNum = getWeekNumber(entry.datum);
      weekMap.putIfAbsent(weekNum, () => []).add(entry);
    }
    
    final allergenLijst = _getAllergenIngredients(topAllergen);
    
    return weekMap.entries.map((e) {
      final weekNum = e.key;
      final weekEntries = e.value;
      
      double totalAllergen = 0;
      final allergenKeywords = allergenLijst.map((e) => e.toLowerCase()).toList();
      if (!allergenKeywords.contains(topAllergen.toLowerCase())) {
        allergenKeywords.add(topAllergen.toLowerCase());
      }
      
      for (final entry in weekEntries) {
        for (final voedsel in entry.voedselEntries) {
          for (final ingredient in voedsel.ingredienten) {
            final lowerIng = ingredient.toLowerCase();
            if (allergenKeywords.any((kw) => lowerIng.contains(kw))) {
              totalAllergen += 2;
            }
          }
        }
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

  List<MaandGrafiekData> _berekenMaandGrafiekData(List<DagboekEntry> entries, String topAllergen) {
    final maandMap = <String, List<DagboekEntry>>{};
    final maandNamenNL = [
      '', 'Januari', 'Februari', 'Maart', 'April', 'Mei', 'Juni',
      'Juli', 'Augustus', 'September', 'Oktober', 'November', 'December'
    ];
    
    for (final entry in entries) {
      final key = '${entry.datum.year}-${entry.datum.month}';
      maandMap.putIfAbsent(key, () => []).add(entry);
    }
    
    final allergenLijst = _getAllergenIngredients(topAllergen);
    
    return maandMap.entries.map((e) {
      final parts = e.key.split('-');
      final jaar = int.parse(parts[0]);
      final maand = int.parse(parts[1]);
      final maandEntries = e.value;
      
      double totalAllergen = 0;
      final allergenKeywords = allergenLijst.map((e) => e.toLowerCase()).toList();
      if (!allergenKeywords.contains(topAllergen.toLowerCase())) {
        allergenKeywords.add(topAllergen.toLowerCase());
      }
      
      for (final entry in maandEntries) {
        for (final voedsel in entry.voedselEntries) {
          for (final ingredient in voedsel.ingredienten) {
            final lowerIng = ingredient.toLowerCase();
            if (allergenKeywords.any((kw) => lowerIng.contains(kw))) {
              totalAllergen += 2;
            }
          }
        }
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

  // Helper: Vind meest voorkomende allergen
  String _vindMeestVoorkomendeAllergen(List<DagboekEntry> entries) {
    if (entries.isEmpty) return 'Onbekend';
    
    final counts = <String, int>{};
    final allergens = {
      'Zuivel': ['Melk', 'Yoghurt', 'Kaas', 'Boter', 'Kwark'],
      'Gluten': ['Brood', 'Pasta', 'Toast', 'Pannenkoeken', 'Haver'],
      'Noten': ['Noten', 'Pindas'],
      'Eieren': ['Ei', 'Eieren'],
    };

    for (final entry in entries) {
      for (final ve in entry.voedselEntries) {
        for (final ing in ve.ingredienten) {
          final lowerIng = ing.toLowerCase();
          for (final allergen in allergens.entries) {
            if (allergen.value.any((kw) => lowerIng.contains(kw.toLowerCase()))) {
              counts[allergen.key] = (counts[allergen.key] ?? 0) + 1;
            }
          }
        }
      }
    }

    if (counts.isEmpty) return 'Onbekend';
    
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  // Helper: Geef ingrediënten voor een allergen (of combinatie)
  List<String> _getAllergenIngredients(String allergen) {
    if (allergen == 'Onbekend' || allergen == 'Klinisch' || allergen == 'Behandeling') {
      return [];
    }

    final allergenMap = {
      'Zuivel': ['Melk', 'Yoghurt', 'Kaas', 'Boter', 'Kwark', 'Slagroom'],
      'Gluten': ['Brood', 'Pasta', 'Toast', 'Pannenkoeken', 'Haver', 'Tarwe'],
      'Noten': ['Noten', 'Pindas', 'Walnoten', 'Amandelen'],
      'Eieren': ['Ei', 'Eieren'],
      'Suiker': ['Suiker', 'Snoep', 'Chocolade', 'Honing'],
    };
    
    // Check of het een combinatie is (bevat " + ")
    if (allergen.contains(' + ')) {
      final delen = allergen.split(' + ');
      final allIngredients = <String>[];
      for (final deel in delen) {
        final ingredients = allergenMap[deel.trim()];
        if (ingredients != null) {
          allIngredients.addAll(ingredients);
        }
      }
      return allIngredients;
    }
    
    final results = allergenMap[allergen] ?? [];
    // Als het niet in de map staat, is het waarschijnlijk een specifiek ingrediënt
    if (results.isEmpty) {
      return [allergen];
    }
    return results;
  }

  // Helper: Bereken weeknummer van een datum
  int getWeekNumber(DateTime date) {
    // ISO 8601 week number calculation
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }
}
