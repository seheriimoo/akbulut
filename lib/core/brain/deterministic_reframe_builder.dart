import 'conversation_utterance.dart';
import 'evidence_ledger.dart';
import 'evidence_bound_reframe_contract.dart';
import 'reframe_hypothesis_kind.dart';

/// B3 — Deterministic earned reframes only (no keyword routing on current turn).
class DeterministicReframeBuilder {
  const DeterministicReframeBuilder._();

  static ConversationUtterance? forValidation({
    required EvidenceLedger ledger,
    EvidenceHypothesis? hypothesis,
    bool prefersTurkish = true,
  }) {
    final h = hypothesis ?? ledger.strongestEarned();
    if (h == null || h.invalidated) return null;
    if (h.strength != EvidenceStrength.explicitCausal &&
        h.strength != EvidenceStrength.composite) {
      return null;
    }

    final text = prefersTurkish
        ? _turkishFor(h.kind)
        : _englishFor(h.kind);
    if (text == null) return null;

    if (!EvidenceBoundReframeContract.admits(
      reframeText: text,
      ledger: ledger,
      hypothesis: h,
    )) {
      return null;
    }

    return ConversationUtterance(text: text);
  }

  static String? _turkishFor(ReframeHypothesisKind kind) {
    switch (kind) {
      case ReframeHypothesisKind.appearanceInTheirEyes:
        return 'O zaman konuşmanın kendisinden çok, onun gözünde nasıl görüneceğin geceyi açık tutuyor olabilir.';
      case ReframeHypothesisKind.tomorrowPressureReturn:
        return 'O zaman yapacakların değil, yarınki baskının tekrar geleceği hissi geceyi açık tutuyor olabilir.';
      case ReframeHypothesisKind.trustWhenTogether:
        return 'O zaman onun yanındayken hissettiğin güven, şimdi eksik kalmış gibi duruyor olabilir.';
      case ReframeHypothesisKind.bossTrustAbsence:
        return 'O zaman patronunun sana güvenmediğini düşünmen, geceyi açık tutuyor olabilir.';
      case ReframeHypothesisKind.mixedLongingResentment:
        return 'O zaman ikisi ayrı duygular gibi duruyor; özlem bir yanda, kırgınlık bir yanda duruyor olabilir.';
      case ReframeHypothesisKind.lonelinessPresence:
      case ReframeHypothesisKind.presenceInSilence:
        return 'O zaman bu gece eksik gelen şey sadece birinin fiziksel olarak burada olması değil; yanında biri varmış hissi olabilir.';
    }
  }

  static String? _englishFor(ReframeHypothesisKind kind) {
    switch (kind) {
      case ReframeHypothesisKind.appearanceInTheirEyes:
        return 'It could be less the talk itself and more how you might look in their eyes tonight.';
      case ReframeHypothesisKind.tomorrowPressureReturn:
        return 'It might be less what you will do and more the feeling that tomorrow\'s pressure returns.';
      case ReframeHypothesisKind.trustWhenTogether:
        return 'The trust you felt when you were together might be what feels missing now.';
      case ReframeHypothesisKind.bossTrustAbsence:
        return 'Believing your boss does not trust you might be what keeps tonight open.';
      case ReframeHypothesisKind.mixedLongingResentment:
        return 'Longing and resentment might be sitting as two separate feelings tonight.';
      case ReframeHypothesisKind.lonelinessPresence:
      case ReframeHypothesisKind.presenceInSilence:
        return 'What feels missing might be the sense someone is here, not just a body in the room.';
    }
  }
}
