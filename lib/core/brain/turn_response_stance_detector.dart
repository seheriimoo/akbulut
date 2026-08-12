import 'conversation_phase.dart';
import 'evidence.dart';
import 'turn_response_stance.dart';

/// Maps perception evidence (+ prior sealed WHAT) into [TurnResponseStance].
///
/// Owns no readiness, protocol, exit, or expression decisions.
/// Fail-closed: returns [TurnResponseStance.unclear] unless evidence supports
/// a more specific stance. Softening is only recognized after an ease offer.
class TurnResponseStanceDetector {
  const TurnResponseStanceDetector();

  TurnResponseStance detect({
    required List<Evidence> evidence,
    required bool hasLoad,
    ConversationPhase? priorPhase,
  }) {
    final holding = evidence.any((e) => e.value == 'holding_against_ease');
    if (holding) {
      return TurnResponseStance.holdingAgainstEase;
    }

    if (hasLoad) {
      return TurnResponseStance.continuedLoad;
    }

    final softening = evidence.any((e) => e.value == 'softening_acceptance');
    if (softening && _priorWasEaseOffer(priorPhase)) {
      return TurnResponseStance.softeningAcceptance;
    }

    return TurnResponseStance.unclear;
  }

  bool _priorWasEaseOffer(ConversationPhase? priorPhase) {
    return priorPhase == ConversationPhase.permission ||
        priorPhase == ConversationPhase.release;
  }
}
