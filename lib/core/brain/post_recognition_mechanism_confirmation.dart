import 'conversation_arc_reader.dart';
import 'conversation_expression_mode.dart';
import 'conversation_grounding_buffer.dart';
import 'grounded_progression.dart';
import 'mechanism_confirmation_semantics.dart';
import 'night_session.dart';
import 'thinking_function_continuity.dart';
import 'thinking_function_intelligence_shaping.dart';
import 'validated_understanding.dart';

/// Post-Recognition mechanism confirmation → one deepen / integrate-lite turn.
enum PostRecognitionConfirmationDecision {
  /// One mechanism-deepen `standard` turn this concern epoch.
  preferDeepen,

  /// Deepen already consumed this epoch — do not repeat.
  alreadyDeepened,

  /// No basis to override hold / other paths.
  noBasis,
}

/// Structural gate: Recognition already surfaced + user confirms same job
/// → exactly one deepen turn (not Narrow-refine, not groundedHold retreat,
/// not Permission/Release, not duplicate Recognition).
class PostRecognitionMechanismConfirmation {
  const PostRecognitionMechanismConfirmation._();

  static PostRecognitionConfirmationDecision evaluate({
    required ConversationArcReader arc,
    required String? message,
    required ValidatedUnderstanding? understanding,
    NightSession? session,
    ConversationGroundingBuffer? conversationGrounding,
  }) {
    if (!arc.hadNarrow) return PostRecognitionConfirmationDecision.noBasis;
    if (message == null || message.trim().isEmpty) {
      return PostRecognitionConfirmationDecision.noBasis;
    }
    if (!MechanismRecognitionEpoch.recognitionSurfaced(session)) {
      return PostRecognitionConfirmationDecision.noBasis;
    }
    if (!MechanismConfirmationSemantics.isSubstantive(message)) {
      return PostRecognitionConfirmationDecision.noBasis;
    }

    final hyp = understanding?.thinkingFunctionHypothesis;
    final supported =
        ThinkingFunctionIntelligenceShaping.isSupportedOrStrong(hyp);

    // Continuity / detect must leave a supported TF, or confirmation semantics
    // alone are insufficient without a prior supported job to deepen.
    if (!supported || hyp == null) {
      return PostRecognitionConfirmationDecision.noBasis;
    }

    final text = message;
    if (ThinkingFunctionContinuity.isMechanismCorrectionPublic(
      text,
      hyp.kind,
    )) {
      return PostRecognitionConfirmationDecision.noBasis;
    }
    if (ConcernShiftDetector.isShift(
      currentMessage: text,
      grounding: conversationGrounding,
      session: session,
    )) {
      return PostRecognitionConfirmationDecision.noBasis;
    }

    if (!MechanismConfirmationSemantics.confirmsOrElaboratesSameJob(
      text,
      hyp.kind,
    )) {
      return PostRecognitionConfirmationDecision.noBasis;
    }

    if (MechanismRecognitionEpoch.deepenConsumed(session)) {
      return PostRecognitionConfirmationDecision.alreadyDeepened;
    }

    return PostRecognitionConfirmationDecision.preferDeepen;
  }
}

/// Epoch helpers for Recognition-once / deepen-once (session mode trail).
class MechanismRecognitionEpoch {
  const MechanismRecognitionEpoch._();

  /// First `standard`/`reframe` after Narrow in this concern epoch.
  static bool recognitionSurfaced(NightSession? session) {
    if (session == null || session.turns.isEmpty) return false;
    var sawNarrow = false;
    for (final turn in session.turns) {
      final mode = turn.expressionMode;
      if (mode == ConversationExpressionMode.narrow) {
        sawNarrow = true;
        continue;
      }
      if (!sawNarrow) continue;
      if (mode == ConversationExpressionMode.standard ||
          mode == ConversationExpressionMode.reframe) {
        return true;
      }
      if (mode == ConversationExpressionMode.observePurity) {
        sawNarrow = false;
      }
    }
    return false;
  }

  /// True when a second post-Narrow `standard` already ran after Recognition
  /// (the deepen slot was consumed).
  static bool deepenConsumed(NightSession? session) {
    if (session == null || session.turns.isEmpty) return false;
    var sawNarrow = false;
    var sawRecognition = false;
    for (final turn in session.turns) {
      final mode = turn.expressionMode;
      if (mode == ConversationExpressionMode.observePurity) {
        sawNarrow = false;
        sawRecognition = false;
        continue;
      }
      if (mode == ConversationExpressionMode.narrow) {
        sawNarrow = true;
        continue;
      }
      if (!sawNarrow) continue;
      if (mode == ConversationExpressionMode.standard ||
          mode == ConversationExpressionMode.reframe) {
        if (!sawRecognition) {
          sawRecognition = true;
        } else if (mode == ConversationExpressionMode.standard) {
          // Second standard after Recognition = deepen consumed.
          return true;
        }
      }
    }
    return false;
  }
}
