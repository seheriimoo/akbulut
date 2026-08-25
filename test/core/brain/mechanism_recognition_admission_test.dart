import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_arc_reader.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/mechanism_recognition_admission.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/prior_admitted_expression.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/thinking_function_hypothesis.dart';
import 'package:slowave/core/brain/thinking_function_kind.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

NightSession _session(List<SessionTurn> turns) {
  final now = DateTime.now().toUtc();
  return NightSession(
    workingMind: WorkingMindView(
      model: LivingMindModel(
        identity: Identity(
          userId: 't',
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
      ),
    ),
    turns: turns,
  );
}

SessionTurn _turn(ConversationExpressionMode mode, {String? text}) {
  return SessionTurn(
    releaseDecision:
        const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
    phase: ConversationPhase.validation,
    expressionMode: mode,
    admittedExpression: text == null
        ? null
        : PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: text,
          ),
  );
}

ValidatedUnderstanding _withTf({
  ThinkingFunctionKind kind = ThinkingFunctionKind.worstCaseRehearsal,
  double confidence = 0.82,
}) {
  return ValidatedUnderstanding(
    thinkingFunctionHypothesis: ThinkingFunctionHypothesis(
      kind: kind,
      confidence: confidence,
      evidenceIds: const ['current:worst_case'],
      supportTurnCount: 1,
    ),
  );
}

void main() {
  const policy = ConversationPolicy();

  group('Micro-slice Narrow-refine → Recognize', () {
    test('A TF supported + Narrow done + same-job → standard', () {
      final session = _session([
        _turn(ConversationExpressionMode.observePurity, text: 'observe'),
        _turn(ConversationExpressionMode.narrow, text: 'fork?'),
      ]);
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: 'Aklım utancı prova ediyor gibi.',
        understanding: _withTf(),
        session: session,
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance('İnsanların beni yanlış okuduğu halleri hayal ediyorum.')
            .appendUserUtterance('Aklım utancı prova ediyor gibi.'),
      );
      expect(decision.expressionMode, ConversationExpressionMode.standard);
      expect(decision.narrowRefinementAfterPartial, isFalse);
    });

    test('B TF supported but Narrow NOT done → no forced Recognition', () {
      final session = _session([
        _turn(ConversationExpressionMode.observePurity, text: 'observe'),
      ]);
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: 'Aklım utancı prova ediyor gibi.',
        understanding: _withTf(),
        session: session,
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance('Aklım utancı prova ediyor gibi.'),
      );
      expect(decision.expressionMode, isNot(ConversationExpressionMode.standard));
      expect(
        decision.expressionMode,
        anyOf(
          ConversationExpressionMode.narrow,
          ConversationExpressionMode.observePurity,
        ),
      );
    });

    test('C after Recognition already surfaced → no duplicate standard force',
        () {
      final session = _session([
        _turn(ConversationExpressionMode.observePurity, text: 'observe'),
        _turn(ConversationExpressionMode.narrow, text: 'fork?'),
        _turn(
          ConversationExpressionMode.standard,
          text: 'Zihnin kötü ihtimalleri prova ediyor gibi.',
        ),
      ]);
      final d = MechanismRecognitionAdmission.evaluate(
        arc: ConversationArcReader.fromSession(session),
        message: 'Aklım sürekli başka kötü sonuç buluyor.',
        understanding: _withTf(),
        session: session,
      );
      expect(d, MechanismRecognitionDecision.alreadySurfaced);

      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: 'Aklım sürekli başka kötü sonuç buluyor.',
        understanding: _withTf(),
        session: session,
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance('Aklım utancı prova ediyor gibi.')
            .appendUserUtterance('Aklım sürekli başka kötü sonuç buluyor.'),
      );
      expect(decision.expressionMode, isNot(ConversationExpressionMode.narrow));
      expect(decision.narrowRefinementAfterPartial, isFalse);
    });

    test('D correction TF null → micro-slice does not force Recognition', () {
      final session = _session([
        _turn(ConversationExpressionMode.observePurity, text: 'observe'),
        _turn(ConversationExpressionMode.narrow, text: 'fork?'),
      ]);
      const msg = 'Hayır, kötü sonuç düşünmüyorum. Sadece heyecanlıyım.';
      expect(
        MechanismRecognitionAdmission.evaluate(
          arc: ConversationArcReader.fromSession(session),
          message: msg,
          understanding: const ValidatedUnderstanding(),
          session: session,
        ),
        MechanismRecognitionDecision.noBasis,
      );
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: msg,
        understanding: const ValidatedUnderstanding(),
        session: session,
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance('Kötü şeyler hayal ediyorum sandım.')
            .appendUserUtterance(msg),
      );
      // Must not enter Narrow-refine sink on correction.
      expect(decision.narrowRefinementAfterPartial, isFalse);
      expect(
        decision.expressionMode,
        isNot(ConversationExpressionMode.narrow),
      );
    });

    test('E topic shift without TF → no forced Recognition', () {
      final session = _session([
        _turn(ConversationExpressionMode.observePurity, text: 'observe'),
        _turn(ConversationExpressionMode.narrow, text: 'fork?'),
      ]);
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: 'Neyse, eski sevgilim yazdı — şimdi aklım orada.',
        understanding: const ValidatedUnderstanding(),
        session: session,
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance('Her şeyin ters gidebileceğini düşünüyorum.')
            .appendUserUtterance(
              'Neyse, eski sevgilim yazdı — şimdi aklım orada.',
            ),
      );
      // Shift → observe; never forced standard Recognition on cleared TF.
      expect(decision.expressionMode, isNot(ConversationExpressionMode.standard));
    });

    test('F tentative TF → no forced Recognition', () {
      final session = _session([
        _turn(ConversationExpressionMode.observePurity, text: 'observe'),
        _turn(ConversationExpressionMode.narrow, text: 'fork?'),
      ]);
      final d = MechanismRecognitionAdmission.evaluate(
        arc: ConversationArcReader.fromSession(session),
        message: 'Aklım utancı prova ediyor gibi.',
        understanding: _withTf(confidence: 0.50),
        session: session,
      );
      expect(d, MechanismRecognitionDecision.noBasis);
    });

    test('G EN equivalent remains safe → standard when TF+Narrow', () {
      final session = _session([
        _turn(ConversationExpressionMode.observePurity, text: 'observe'),
        _turn(ConversationExpressionMode.narrow, text: 'fork?'),
      ]);
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: "It's like my mind is rehearsing embarrassment on loop.",
        understanding: _withTf(),
        session: session,
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance('I keep imagining people reading me wrong.')
            .appendUserUtterance(
              "It's like my mind is rehearsing embarrassment on loop.",
            ),
      );
      expect(decision.expressionMode, ConversationExpressionMode.standard);
    });
  });
}
