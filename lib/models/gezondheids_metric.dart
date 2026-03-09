import 'package:uuid/uuid.dart';

class GezondheidsMetric {
  final String id;
  final DateTime tijdstip;
  final int eczeemErnstig; // 0-10: eczema severity
  final int eczeemJeuken; // 0-10: eczema itching
  final int eczeemMild; // 0-10
  final int slaapKwaliteit; // 0-10
  final int geenEczeem; // 0-10
  final int roodheid; // 0-10: Redness (Erythema)
  final int droogheid; // 0-10: Dryness
  final int schilfering; // 0-10: Scaling
  final bool medicatieGebruikt; // True if ointment/medicine used
  final String? notities;

  GezondheidsMetric({
    String? id,
    DateTime? tijdstip,
    this.eczeemErnstig = 0,
    this.eczeemJeuken = 0,
    this.eczeemMild = 5,
    this.slaapKwaliteit = 5,
    this.geenEczeem = 5,
    this.roodheid = 0,
    this.droogheid = 0,
    this.schilfering = 0,
    this.medicatieGebruikt = false,
    this.notities,
  })  : id = id ?? const Uuid().v4(),
        tijdstip = tijdstip ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tijdstip': tijdstip.toIso8601String(),
      'eczeemErnstig': eczeemErnstig,
      'eczeemJeuken': eczeemJeuken,
      'eczeemMild': eczeemMild,
      'slaapKwaliteit': slaapKwaliteit,
      'geenEczeem': geenEczeem,
      'roodheid': roodheid,
      'droogheid': droogheid,
      'schilfering': schilfering,
      'medicatieGebruikt': medicatieGebruikt,
      'notities': notities,
    };
  }

  factory GezondheidsMetric.fromJson(Map<String, dynamic> json) {
    return GezondheidsMetric(
      id: json['id'] as String?,
      tijdstip: json['tijdstip'] != null ? DateTime.parse(json['tijdstip']) : null,
      eczeemErnstig: (json['eczeemErnstig'] ?? json['allergieSymptomen'] ?? 0) as int,
      eczeemJeuken: (json['eczeemJeuken'] ?? 0) as int,
      eczeemMild: (json['eczeemMild'] ?? json['energieNiveau'] ?? 5) as int,
      slaapKwaliteit: (json['slaapKwaliteit'] ?? 5) as int,
      geenEczeem: (json['geenEczeem'] ?? json['stressNiveau'] ?? 5) as int,
      roodheid: (json['roodheid'] ?? 0) as int,
      droogheid: (json['droogheid'] ?? 0) as int,
      schilfering: (json['schilfering'] ?? 0) as int,
      medicatieGebruikt: (json['medicatieGebruikt'] ?? false) as bool,
      notities: json['notities'] as String?,
    );
  }
}
