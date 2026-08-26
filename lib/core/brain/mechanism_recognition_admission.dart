import 'conversation_arc_reader.dart';
import 'night_session.dart';
import 'post_recognition_mechanism_confirmation.dart';
import 'thinking_function_intelligence_shaping.dart';
import 'validated_understanding.dart';

/// Micro-slice: after Narrow + supported TF same-job elaboration, prefer
/// mechanism-capable Recognition (`standard`) over Narrow-refine loops.
///
/// Does not force Belki-reframe, Permission, or Release.
enum MechanismRecognitionDecision {
  /// Offer one Recognition-capable `standard` turn this mechanism epoch.
  preferStandard,

  /// Recognition already surfaced this epoch — do not refine-loop again.
  alreadySurfaced,

  /// Do not override Narrow / refine paths.
  noBasis,
}

/// Smallest structural gate for Narrow-refine → Recognize transition.
///
/// Relies on cognition: supported [ThinkingFunctionHypothesis] on this turn
/// already means fresh detection or continuity same-job (correction / topic
/// shift clear the hypothesis upstream).
class MechanismRecognitionAdmission {
  const MechanismRecognitionAdmission._();

  static MechanismRecognitionDecision evaluate({
    required ConversationArcReader arc,
    required String? message,
    required ValidatedUnderstanding? understanding,
    NightSession? session,
  }) {
    if (!arc.hadNarrow) return MechanismRecognitionDecision.noBasis;
    if (message == null || message.trim().isEmpty) {
      return MechanismRecognitionDecision.noBasis;
    }

    final hyp = understanding?.thinkingFunctionHypothesis;
    if (!ThinkingFunctionIntelligenceShaping.isSupportedOrStrong(hyp)) {
      return MechanismRecognitionDecision.noBasis;
    }

    if (_isBareOrThin(message)) return MechanismRecognitionDecision.noBasis;

    if (MechanismRecognitionEpoch.recognitionSurfaced(session)) {
      return MechanismRecognitionDecision.alreadySurfaced;
    }

    return MechanismRecognitionDecision.preferStandard;
  }

  static bool _isBareOrThin(String message) {
    final n = message
        .toLowerCase()
        .replaceAll(RegExp(r'[.!?…]+$'), '')
        .trim();
    if (n.length < 10) return true;
    return RegExp(r'^(evet|aynen|tamam|ok|okay|yes|yeah)$').hasMatch(n);
  }
}
