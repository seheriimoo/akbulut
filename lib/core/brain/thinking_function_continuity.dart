import 'conversation_grounding_buffer.dart';
import 'grounded_progression.dart';
import 'mechanism_confirmation_semantics.dart';
import 'night_session.dart';
import 'thinking_function_detector.dart';
import 'thinking_function_hypothesis.dart';
import 'thinking_function_kind.dart';

/// Session-scoped Thinking Function continuity (Phase 2).
///
/// Evidence continuity — not keyword memory and not a permanent lock.
/// Fresh detection always wins when present. Prior supported hypotheses may
/// persist only when the new turn elaborates the same cognitive job.
class ThinkingFunctionContinuity {
  const ThinkingFunctionContinuity();

  static const double decayFactor = 0.88;
  static const double minPersistConfidence =
      ThinkingFunctionDetector.minEmitConfidence;

  /// Resolve this turn's hypothesis from fresh detection + optional prior.
  ///
  /// Returns null when corrected, topic-shifted, or decayed below emit floor.
  ThinkingFunctionHypothesis? resolve({
    required ThinkingFunctionHypothesis? fresh,
    required ThinkingFunctionHypothesis? prior,
    required String currentMessage,
    ConversationGroundingBuffer? conversationGrounding,
    NightSession? session,
  }) {
    final text = _normalize(currentMessage);
    if (text.isEmpty) return null;

    if (_isMechanismCorrection(text, prior?.kind)) {
      return null;
    }

    if (_isHardTopicJump(
      currentMessage: currentMessage,
      prior: prior,
      grounding: conversationGrounding,
      session: session,
    )) {
      return null;
    }

    if (fresh != null) {
      if (prior != null &&
          prior.kind == fresh.kind &&
          prior.confidence > fresh.confidence) {
        // Same job: keep the stronger continuous confidence floor.
        return ThinkingFunctionHypothesis(
          kind: fresh.kind,
          confidence: _clamp01(
            (prior.confidence * decayFactor).clamp(
              fresh.confidence,
              1.0,
            ),
          ),
          evidenceIds: [
            ...fresh.evidenceIds,
            'continuity:refresh',
            ...prior.evidenceIds.where((e) => e.startsWith('prior:')),
          ],
          supportTurnCount: prior.supportTurnCount + 1,
        );
      }
      return fresh;
    }

    if (prior == null) return null;
    if (prior.confidence < ThinkingFunctionDetector.supportedFloor) {
      // Tentative priors do not ride across turns.
      return null;
    }

    if (!_elaboratesSameJob(text, prior.kind)) {
      // Ambiguous turn: decay; drop when below emit floor.
      final decayed = _clamp01(prior.confidence * decayFactor);
      if (decayed < minPersistConfidence) return null;
      if (!_isSoftContinuation(text)) return null;
      return ThinkingFunctionHypothesis(
        kind: prior.kind,
        confidence: decayed,
        evidenceIds: [
          'continuity:decay',
          ...prior.evidenceIds,
        ],
        supportTurnCount: prior.supportTurnCount,
      );
    }

    // Same-job elaboration with new supporting evidence: refresh/stabilize
    // rather than treat as an evidence-free hop.
    final refreshed = _clamp01(
      prior.confidence >= ThinkingFunctionDetector.strongFloor
          ? prior.confidence * 0.97
          : (prior.confidence * 0.95)
              .clamp(ThinkingFunctionDetector.supportedFloor, 0.82),
    );
    if (refreshed < minPersistConfidence) return null;

    return ThinkingFunctionHypothesis(
      kind: prior.kind,
      confidence: refreshed,
      evidenceIds: [
        'continuity:elaboration_refresh',
        'current:semantic_family',
        ...prior.evidenceIds,
      ],
      supportTurnCount: prior.supportTurnCount + 1,
    );
  }

  /// Whether [message] should clear session TF storage after resolve.
  static bool shouldClearSessionStore({
    required ThinkingFunctionHypothesis? resolved,
    required String currentMessage,
    ThinkingFunctionHypothesis? prior,
    ConversationGroundingBuffer? conversationGrounding,
    NightSession? session,
  }) {
    final text = _normalize(currentMessage);
    if (_isMechanismCorrection(text, prior?.kind)) return true;
    if (_isHardTopicJump(
      currentMessage: currentMessage,
      prior: prior,
      grounding: conversationGrounding,
      session: session,
    )) {
      return true;
    }
    return resolved == null;
  }

  /// Public correction check for post-Recognition admission (same rules).
  static bool isMechanismCorrectionPublic(
    String message,
    ThinkingFunctionKind? priorKind,
  ) {
    return _isMechanismCorrection(_normalize(message), priorKind);
  }

  static bool _elaboratesSameJob(String text, ThinkingFunctionKind kind) {
    // Post-Recognition bridge: preparation-utility confirmation elaborates
    // the FUNCTION of the prior mechanism without requiring negative landing.
    if (MechanismConfirmationSemantics.confirmsOrElaboratesSameJob(
      text,
      kind,
    )) {
      return true;
    }
    switch (kind) {
      case ThinkingFunctionKind.worstCaseRehearsal:
        return _worstCaseElaboration(text);
      case ThinkingFunctionKind.earlyTomorrowCarry:
        return _tomorrowElaboration(text);
      case ThinkingFunctionKind.preparationRehearsal:
        return _preparationElaboration(text);
      case ThinkingFunctionKind.certaintyChase:
        return _certaintyElaboration(text);
      case ThinkingFunctionKind.protectiveHolding:
        return _protectiveElaboration(text);
    }
  }

  static bool _worstCaseElaboration(String text) {
    if (_negativeScenarioLoop(text)) return true;
    if (RegExp(
      r'\b(worst[- ]?case|could go wrong|goes wrong|ends? badly|'
      r'ending badly|invent\w* disaster|catastroph|'
      r'kotu senaryo|kotu ihtimal|en kotu|kotuye bagli|'
      r'her ihtimal|bad outcomes?|ends worse|'
      r'fall(ing)? apart|embarrassment|disaster (movie|film|scene)|'
      r'rehears\w*|ugly one|messed it up|baska kotu|yenisi geliyor)\b',
    ).hasMatch(text)) {
      return true;
    }
    // Structural: refuses one-event framing while mind keeps generating.
    final multi =
        RegExp(
          r'\b(not one specific|not a specific|tek bir sey degil|'
          r'different scenarios|keeps? (creating|inventing|finding|generating)|'
          r'surekli (uret|kotu)|birini bitir|birini dusun|'
          r'yenisi geliyor|baska kotu|another (one|ugly|bad))\b',
        ).hasMatch(text);
    final negative = RegExp(
      r'\b(bad|badly|worse|worst|disaster|kotu|ihtimal|alone|unsafe|'
      r'embarrass|humiliat|ruin|fall)\b',
    ).hasMatch(text);
    return multi && negative;
  }

  static bool _negativeScenarioLoop(String text) {
    final gen = RegExp(
      r'\b(scenario|scenarios|senaryo|invent|imagining|imagine|'
      r'ihtimal|creating|generat|uret\w*|path|paths|futures?|'
      r'rehears|carousel|disaster movie|drafting|yenisi)\b',
    );
    final bad = RegExp(
      r'\b(badly|worse|worst|disaster|catastrop|kotu|ends? bad|'
      r'go wrong|going wrong|alone|unsafe|embarrass|fall apart|ruin)\b',
    );
    return gen.hasMatch(text) && bad.hasMatch(text);
  }

  static bool _tomorrowElaboration(String text) => RegExp(
        r'\b(tomorrow|yarin|next day|morning|carrying|keep thinking|'
        r'duramıyorum|duramiyorum)\b',
      ).hasMatch(text);

  static bool _preparationElaboration(String text) => RegExp(
        r'\b(prepar|ready|hazir|rehears|get ready)\b',
      ).hasMatch(text);

  static bool _certaintyElaboration(String text) => RegExp(
        r'\b(one more|figure|almost|certainty|emin|bir daha)\b',
      ).hasMatch(text);

  static bool _protectiveElaboration(String text) => RegExp(
        r"\b(can'?t let go|holding|keep watch|unsafe to stop|birakamiyorum)\b",
      ).hasMatch(text);

  static bool _isSoftContinuation(String text) => RegExp(
        r"\b(still|keep|keeps|can't stop|cannot stop|hala|hâlâ|yine|"
        r'same|devam)\b',
      ).hasMatch(text);

  static bool _isMechanismCorrection(
    String text,
    ThinkingFunctionKind? priorKind,
  ) {
    // Explicit denial of worst-case / disaster imagination.
    if (RegExp(
      r"\b(not imagining|not inventing|not about (the )?worst|"
      r"i'?m just excited|just excited|not disasters?|"
      r"korkmuyorum|heyecanl[iy]|alakas[iı] yok|"
      r"kotu(ye)? (degil|dusunmuyorum|dusunmuyorum)|"
      r"kotu .{0,24}(degil|dusunmuyorum|dusunmuyorum)|"
      r"kotu sonuc .{0,12}(degil|dusunmuyorum|dusunmuyorum)|"
      r"hayir[,.]?.{0,40}kotu|"
      r"not (worried|anxious) about (what could go )?wrong)\b",
    ).hasMatch(text)) {
      return true;
    }
    if (priorKind == ThinkingFunctionKind.worstCaseRehearsal &&
        RegExp(
          r"\b(no[,.]?\s+i'?m not|hayir[,.]?\s+ben|hayir[,.]?\s+kotu|"
          r'not (that|those|catastroph)|sadece heyecan)\b',
        ).hasMatch(text) &&
        RegExp(
          r'\b(bad|worst|disaster|scenario|senaryo|wrong|kotu|excited|heyecan)\b',
        ).hasMatch(text)) {
      return true;
    }
    return false;
  }

  static bool _isHardTopicJump({
    required String currentMessage,
    required ThinkingFunctionHypothesis? prior,
    ConversationGroundingBuffer? grounding,
    NightSession? session,
  }) {
    if (prior == null) return false;
    if (ConcernShiftDetector.isShift(
      currentMessage: currentMessage,
      grounding: grounding,
      session: session,
    )) {
      return true;
    }
    final text = _normalize(currentMessage);
    // Explicit pivot into a new relational/object domain.
    if (RegExp(
      r'\b(anyway|baska konu|konuyu degistir|by the way|'
      r'aslinda baska|aslında başka)\b',
    ).hasMatch(text)) {
      if (RegExp(
        r'\b(ex\b|eski sevgili|partner|boyfriend|girlfriend|mesaj|'
        r'texted|yazdi|annem|babam)\b',
      ).hasMatch(text)) {
        return true;
      }
    }
    return false;
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

  static double _clamp01(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}
