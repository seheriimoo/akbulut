import 'conversation_expression_mode.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';
import 'surface_utterance_kind.dart';
import 'utterance_guard.dart';

/// B2.2 — Appropriate landing when surface mirror abstains.
///
/// Closing/minimal ack paths only. Does not invent insight or force mirror.
class ConversationalLanding {
  const ConversationalLanding._();

  static const _guard = UtteranceGuard();

  static ConversationUtterance? forValidation({
    required String? userUtterance,
    String? groundingBlob,
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
  }) {
    if (!_supportsLanding(expressionMode)) return null;
    final user = userUtterance?.trim();
    if (user == null || user.isEmpty) return null;

    final turkish = _prefersTurkish(user, groundingBlob);

    if (SurfaceUtteranceReader.isClosingIntent(user)) {
      final text = turkish ? 'İyi geceler.' : 'Good night.';
      return _admit(text, user, expressionMode);
    }

    if (!SurfaceUtteranceReader.isMinimalAck(user)) return null;

    if (SurfaceUtteranceReader.isAffirmationAck(user)) {
      // Affirmation of prior substantive turn — mirror handles via grounding.
      return null;
    }

    if (SurfaceUtteranceReader.isClosingAck(user) ||
        _groundingShowsSettling(groundingBlob)) {
      final text = turkish ? 'Tamam.' : 'Okay.';
      return _admit(text, user, expressionMode);
    }

    return null;
  }

  static bool _supportsLanding(ConversationExpressionMode mode) {
    switch (mode) {
      case ConversationExpressionMode.standard:
      case ConversationExpressionMode.observePurity:
      case ConversationExpressionMode.lightChat:
        return true;
      case ConversationExpressionMode.postReframeListen:
      case ConversationExpressionMode.narrow:
      case ConversationExpressionMode.reframe:
      case ConversationExpressionMode.integrate:
      case ConversationExpressionMode.closure:
      case ConversationExpressionMode.repair:
        return false;
    }
  }

  static bool _groundingShowsSettling(String? blob) {
    if (blob == null || blob.trim().isEmpty) return false;
    final n = _normalize(blob);
    return RegExp(
      r'\b(sakinles|rahatlad|iyiles|bilmiyorum|uyuyam|tamam)\b',
    ).hasMatch(n);
  }

  static ConversationUtterance? _admit(
    String text,
    String userUtterance,
    ConversationExpressionMode expressionMode,
  ) {
    final utterance = ConversationUtterance(text: text);
    final admitted = _guard.allow(
      utterance: utterance,
      what: ConversationPhase.validation,
      userUtterance: userUtterance,
      expressionMode: expressionMode,
    );
    return admitted;
  }

  static bool _prefersTurkish(String user, String? grounding) {
    final blob = '$user ${grounding ?? ''}';
    if (RegExp(r'[ğüşıöçâîû]').hasMatch(blob)) return true;
    final lower = blob.toLowerCase();
    const markers = ['evet', 'tamam', 'gece', 'uyuyam', 'bilmiyorum', 'iyi'];
    for (final m in markers) {
      if (lower.contains(m)) return true;
    }
    return false;
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c');
  }
}
