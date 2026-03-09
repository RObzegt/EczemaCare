class ProvocatieEntry {
  final String allergen;
  final DateTime startDatum;
  final int duurDagen;
  final bool isAfgerond;

  ProvocatieEntry({
    required this.allergen,
    required this.startDatum,
    this.duurDagen = 5,
    this.isAfgerond = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'allergen': allergen,
      'startDatum': startDatum.toIso8601String(),
      'duurDagen': duurDagen,
      'isAfgerond': isAfgerond,
    };
  }

  factory ProvocatieEntry.fromJson(Map<String, dynamic> json) {
    return ProvocatieEntry(
      allergen: json['allergen'],
      startDatum: DateTime.parse(json['startDatum']),
      duurDagen: json['duurDagen'] ?? 5,
      isAfgerond: json['isAfgerond'] ?? false,
    );
  }

  ProvocatieEntry copyWith({
    String? allergen,
    DateTime? startDatum,
    int? duurDagen,
    bool? isAfgerond,
  }) {
    return ProvocatieEntry(
      allergen: allergen ?? this.allergen,
      startDatum: startDatum ?? this.startDatum,
      duurDagen: duurDagen ?? this.duurDagen,
      isAfgerond: isAfgerond ?? this.isAfgerond,
    );
  }
}

class EliminatieTest {
  final String id;
  final List<String> allergenen;
  final DateTime startDatum;
  final DateTime? eindDatum;
  final bool isActief;
  final int doelDagen;
  final String? notities;
  final List<ProvocatieEntry> provocaties;

  EliminatieTest({
    required this.id,
    required this.allergenen,
    required this.startDatum,
    this.eindDatum,
    this.isActief = true,
    this.doelDagen = 21,
    this.notities,
    this.provocaties = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'allergenen': allergenen,
      'startDatum': startDatum.toIso8601String(),
      'eindDatum': eindDatum?.toIso8601String(),
      'isActief': isActief,
      'doelDagen': doelDagen,
      'notities': notities,
      'provocaties': provocaties.map((p) => p.toJson()).toList(),
    };
  }

  factory EliminatieTest.fromJson(Map<String, dynamic> json) {
    return EliminatieTest(
      id: json['id'],
      allergenen: List<String>.from(json['allergenen'] ?? []),
      startDatum: DateTime.parse(json['startDatum']),
      eindDatum: json['eindDatum'] != null ? DateTime.parse(json['eindDatum']) : null,
      isActief: json['isActief'] ?? true,
      doelDagen: json['doelDagen'] ?? 21,
      notities: json['notities'],
      provocaties: (json['provocaties'] as List? ?? [])
          .map((p) => ProvocatieEntry.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  EliminatieTest copyWith({
    List<String>? allergenen,
    DateTime? startDatum,
    DateTime? eindDatum,
    bool? isActief,
    int? doelDagen,
    String? notities,
    List<ProvocatieEntry>? provocaties,
  }) {
    return EliminatieTest(
      id: id,
      allergenen: allergenen ?? this.allergenen,
      startDatum: startDatum ?? this.startDatum,
      eindDatum: eindDatum ?? this.eindDatum,
      isActief: isActief ?? this.isActief,
      doelDagen: doelDagen ?? this.doelDagen,
      notities: notities ?? this.notities,
      provocaties: provocaties ?? this.provocaties,
    );
  }
}
