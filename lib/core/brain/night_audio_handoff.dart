import 'conversation_grounding_buffer.dart';
import 'night_session.dart';

/// Night → Player presentation handoff (not HCOS cognition).
///
/// Maps same-night cues into PlayerScreen [blocker] titles only.
/// Does not choose audio assets, billing, or ExitDecision.
class NightAudioHandoff {
  const NightAudioHandoff();

  /// Prefer loneliness / relationship / stress / mind from night texture.
  String blockerFor({
    required NightSession session,
    ConversationGroundingBuffer? grounding,
  }) {
    final blob = StringBuffer();
    if (grounding != null) {
      for (final line in grounding.userUtterances) {
        blob.writeln(line);
      }
    }
    for (final turn in session.turns) {
      final admitted = turn.admittedExpression?.text;
      if (admitted != null) blob.writeln(admitted);
      for (final p in turn.emotionalPatterns) {
        blob.writeln(p.id);
        blob.writeln(p.name);
      }
      for (final p in turn.mentalPatterns) {
        blob.writeln(p.id);
        blob.writeln(p.name);
      }
    }

    final lower = blob.toString().toLowerCase();

    if (_containsAny(lower, const [
      'lonely',
      'loneliness',
      'alone',
      'yalnız',
      'yalnizlik',
      'yalnızlık',
      'yalniz',
    ])) {
      return 'loneliness';
    }

    if (_containsAny(lower, const [
      'miss my',
      'miss him',
      'miss her',
      'relationship',
      'özlüyorum',
      'ozluyorum',
      'eski sevgili',
    ]) ||
        RegExp(r'\bex\b').hasMatch(lower)) {
      return 'relationship';
    }

    if (_containsAny(lower, const [
      'stress',
      'stressed',
      'anxious',
      'anxiety',
      'panic',
      'kaygı',
      'kaygi',
      'endişe',
      'endise',
      'gergin',
    ])) {
      return 'stress';
    }

    if (_containsAny(lower, const [
      'overthink',
      'racing',
      'spiral',
      'mind won',
      "mind won't",
      'thinking',
      'rehears',
      'overanalyz',
      'düşün',
      'dusun',
      'zihn',
    ])) {
      return 'mind';
    }

    return 'mind';
  }

  bool _containsAny(String lower, List<String> markers) {
    for (final marker in markers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }
}
