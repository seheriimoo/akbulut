class Belief {
  final String id;
  final String name;
  final String description;
  final double confidence;
  final int observations;

  const Belief({
    required this.id,
    required this.name,
    required this.description,
    required this.confidence,
    required this.observations,
  });
}
