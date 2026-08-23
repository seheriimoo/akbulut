import 'conversation_grounding_buffer.dart';
import 'surface_text_fuzzy.dart';

/// Session-aware locale evidence for Guard / fallback — not mirror routing.
class SessionLocale {
  const SessionLocale._();

  /// Full same-night user evidence for locale and corpus contracts.
  static String? userEvidenceBlob({
    ConversationGroundingBuffer? conversationGrounding,
    String sessionVentCorpus = '',
  }) {
    final parts = <String>[
      if (sessionVentCorpus.trim().isNotEmpty) sessionVentCorpus.trim(),
      if (conversationGrounding != null)
        ...conversationGrounding.userUtterances,
    ];
    final blob = parts.join(' ').trim();
    return blob.isEmpty ? null : blob;
  }

  static bool prefersTurkish(String? userUtterance, String? sessionBlob) =>
      SurfaceTextFuzzy.prefersTurkish(userUtterance, sessionBlob);

  static bool prefersEnglish(String? sessionBlob) {
    if (sessionBlob == null || sessionBlob.trim().isEmpty) return false;
    final lower = sessionBlob.toLowerCase();
    if (RegExp(r'[ğüşıöçâîû]').hasMatch(lower)) return false;
    return RegExp(
      r"\b(the|you|your|tonight|tomorrow|maybe|feel|cant|cannot|dont|don't)\b",
    ).hasMatch(lower);
  }

  static bool isEnglishShortAck(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return false;
    return RegExp(
      r'^(okay\.?|ok\.?|sure\.?|alright\.?|got it\.?|i hear you\.?|'
      r'i hear that\.?|understood\.?)$',
    ).hasMatch(t);
  }
}
