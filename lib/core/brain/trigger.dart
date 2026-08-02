class Trigger {
  final String id;
  final String name;
  final String description;
  final int observations;

  const Trigger({
    required this.id,
    required this.name,
    required this.description,
    required this.observations,
  });

  Trigger copyWith({
    String? id,
    String? name,
    String? description,
    int? observations,
  }) {
    return Trigger(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      observations: observations ?? this.observations,
    );
  }
}
