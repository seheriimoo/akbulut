import 'mental_pattern_status.dart';

class MentalPattern {
  final String id;
  final String name;
  final String description;
  final double confidence;
  final int observations;
  final MentalPatternStatus status;

  const MentalPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.confidence,
    required this.observations,
    required this.status,
  });

  MentalPattern copyWith({
    String? id,
    String? name,
    String? description,
    double? confidence,
    int? observations,
    MentalPatternStatus? status,
  }) {
    return MentalPattern(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      confidence: confidence ?? this.confidence,
      observations: observations ?? this.observations,
      status: status ?? this.status,
    );
  }
}
