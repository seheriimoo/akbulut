import 'conversation_decision.dart';
import 'conversation_phase.dart';
import 'explicit_exit_intent.dart';
import 'neutral_entry_detector.dart';
import 'night_session.dart';
import 'post_audio_re_engagement.dart';
import 'release_decision.dart';
import 'turn_response_stance.dart';
import 'validated_understanding.dart';

/// ConversationPolicy
///
/// Purpose:
/// Maps ReleaseDecision into the appropriate
/// ConversationDecision according to the
/// HCOS Conversation Protocol.
///
/// Neutral Entry V1: on first-turn hold with a content-free greeting and no
/// mental/emotional load evidence, routes to [ConversationPhase.neutralEntry]
/// instead of Receipt.
///
/// Naming once V1: after a spoken Receipt on the same night, while readiness
/// is still hold and load evidence remains, routes exactly one Naming turn
/// before Permission/Release climb. Never restamps Naming.
///
/// Turn-Response Progression V1: uses prior sealed phase + turn stance so
/// Release is not re-issued after resistance or softening unless readiness
/// has genuinely rebuilt through a non-Release path.
class ConversationPolicy {
  const ConversationPolicy({
    this.neutralEntryDetector = const NeutralEntryDetector(),
    this.explicitExitIntent = const ExplicitExitIntent(),
    this.postAudioReEngagement = const PostAudioReEngagement(),
  });

  final NeutralEntryDetector neutralEntryDetector;
  final ExplicitExitIntent explicitExitIntent;
  final PostAudioReEngagement postAudioReEngagement;

  ConversationDecision decide({
    required ReleaseDecision releaseDecision,
    String? message,
    NightSession? session,
    ValidatedUnderstanding? understanding,
  }) {
    // Explicit exit intent → Enough close that may soft-handoff into audio.
    // Readiness ladder is not required when the person clearly asks to leave.
    if (message != null && explicitExitIntent.matches(message)) {
      return const ConversationDecision(
        phase: ConversationPhase.continuity,
        shouldSpeak: true,
      );
    }

    // Conversation protest / correction: leave failed Receipt pattern.
    // Recalibrate via Permission (obligation-ease) — not another Receipt
    // interpretation, not Enough→audio.
    if (_isConversationProtestOrCorrection(message)) {
      return const ConversationDecision(
        phase: ConversationPhase.permission,
        shouldSpeak: true,
      );
    }

    // Post-audio re-engagement: meaningful new turn reopens Receipt path.
    if (_isPostAudioReEngagement(message: message, session: session)) {
      return const ConversationDecision(
        phase: ConversationPhase.validation,
        shouldSpeak: true,
      );
    }

    if (_isNeutralEntry(
      releaseDecision: releaseDecision,
      message: message,
      session: session,
      understanding: understanding,
    )) {
      return const ConversationDecision(
        phase: ConversationPhase.neutralEntry,
        shouldSpeak: true,
      );
    }

    final priorPhase =
        (session == null || session.turns.isEmpty) ? null : session.turns.last.phase;
    final stance =
        understanding?.turnResponseStance ?? TurnResponseStance.unclear;
    final hasLoad = _hasLoadEvidence(understanding);

    if (priorPhase == ConversationPhase.release) {
      return _decideAfterRelease(
        releaseDecision: releaseDecision,
        stance: stance,
        hasLoad: hasLoad,
        priorPhase: ConversationPhase.release,
      );
    }

    return _decideBase(
      releaseDecision: releaseDecision,
      priorPhase: priorPhase,
      session: session,
      hasLoad: hasLoad,
    );
  }

  ConversationDecision _decideAfterRelease({
    required ReleaseDecision releaseDecision,
    required TurnResponseStance stance,
    required bool hasLoad,
    required ConversationPhase priorPhase,
  }) {
    if (releaseDecision.readiness == ReleaseReadiness.transitionReady) {
      // Softening after Release: speak one Enough close before audio.
      // Do not skip the spoken night-close into immediate audio.
      if (priorPhase == ConversationPhase.release) {
        return const ConversationDecision(
          phase: ConversationPhase.continuity,
          shouldSpeak: true,
        );
      }
      return const ConversationDecision(
        phase: ConversationPhase.audio,
        shouldSpeak: false,
      );
    }

    final resisting = stance == TurnResponseStance.holdingAgainstEase ||
        stance == TurnResponseStance.continuedLoad ||
        hasLoad;

    if (resisting) {
      // Resistance after Release → Receipt/Permission, never Release.
      if (releaseDecision.readiness == ReleaseReadiness.hold) {
        return const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        );
      }
      return const ConversationDecision(
        phase: ConversationPhase.permission,
        shouldSpeak: true,
      );
    }

    if (stance == TurnResponseStance.softeningAcceptance) {
      return const ConversationDecision(
        phase: ConversationPhase.continuity,
        shouldSpeak: true,
      );
    }

    // Unclear after Release: fail closed on acceptance/audio, but never
    // re-issue Release merely because load was absent.
    if (releaseDecision.readiness == ReleaseReadiness.hold) {
      return const ConversationDecision(
        phase: ConversationPhase.validation,
        shouldSpeak: true,
      );
    }
    if (releaseDecision.readiness == ReleaseReadiness.regulated) {
      return const ConversationDecision(
        phase: ConversationPhase.permission,
        shouldSpeak: true,
      );
    }
    return const ConversationDecision(
      phase: ConversationPhase.continuity,
      shouldSpeak: true,
    );
  }

  ConversationDecision _decideBase({
    required ReleaseDecision releaseDecision,
    required ConversationPhase? priorPhase,
    required NightSession? session,
    required bool hasLoad,
  }) {
    switch (releaseDecision.readiness) {
      case ReleaseReadiness.hold:
        if (_shouldSpeakNamingOnce(
          session: session,
          priorPhase: priorPhase,
          hasLoad: hasLoad,
        )) {
          return const ConversationDecision(
            phase: ConversationPhase.naming,
            shouldSpeak: true,
          );
        }
        return const ConversationDecision(
          phase: ConversationPhase.validation,
          shouldSpeak: true,
        );

      case ReleaseReadiness.regulated:
        return const ConversationDecision(
          phase: ConversationPhase.permission,
          shouldSpeak: true,
        );

      case ReleaseReadiness.settling:
        // One Release issuance per climb. A second Enough after Enough must
        // not re-stamp the close — speak once, then stay quiet.
        if (priorPhase == ConversationPhase.continuity) {
          return const ConversationDecision(
            phase: ConversationPhase.continuity,
            shouldSpeak: false,
          );
        }
        return const ConversationDecision(
          phase: ConversationPhase.release,
          shouldSpeak: true,
        );

      case ReleaseReadiness.receptive:
        // Receptive is Enough / continuity — not a second Release WHAT.
        // If Enough already spoke, do not emit another identical close.
        if (priorPhase == ConversationPhase.continuity) {
          return const ConversationDecision(
            phase: ConversationPhase.continuity,
            shouldSpeak: false,
          );
        }
        return const ConversationDecision(
          phase: ConversationPhase.continuity,
          shouldSpeak: true,
        );

      case ReleaseReadiness.transitionReady:
        return const ConversationDecision(
          phase: ConversationPhase.audio,
          shouldSpeak: false,
        );
    }
  }

  /// Exactly one Naming after Receipt while still holding load.
  bool _shouldSpeakNamingOnce({
    required NightSession? session,
    required ConversationPhase? priorPhase,
    required bool hasLoad,
  }) {
    if (!hasLoad) return false;
    if (priorPhase != ConversationPhase.validation) return false;
    if (session == null) return false;
    for (final turn in session.turns) {
      if (turn.phase == ConversationPhase.naming) return false;
    }
    return true;
  }

  /// After terminal audio, a meaningful user turn reopens conversation.
  bool _isPostAudioReEngagement({
    required String? message,
    required NightSession? session,
  }) {
    if (session == null || session.turns.isEmpty) return false;
    if (session.turns.last.phase != ConversationPhase.audio) return false;
    if (message == null) return false;
    return postAudioReEngagement.isMeaningful(message);
  }

  bool _isNeutralEntry({
    required ReleaseDecision releaseDecision,
    required String? message,
    required NightSession? session,
    required ValidatedUnderstanding? understanding,
  }) {
    if (releaseDecision.readiness != ReleaseReadiness.hold) {
      return false;
    }
    if (session == null || session.turns.isNotEmpty) {
      return false;
    }
    if (message == null || !neutralEntryDetector.isNeutralGreeting(message)) {
      return false;
    }
    if (_hasLoadEvidence(understanding)) {
      return false;
    }
    return true;
  }

  bool _hasLoadEvidence(ValidatedUnderstanding? understanding) {
    if (understanding == null) return false;
    if (understanding.mentalPatterns.isNotEmpty ||
        understanding.emotionalPatterns.isNotEmpty) {
      return true;
    }
    final hyp = understanding.thinkingFunctionHypothesis;
    return hyp != null && hyp.confidence >= 0.55;
  }

  /// Conversation feedback: objecting to Nocta's speech or correcting a
  /// misread. Private helper — not a new engine.
  bool _isConversationProtestOrCorrection(String? message) {
    if (message == null) return false;
    var n = message.trim().toLowerCase();
    if (n.isEmpty) return false;
    n = n
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ı', 'i')
        .replaceAll('ç', 'c');

    // Protest — objecting to Nocta's style / repetition.
    if (n.contains('robot gibi')) return true;
    if (n.contains('beni anlam')) return true;
    if (n.contains('anlamiyosun')) return true;
    if (n.contains('anlamiyorsun')) return true;
    if (n.contains('surekli ayni')) return true;
    if (n.contains('ayni seyi soyl')) return true;
    if (n.contains('ayni seyi soyluyor')) return true;
    if (n.contains('bunu zaten soyled')) return true;
    if (n.contains('bu soruyu zaten')) return true;
    if (n.contains('tekrar ediyorsun')) return true;
    if (n.contains('tekrarliyorsun')) return true;
    if (n.contains('like a robot')) return true;
    if (n.contains('talking like a robot')) return true;
    if (RegExp(r"you don'?t understand( me)?").hasMatch(n)) return true;
    if (n.contains('same thing over')) return true;
    if (n.contains('keep saying the same')) return true;
    if (n.contains('you already said')) return true;
    if (n.contains('you already asked')) return true;
    if (n.contains('stop repeating')) return true;

    // Correction — rejecting Nocta's interpretation / attributed feeling.
    if (n.contains('yanlis anlad')) return true;
    if (n.contains('yanlis anladin')) return true;
    if (n.contains('yanlis anliyorsun')) return true;
    if (n.contains('oyle demedim')) return true;
    if (n.contains('demedim')) {
      if (n.contains('oyle') || n.contains('oyle') || n.contains('ben')) {
        return true;
      }
    }
    if (n.contains('uzgun degilim')) return true;
    if (n.contains('uzgun değilim')) return true;
    if (n.contains("i'm not sad")) return true;
    if (n.contains('i am not sad')) return true;
    if (n.contains("that's not what i")) return true;
    if (n.contains('thats not what i')) return true;
    if (n.contains('you misunderstood')) return true;
    if (n.contains('wrong about')) return true;
    return false;
  }
}
