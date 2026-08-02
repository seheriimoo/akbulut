class EmotionalPattern {
  final String id;
  final String name;
  final String description;
  final double confidence;
  final int observations;

  const EmotionalPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.confidence,
    required this.observations,
  });

  EmotionalPattern copyWith({
    String? id,
    String? name,
    String? description,
    double? confidence,
    int? observations,
  }) {
    return EmotionalPattern(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      confidence: confidence ?? this.confidence,
      observations: observations ?? this.observations,
    );
  }
}
