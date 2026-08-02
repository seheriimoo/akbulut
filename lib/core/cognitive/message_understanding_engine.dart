class MessageUnderstandingResult {
  final String topic;
  final String primarySubject;
  final String timeReference;
  final List<String> people;
  final List<String> events;
  final List<String> objects;
  final String summary;

  const MessageUnderstandingResult({
    required this.topic,
    required this.primarySubject,
    required this.timeReference,
    required this.people,
    required this.events,
    required this.objects,
    required this.summary,
  });
}

class MessageUnderstandingEngine {
  const MessageUnderstandingEngine._();

  static MessageUnderstandingResult analyze(String message) {
    return MessageUnderstandingResult(
      topic: "unknown",
      primarySubject: "",
      timeReference: "",
      people: const [],
      events: const [],
      objects: const [],
      summary: message,
    );
  }
}
