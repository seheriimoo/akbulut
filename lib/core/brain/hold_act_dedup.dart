import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'conversation_utterance.dart';
import 'grounded_progression.dart';
import 'night_session.dart';
import 'user_object_mirror.dart';

/// B4.1.1 — Session-level semantic act dedup for hold and minimal landing.
class HoldActDedup {
  const HoldActDedup._();

  static bool isGroundedHoldShape(String text) {
    final n = _normalize(text);
    return n.contains('kaybetmedim') ||
        n.contains('henuz tam oturmad') ||
        n.contains('henüz tam oturmad') ||
        n.contains('burada kalabilir') ||
        n.contains('tam adini koyam') ||
        n.contains('tam adını koyam') ||
        n.contains('hala sende duruyor') ||
        n.contains('hâlâ sende duruyor');
  }

  static bool sessionUsedGroundedHold(NightSession? session) {
    if (session == null) return false;
    for (final turn in session.turns) {
      final text = turn.admittedExpression?.text;
      if (text == null || text.trim().isEmpty) continue;
      if (turn.expressionMode == ConversationExpressionMode.groundedHold ||
          isGroundedHoldShape(text)) {
        return true;
      }
    }
    return false;
  }

  static String? lastAdmittedText(NightSession? session) {
    if (session == null || session.turns.isEmpty) return null;
    for (var i = session.turns.length - 1; i >= 0; i--) {
      final text = session.turns[i].admittedExpression?.text;
      if (text != null && text.trim().isNotEmpty) return text.trim();
    }
    return null;
  }

  static bool isMinimalLanding(String text) {
    final n = _normalize(text).replaceAll(RegExp(r'[.!?…]+$'), '').trim();
    return n == 'tamam' || n == 'okay' || n == 'ok';
  }

  static bool lastWasMinimalLanding(NightSession? session) {
    final last = lastAdmittedText(session);
    return last != null && isMinimalLanding(last);
  }

  static bool wouldRepeatText(NightSession? session, String candidate) {
    final last = lastAdmittedText(session);
    if (last == null) return false;
    return _normalize(last) == _normalize(candidate);
  }

  static bool sessionContainsNormalized(NightSession? session, String candidate) {
    if (session == null) return false;
    final target = _normalize(candidate);
    for (final turn in session.turns) {
      final text = turn.admittedExpression?.text;
      if (text != null && _normalize(text) == target) return true;
    }
    return false;
  }

  static ConversationUtterance? concernShiftAcknowledge({
    required String? userUtterance,
    String? groundingBlob,
    NightSession? session,
    ConversationGroundingBuffer? grounding,
  }) {
    if (userUtterance == null || userUtterance.trim().length < 8) {
      return null;
    }
    if (!ConcernShiftDetector.isShift(
      currentMessage: userUtterance,
      grounding: grounding,
      session: session,
    )) {
      return null;
    }
    return UserObjectMirror.forValidation(
      userUtterance: userUtterance,
      groundingBlob: groundingBlob,
      expressionMode: ConversationExpressionMode.observePurity,
      session: session,
      grounding: grounding,
    );
  }

  static ConversationUtterance? alternateMinimalLanding({
    required NightSession? session,
    required String? userUtterance,
    required bool prefersTurkish,
  }) {
    if (!prefersTurkish) {
      return const ConversationUtterance(text: 'Okay.');
    }
    if (lastWasMinimalLanding(session)) {
      for (final opt in const [
        'Buradasın.',
        'Söylediklerin burada.',
        'Devam edebilirsin.',
      ]) {
        if (!sessionContainsNormalized(session, opt)) {
          return ConversationUtterance(text: opt);
        }
      }
    }
    return const ConversationUtterance(text: 'Tamam.');
  }

  static ConversationUtterance? alternateGroundedHold({
    required String? userUtterance,
    String? groundingBlob,
    required NightSession? session,
    ConversationGroundingBuffer? grounding,
    required bool prefersTurkish,
  }) {
    if (!prefersTurkish) {
      return const ConversationUtterance(
        text:
            'You do not have to name it perfectly tonight. What we know is it is still keeping you awake.',
      );
    }

    final shift = concernShiftAcknowledge(
      userUtterance: userUtterance,
      groundingBlob: groundingBlob,
      session: session,
      grounding: grounding,
    );
    if (shift != null && !wouldRepeatText(session, shift.text)) return shift;

    if (NarrowExhaustionGate.userStillUncertain(userUtterance)) {
      const uncertain =
          'Tam adını koyamıyor olman da tamam. Şimdilik bildiğimiz şey, bunun seni hâlâ uyanık tuttuğu.';
      if (!sessionContainsNormalized(session, uncertain)) {
        return const ConversationUtterance(text: uncertain);
      }
    }

    if (_isSettling(userUtterance)) {
      final mirror = UserObjectMirror.forValidation(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        expressionMode: ConversationExpressionMode.observePurity,
        session: session,
        grounding: grounding,
      );
      if (mirror != null && !wouldRepeatText(session, mirror.text)) {
        return mirror;
      }
      return alternateMinimalLanding(
        session: session,
        userUtterance: userUtterance,
        prefersTurkish: prefersTurkish,
      );
    }

    final anchor = surfaceAnchor(userUtterance, groundingBlob);
    if (anchor != null) {
      final ack =
          '$anchor hâlâ sende duruyor. Bu gece çözmek zorunda değilsin.';
      if (!sessionContainsNormalized(session, ack)) {
        return ConversationUtterance(text: ack);
      }
    }

    if (userUtterance != null && userUtterance.trim().length >= 8) {
      final mirror = UserObjectMirror.forValidation(
        userUtterance: userUtterance,
        groundingBlob: groundingBlob,
        expressionMode: ConversationExpressionMode.groundedHold,
        session: session,
        grounding: grounding,
      );
      if (mirror != null && !wouldRepeatText(session, mirror.text)) {
        return mirror;
      }
    }

    if ((userUtterance == null || userUtterance.trim().length < 12) &&
        groundingBlob != null &&
        groundingBlob.trim().length >= 8) {
      final anchor = surfaceAnchor(null, groundingBlob);
      if (anchor != null) {
        final ack =
            '$anchor hâlâ sende duruyor. Bu gece çözmek zorunda değilsin.';
        if (!sessionContainsNormalized(session, ack)) {
          return ConversationUtterance(text: ack);
        }
      }
      final ctxMirror = UserObjectMirror.forValidation(
        userUtterance: groundingBlob,
        groundingBlob: groundingBlob,
        expressionMode: ConversationExpressionMode.observePurity,
        session: session,
        grounding: grounding,
      );
      if (ctxMirror != null && !wouldRepeatText(session, ctxMirror.text)) {
        return ctxMirror;
      }
    }

    return alternateMinimalLanding(
      session: session,
      userUtterance: userUtterance,
      prefersTurkish: prefersTurkish,
    );
  }

  static String? surfaceAnchor(String? user, String? blob) {
    final source = (user ?? blob ?? '').trim();
    if (source.isEmpty) return null;
    final clauses = source
        .split(RegExp(r'[,;!.?]\s*'))
        .map((c) => c.trim())
        .where((c) => c.length >= 8)
        .toList();
    if (clauses.isEmpty) return null;
    clauses.sort((a, b) => b.length.compareTo(a.length));
    final best = clauses.first;
    if (best.length > 48) {
      return '${best.substring(0, 45).trim()}…';
    }
    return best;
  }

  static bool _isSettling(String? message) {
    if (message == null) return false;
    final n = _normalize(message);
    return RegExp(
      r'\b(hallederim|halledecegim|halledeceğim|uyuyacagim|uyuyacağım|'
      r'yatcam|yatacağım|sakinles|rahatlad|tamam)\b',
    ).hasMatch(n);
  }

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[.!?…]+$'), '')
        .trim();
  }
}
