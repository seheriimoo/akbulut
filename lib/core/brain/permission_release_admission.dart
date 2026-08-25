import 'conversation_arc_reader.dart';
import 'conversation_expression_mode.dart';
import 'conversation_phase.dart';
import 'night_session.dart';
import 'permission_realization_contract.dart';

/// GOLD-lock admission for Permission / Release speech-acts on expression.
///
/// A freshly detected ThinkingFunction alone is NOT enough.
/// Permission/Release language on Receipt/validation requires earned
/// recognition evidence, or an explicit user rest/stop request.
class PermissionReleaseAdmission {
  const PermissionReleaseAdmission._();

  /// True when obligation-ease / put-down language may surface this turn.
  static bool allowsObligationEase({
    required ConversationPhase what,
    required ConversationExpressionMode expressionMode,
    required String? userUtterance,
    NightSession? session,
  }) {
    if (what == ConversationPhase.permission ||
        what == ConversationPhase.release) {
      return true;
    }

    if (_userRequestsRestOrStop(userUtterance)) return true;

    if (expressionMode == ConversationExpressionMode.integrate ||
        expressionMode == ConversationExpressionMode.closure ||
        expressionMode == ConversationExpressionMode.postReframeListen) {
      return true;
    }

    final arc = ConversationArcReader.fromSession(session);
    if (arc.hadReframe || arc.hadIntegrate || arc.reframeConfirmed) {
      return true;
    }

    if (session != null) {
      for (final turn in session.turns) {
        final mode = turn.expressionMode;
        if (mode == ConversationExpressionMode.reframe ||
            mode == ConversationExpressionMode.integrate ||
            mode == ConversationExpressionMode.closure) {
          return true;
        }
        final text = turn.admittedExpression?.text;
        if (text != null && _looksLikeRecognitionSurface(text)) return true;
      }
    }

    return false;
  }

  /// True when [text] is Permission obligation-ease or Release put-down.
  static bool looksLikeObligationEaseOrRelease(String text) {
    final n = _normalize(text);
    if (PermissionRealizationContract.matchesObligationEase(n)) return true;
    return _releasePutDown.hasMatch(n);
  }

  static bool _looksLikeRecognitionSurface(String text) {
    final n = _normalize(text);
    return RegExp(
      r'\b(rehears|prepar|scenario|senaryo|ihtimal|could go wrong|'
      r'imagining|invent|carrying tomorrow|certainty|mind (may|might|appears)|'
      r'zihn|belki de|perhaps .{0,40}mind|part of (your|the) mind)\b',
    ).hasMatch(n);
  }

  static bool _userRequestsRestOrStop(String? user) {
    if (user == null || user.trim().isEmpty) return false;
    final n = _normalize(user);
    return RegExp(
      r"\b(stop|enough|leave it|let (it|this) go|i (want|need) (to )?(rest|sleep)|"
      r'uyumak istiyorum|birak|bırak|yeter|rahatlamak)\b',
    ).hasMatch(n);
  }

  static String _normalize(String message) {
    return message
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('`', "'")
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .trim();
  }

  static final RegExp _releasePutDown = RegExp(
    r"\b(leave (some of |it |this )?here|"
    r'let (it|this) (rest|go)|'
    r'set (it|this|some) down|'
    r'night can hold|'
    r'put (it|this) down|'
    r'birakabilirsin|bırakabilirsin|'
    r'geceye birak|geceye bırak)\b',
  );
}
