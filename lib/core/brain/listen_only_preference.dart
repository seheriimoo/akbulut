import 'conversation_grounding_buffer.dart';

/// Structural listen-only interaction constraint for the active night.
///
/// Not persona-specific — detects explicit interaction preference only.
class ListenOnlyPreference {
  const ListenOnlyPreference._();

  static final _declarePatterns = RegExp(
    r"(sadece dinle|sadece\s+dinle|just listen|only listen|"
    r"don't analyze|dont analyze|do not analyze|no analysis|"
    r"soru sorma|soru\s+sorma|don't ask|dont ask|"
    r"sadece burada ol|just be here|just stay here|"
    r"analiz yapma|yorum yapma|yorum\s+yapma)",
    caseSensitive: false,
  );

  static final _analysisRequestPatterns = RegExp(
    r'\b(sence neden|neden boyle|neden böyle|ne dusunuyorsun|'
    r'ne düşünüyorsun|what do you think|why do i feel|'
    r'why am i|help me understand|anlamak istiyorum|'
    r'anlamına ne|what does this mean|analiz et|analyze this)\b',
    caseSensitive: false,
  );

  static final _interpretiveAssistantPatterns = RegExp(
    r'\b(altında yatan|altinda yatan|aslında|aslinda|belki de|'
    r'temelde|muhtemelen sen|bunun anlamı|bunun anlami|'
    r'fark ettin mi|şunu fark|sunu fark|görünüşe göre|gorunuse gore)\b',
    caseSensitive: false,
  );

  static bool declaresListenOnly(String message) =>
      _declarePatterns.hasMatch(_normalize(message));

  static bool requestsAnalysis(String message) =>
      _analysisRequestPatterns.hasMatch(_normalize(message));

  /// Active when a prior turn declared listen-only and user has not reopened
  /// analysis on the current turn.
  static bool isActive({
    required String? currentMessage,
    ConversationGroundingBuffer? grounding,
    String sessionVentCorpus = '',
  }) {
    if (currentMessage != null && requestsAnalysis(currentMessage)) {
      return false;
    }

    if (currentMessage != null && declaresListenOnly(currentMessage)) {
      return true;
    }

    if (grounding != null) {
      for (final line in grounding.userUtterances) {
        if (declaresListenOnly(line)) return true;
      }
    }

    if (sessionVentCorpus.trim().isNotEmpty &&
        declaresListenOnly(sessionVentCorpus)) {
      return true;
    }

    return false;
  }

  static bool violatesListenOnly(String assistantText) {
    final lower = assistantText.toLowerCase();
    if (lower.contains('?')) return true;
    return _interpretiveAssistantPatterns.hasMatch(lower);
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c');
  }
}
