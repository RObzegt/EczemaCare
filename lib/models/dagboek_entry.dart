import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'voedsel_entry.dart';
import 'gezondheids_metric.dart';

class DagboekEntry {
  final String id;
  final DateTime datum;
  final List<VoedselEntry> voedselEntries;
  final List<GezondheidsMetric> gezondheidsMetrics;

  DagboekEntry({
    String? id,
    DateTime? datum,
    List<VoedselEntry>? voedselEntries,
    List<GezondheidsMetric>? gezondheidsMetrics,
  })  : id = id ?? const Uuid().v4(),
        datum = datum ?? DateTime.now(),
        voedselEntries = voedselEntries ?? [],
        gezondheidsMetrics = gezondheidsMetrics ?? [];

  String get dagVanWeek {
    return DateFormat('EEEE', 'nl_NL').format(datum);
  }

  String get geformateerdeDatum {
    return DateFormat('d MMMM yyyy', 'nl_NL').format(datum);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'datum': datum.toIso8601String(),
      'voedselEntries': voedselEntries.map((e) => e.toJson()).toList(),
      'gezondheidsMetrics': gezondheidsMetrics.map((e) => e.toJson()).toList(),
    };
  }

  factory DagboekEntry.fromJson(Map<String, dynamic> json) {
    return DagboekEntry(
      id: json['id'],
      datum: DateTime.parse(json['datum']),
      voedselEntries: (json['voedselEntries'] as List)
          .map((e) => VoedselEntry.fromJson(e))
          .toList(),
      gezondheidsMetrics: (json['gezondheidsMetrics'] as List)
          .map((e) => GezondheidsMetric.fromJson(e))
          .toList(),
    );
  }
}
