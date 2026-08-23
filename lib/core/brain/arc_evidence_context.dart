import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'night_session.dart';

/// Read-only arc evidence from the current night (Slice 3.1).
///
/// Shaping/fallback only. No new interpretation. Summarizes what the user
/// and prior admitted lines already established.
class ArcEvidenceContext {
  const ArcEvidenceContext({
    this.lastReframeText,
    this.lastIntegrateText,
    this.userEvidenceBlob,
    this.preferredLanguage,
  });

  final String? lastReframeText;
  final String? lastIntegrateText;
  final String? userEvidenceBlob;
  final String? preferredLanguage;

  bool get prefersTurkish =>
      preferredLanguage == 'tr' ||
      _blobLooksTurkish(userEvidenceBlob ?? '') ||
      _blobLooksTurkish(lastReframeText ?? '') ||
      _blobLooksTurkish(lastIntegrateText ?? '');

  factory ArcEvidenceContext.fromNight({
    NightSession? session,
    ConversationGroundingBuffer? grounding,
  }) {
    String? reframe;
    String? integrate;
    final userParts = <String>[];

    if (grounding != null) {
      userParts.addAll(grounding.userUtterances);
    }

    if (session != null) {
      for (final turn in session.turns) {
        if (turn.expressionMode == ConversationExpressionMode.reframe &&
            turn.admittedExpression != null) {
          reframe = turn.admittedExpression!.text;
        }
        if (turn.expressionMode == ConversationExpressionMode.integrate &&
            turn.admittedExpression != null) {
          integrate = turn.admittedExpression!.text;
        }
      }
    }

    final blob = userParts.join(' ').trim();
    return ArcEvidenceContext(
      lastReframeText: reframe,
      lastIntegrateText: integrate,
      userEvidenceBlob: blob.isEmpty ? null : blob,
      preferredLanguage: _inferLanguage(blob, reframe, integrate),
    );
  }

  static String? _inferLanguage(
    String blob,
    String? reframe,
    String? integrate,
  ) {
    if (_blobLooksTurkish('$blob $reframe $integrate')) return 'tr';
    if (_blobLooksEnglish('$blob $reframe $integrate')) return 'en';
    return null;
  }

  static bool _blobLooksTurkish(String text) {
    if (text.trim().isEmpty) return false;
    final lower = text.toLowerCase();
    if (RegExp(r'[ğüşıöçâîû]').hasMatch(lower)) return true;
    const markers = [
      'yarin',
      'yarın',
      'gece',
      'evet',
      'degil',
      'değil',
      'kafam',
      'ozle',
      'özle',
      'yalniz',
      'yalnız',
      'bilmiyorum',
      'sakin',
      'rahat',
      'dogru',
      'doğru',
      'mudur',
      'müdür',
    ];
    for (final m in markers) {
      if (lower.contains(m)) return true;
    }
    return false;
  }

  static bool _blobLooksEnglish(String text) {
    final lower = text.toLowerCase();
    return RegExp(r'\b(the|you|your|tonight|tomorrow|maybe|feel)\b')
        .hasMatch(lower);
  }
}
