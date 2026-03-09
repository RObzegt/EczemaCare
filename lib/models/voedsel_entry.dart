import 'package:uuid/uuid.dart';
import 'voedsel_categorie.dart';

class VoedselEntry {
  final String id;
  final VoedselCategorie categorie;
  final String beschrijving;
  final DateTime tijdstip;
  final List<String> ingredienten;
  final String? notities;

  VoedselEntry({
    String? id,
    required this.categorie,
    required this.beschrijving,
    DateTime? tijdstip,
    List<String>? ingredienten,
    this.notities,
  })  : id = id ?? const Uuid().v4(),
        tijdstip = tijdstip ?? DateTime.now(),
        ingredienten = ingredienten ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categorie': categorie.index,
      'beschrijving': beschrijving,
      'tijdstip': tijdstip.toIso8601String(),
      'ingredienten': ingredienten,
      'notities': notities,
    };
  }

  factory VoedselEntry.fromJson(Map<String, dynamic> json) {
    return VoedselEntry(
      id: json['id'] as String?,
      categorie: VoedselCategorie.values[json['categorie'] ?? 0],
      beschrijving: json['beschrijving'] ?? '',
      tijdstip: json['tijdstip'] != null ? DateTime.parse(json['tijdstip']) : null,
      ingredienten: json['ingredienten'] != null ? List<String>.from(json['ingredienten']) : [],
      notities: json['notities'] as String?,
    );
  }
}
