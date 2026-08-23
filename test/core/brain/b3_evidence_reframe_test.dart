import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/evidence_bound_reframe_contract.dart';
import 'package:slowave/core/brain/reframe_admission_gate.dart';
import 'package:slowave/core/brain/reframe_evidence_reader.dart';
import 'package:slowave/core/brain/deterministic_reframe_builder.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/conversation_arc_reader.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/prior_admitted_expression.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/working_mind_view.dart';
import 'package:slowave/core/brain/utterance_guard.dart';

LivingMindModel _emptyModel() {
  final now = DateTime.now().toUtc();
  return LivingMindModel(
    identity: Identity(
      userId: 'test',
      preferredLanguage: 'tr',
      timezone: 'UTC',
      createdAt: now,
      lastInteractionAt: now,
      totalSessions: 0,
    ),
    mentalPatterns: const [],
    emotionalPatterns: const [],
    triggers: const [],
    beliefs: const [],
    needs: const [],
    preferences: const [],
  );
}

NightSession _sessionWithTurns(List<SessionTurn> turns) {
  return NightSession(
    workingMind: WorkingMindView(model: _emptyModel()),
    turns: turns,
  );
}

void main() {
  const guard = UtteranceGuard();
  const policy = ConversationPolicy();
  const admissionGate = ReframeAdmissionGate();

  group('B3 evidence ledger', () {
    test('reframe rejects when evidence ledger missing', () {
      const baski =
          'O zaman yapacakların değil, yarınki baskının tekrar geleceği hissi geceyi açık tutuyor olabilir.';
      expect(
        guard.allow(
          utterance: const ConversationUtterance(text: baski),
          what: ConversationPhase.validation,
          userUtterance: 'yarın stresli',
          expressionMode: ConversationExpressionMode.reframe,
        ),
        isNull,
      );
    });

    test('B15 correction invalidates mother/travma reframes', () {
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('Annem aradı, yine aynı konular.')
          .appendUserUtterance('Evet sinirlendim.')
          .appendUserUtterance('Hayır, annemle çözülmemiş travma falan yok.');

      final ledger = ReframeEvidenceReader.fromGrounding(grounding);
      expect(ledger.invalidatedTopics, isNotEmpty);

      const bad =
          'O zaman annenle yaşadıklarının tekrar etmesinden korkuyor olabilirsin.';
      expect(
        EvidenceBoundReframeContract.admits(
          reframeText: bad,
          ledger: ledger,
        ),
        isFalse,
      );

      const pressure =
          'O zaman yapacakların değil, yarınki baskının tekrar geleceği hissi geceyi açık tutuyor olabilir.';
      expect(
        EvidenceBoundReframeContract.admits(
          reframeText: pressure,
          ledger: ledger,
        ),
        isFalse,
      );
    });

    test('golden path earns appearance reframe', () {
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('Yarın müdürümle konuşacağım, uyuyamıyorum.')
          .appendUserUtterance('Evet.')
          .appendUserUtterance('Tepkisi. Beni yetersiz bulmasından korkuyorum.');

      final ledger = ReframeEvidenceReader.fromGrounding(grounding);
      final earned = ledger.strongestEarned();
      expect(earned, isNotNull);

      final line = DeterministicReframeBuilder.forValidation(ledger: ledger);
      expect(line, isNotNull);
      expect(
        guard.allow(
          utterance: line!,
          what: ConversationPhase.validation,
          userUtterance: grounding.currentUserUtterance,
          expressionMode: ConversationExpressionMode.reframe,
          reframeEvidenceLedger: ledger,
        ),
        isNotNull,
      );
    });

    test('B02-style patron trust earns reframe', () {
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('Pazartesi lansman var, ekibin yarısı cevap vermiyor.')
          .appendUserUtterance('Ben mi fazla stres yapıyorum bilmiyorum.')
          .appendUserUtterance('Aslında patronun bana güvenmediğini düşünüyorum.');

      final ledger = ReframeEvidenceReader.fromGrounding(grounding);
      final earned = ledger.strongestEarned();
      expect(earned?.kind.name, contains('boss'));
    });

    test('özlem alone does not earn mixed longing+resentment reframe', () {
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance("Instagram'da karşıma çıktı, içim çöktü.")
          .appendUserUtterance('Özlem var hâlâ.');

      final ledger = ReframeEvidenceReader.fromGrounding(grounding);
      expect(ledger.strongestEarned(), isNull);

      const invented =
          'O zaman ikisi ayrı duygular gibi duruyor; özlem bir yanda, kırgınlık bir yanda duruyor olabilir.';
      expect(
        EvidenceBoundReframeContract.admits(
          reframeText: invented,
          ledger: ledger,
        ),
        isFalse,
      );
    });
  });

  group('B3 admission gate routing', () {
    test('user correction routes to noBasis not reframe', () {
      final session = _sessionWithTurns(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.observePurity,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Annem aradı.',
          ),
        ),
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.narrow,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Fork?',
          ),
        ),
      ]);
      final arc = ConversationArcReader.fromSession(session);
      final grounding = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('Annem aradı, yine aynı konular.')
          .appendUserUtterance('Evet sinirlendim.')
          .appendUserUtterance('Hayır, annemle çözülmemiş travma falan yok.');

      final decision = admissionGate.evaluate(
        session: session,
        message: grounding.currentUserUtterance,
        understanding: null,
        conversationGrounding: grounding,
        arc: arc,
      );
      expect(decision.outcome, ReframeAdmissionOutcome.noBasis);

      final route = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        session: session,
        message: grounding.currentUserUtterance,
        conversationGrounding: grounding,
      );
      expect(route.expressionMode, isNot(ConversationExpressionMode.reframe));
    });
  });
}
