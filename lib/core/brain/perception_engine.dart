import 'evidence.dart';

class PerceptionEngine {
  const PerceptionEngine();

  List<Evidence> perceive(String message) {
    final text = message.toLowerCase();

    final evidence = <Evidence>[];

    if (text.contains('düşünüyorum') || text.contains('thinking')) {
      evidence.add(
        const Evidence(
          type: 'thinking',
          value: 'repetitive_thinking',
          confidence: 0.80,
        ),
      );
    }

    if (text.contains('ya şöyle olursa') || text.contains('what if')) {
      evidence.add(
        const Evidence(
          type: 'uncertainty',
          value: 'future_uncertainty',
          confidence: 0.85,
        ),
      );
    }

    if (text.contains('kafam durmuyor') || text.contains("mind won't stop")) {
      evidence.add(
        const Evidence(
          type: 'cognition',
          value: 'mental_overload',
          confidence: 0.90,
        ),
      );
    }

    return evidence;
  }
}
