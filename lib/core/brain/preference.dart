class Preference {
  final String id;
  final String name;
  final String description;
  final double confidence;
  final int observations;

  const Preference({
    required this.id,
    required this.name,
    required this.description,
    required this.confidence,
    required this.observations,
  });
}
