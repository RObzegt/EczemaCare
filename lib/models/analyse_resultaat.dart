import 'package:uuid/uuid.dart';

class AnalyseResultaat {
  final String id;
  final DateTime aanmaakDatum;
  final List<Patroon> patronen;
  final List<Correlatie> correlaties;
  final List<String> aanbevelingen;
  final List<DagGrafiekData> dagData;
  final List<WeekGrafiekData> weekData;
  final List<MaandGrafiekData> maandData;
  final String topAllergen;
  final List<MedischeBron> medicalSources;

  AnalyseResultaat({
    String? id,
    DateTime? aanmaakDatum,
    List<Patroon>? patronen,
    List<Correlatie>? correlaties,
    List<String>? aanbevelingen,
    List<DagGrafiekData>? dagData,
    List<WeekGrafiekData>? weekData,
    List<MaandGrafiekData>? maandData,
    String? topAllergen,
    List<MedischeBron>? medicalSources,
  })  : id = id ?? const Uuid().v4(),
        aanmaakDatum = aanmaakDatum ?? DateTime.now(),
        patronen = patronen ?? [],
        correlaties = correlaties ?? [],
        aanbevelingen = aanbevelingen ?? [],
        dagData = dagData ?? [],
        weekData = weekData ?? [],
        maandData = maandData ?? [],
        topAllergen = topAllergen ?? 'Onbekend',
        medicalSources = medicalSources ?? [];
}

class MedischeBron {
  final String titel;
  final String url;
  final String beschrijving;
  final String instantie; // Bijv. 'UMC Utrecht', 'NHG', 'VMCE'

  MedischeBron({
    required this.titel,
    required this.url,
    required this.beschrijving,
    required this.instantie,
  });
}

class DagGrafiekData {
  final DateTime datum;
  final int weekNum;
  final double allergenIntake; // 0-10
  final double eczeemLevel; // 0-10

  DagGrafiekData({
    required this.datum,
    required this.weekNum,
    required this.allergenIntake,
    required this.eczeemLevel,
  });
}

class WeekGrafiekData {
  final int weekNum;
  final int jaar;
  final DateTime startDatum;
  final double gemiddeldeAllergenIntake;
  final double gemiddeldeEczeem;
  final int aantalDagen;

  WeekGrafiekData({
    required this.weekNum,
    required this.jaar,
    required this.startDatum,
    required this.gemiddeldeAllergenIntake,
    required this.gemiddeldeEczeem,
    required this.aantalDagen,
  });
}

class MaandGrafiekData {
  final int maand;
  final int jaar;
  final String maandNaam;
  final double gemiddeldeAllergenIntake;
  final double gemiddeldeEczeem;
  final int aantalDagen;

  MaandGrafiekData({
    required this.maand,
    required this.jaar,
    required this.maandNaam,
    required this.gemiddeldeAllergenIntake,
    required this.gemiddeldeEczeem,
    required this.aantalDagen,
  });
}

class Patroon {
  final String id;
  final String beschrijving;
  final int frequentie;
  final double betrouwbaarheid; // 0.0 - 1.0

  Patroon({
    String? id,
    required this.beschrijving,
    required this.frequentie,
    required this.betrouwbaarheid,
  }) : id = id ?? const Uuid().v4();
}

class Correlatie {
  final String id;
  final String voedselItem;
  final String symptoom;
  final double correlatieSterkte; // -1.0 to 1.0
  final String beschrijving;

  Correlatie({
    String? id,
    required this.voedselItem,
    required this.symptoom,
    required this.correlatieSterkte,
    required this.beschrijving,
  }) : id = id ?? const Uuid().v4();
}
