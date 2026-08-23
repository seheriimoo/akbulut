import 'conversation_dna.dart';
import 'conversation_expression_mode.dart';
import 'conversation_phase.dart';
import 'conversation_utterance.dart';
import 'evidence_bound_reframe_contract.dart';
import 'evidence_ledger.dart';
import 'grounded_progression.dart';
import 'light_conversation_detector.dart';
import 'listen_only_preference.dart';
import 'session_locale.dart';
import 'surface_text_fuzzy.dart';
import 'permission_realization_contract.dart';
import 'receipt_realization_contract.dart';
import 'surface_mirror_contract.dart';

/// UtteranceGuard
///
/// Enforces Conversation Output Contract and Conversation DNA on emission.
///
/// Expression-plane only. Does not decide release, protocol, or exit.
/// Does not generate language. Does not write memory.
/// Admit/reject only — never rewrites or repairs wording.
///
/// Naming admission follows Guard Naming Contract V2: canonical stems plus
/// semantic quiet-recognition patterns. Fail closed on ambiguity.
///
/// Receipt admission follows Guard Receipt Contract V1.6: classic soft stems
/// plus texture-first / soft-functional patterns from the shared
/// [ReceiptRealizationContract].
/// Fail closed on invention, Naming-stem drift, and compound second moves.
/// Guard stays mechanism-agnostic — no Exactly-It psychology scoring.
///
/// Permission admission follows Guard Permission Contract V1.0 via shared
/// [PermissionRealizationContract]: classic obligation-ease stems, leave-be
/// family, and natural non-resolution variants. Fail closed on Release
/// enactment / advice / invented problems / other-WHAT drift.
///
/// Release admission follows Guard Release Contract V1.1: classic putting-down
/// stems, bounded set-down pattern, and natural set-down variants. Fail closed
/// on sleep commands / other-WHAT drift.
class UtteranceGuard {
  const UtteranceGuard();

  /// Guard Naming Contract version bound in this guard.
  static const String namingContractVersion = '2.0';

  /// Guard Receipt Contract version bound in this guard.
  static const String receiptContractVersion = '1.6';

  /// Guard Permission Contract version bound in this guard.
  /// Aligned with [PermissionRealizationContract.version].
  static const String permissionContractVersion =
      PermissionRealizationContract.version;

  /// Guard Release Contract version bound in this guard.
  static const String releaseContractVersion = '1.1';

  static const List<ConversationPhase> _speakablePhases = [
    ConversationPhase.validation,
    ConversationPhase.naming,
    ConversationPhase.permission,
    ConversationPhase.release,
    ConversationPhase.continuity,
    ConversationPhase.neutralEntry,
  ];

  /// Guard Neutral Entry Contract version bound in this guard.
  static const String neutralEntryContractVersion = '1.0';

  /// Soft upper bound for DNA principle 2 (fewest helpful words).
  /// Golden Conversations V2 short-line Receipt/Naming may use more lines
  /// without becoming an essay.
  static const int _maxHelpfulWords = 65;

  /// Returns [utterance] if it may leave the Conversation layer; otherwise
  /// `null` (no conversational language).
  ///
  /// [dna] is the bound Conversation DNA from the invocation package.
  /// Defaults to [ConversationDNA.instance], the sole frozen binding today.
  ConversationUtterance? allow({
    required ConversationUtterance utterance,
    required ConversationPhase what,
    ConversationDNA dna = ConversationDNA.instance,
    String? userUtterance,
    String? mirrorGroundingUtterance,
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
    EvidenceLedger? reframeEvidenceLedger,
    bool listenOnlyActive = false,
  }) {
    final text = utterance.text.trim();

    // Output Contract: no conversational language is absence, not empty text.
    if (text.isEmpty) {
      return null;
    }

    // Soft line-breaks from the model are formatting, not multi-message
    // bundles. Collapse all whitespace into one speech plane, then enforce
    // sentence-count limits by WHAT.
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return null;
    }

    // Output Contract: one speech artifact (no multi-message bundles).
    // Receipt/Naming may use two short sentences for soft perspective.
    if (!_singleSpeechOutcome(normalized, what, expressionMode: expressionMode)) {
      return null;
    }

    // One reply, one language (EN or TR) — mixed replies fail closed.
    if (_isMixedLanguage(normalized)) {
      return null;
    }

    // Mirror the person's language when it is clearly EN or TR.
    // Mixed / unknown user language: do not invent a lock.
    if (!_matchesUserLanguage(
      normalized,
      userUtterance,
      mirrorGroundingUtterance: mirrorGroundingUtterance,
    )) {
      return null;
    }

    if (listenOnlyActive && _violatesListenOnlyContract(
      normalized,
      expressionMode: expressionMode,
      what: what,
    )) {
      return null;
    }

    if (_inventedNarrowLoadLexeme(
      normalized,
      userUtterance: userUtterance,
      mirrorGroundingUtterance: mirrorGroundingUtterance,
    )) {
      return null;
    }

    // Stay inside the decided WHAT (DNA principle 9 / anti-rule rewrite).
    if (!_faithfulToWhat(
      normalized,
      what,
      expressionMode: expressionMode,
      userUtterance: userUtterance,
      mirrorGroundingUtterance: mirrorGroundingUtterance,
    )) {
      return null;
    }

    // Observe purity: reject early reframe stems on first Receipt.
    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.observePurity &&
        _observePurityReframeDrift(normalized)) {
      return null;
    }

    // Repair: one question max.
    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.repair &&
        _tooManyQuestions(normalized)) {
      return null;
    }

    // Narrow: exactly one fork question.
    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.narrow &&
        (_tooManyQuestions(normalized) || !normalized.contains('?'))) {
      return null;
    }

    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.narrow &&
        !GroundedNarrowContract.admitsNarrowText(
          noctaText: normalized,
          userUtterance: userUtterance,
          groundingBlob: mirrorGroundingUtterance,
        )) {
      return null;
    }

    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.groundedHold &&
        !GroundedHoldContract.admits(
          noctaText: normalized,
          userUtterance: userUtterance,
          groundingBlob: mirrorGroundingUtterance,
        )) {
      return null;
    }

    // Light chat: one question max.
    if (what == ConversationPhase.neutralEntry &&
        expressionMode == ConversationExpressionMode.lightChat &&
        _tooManyQuestions(normalized)) {
      return null;
    }

    // Reframe: no question; no Belki/Sanki fatigue stems.
    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.reframe &&
        (normalized.contains('?') ||
            _genericReframeFatigue(normalized) ||
            _reframeBelkiSankiDrift(normalized))) {
      return null;
    }

    // B3 — semantic evidence ceiling for reframe (fail closed without ledger).
    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.reframe) {
      if (reframeEvidenceLedger == null) return null;
      if (!EvidenceBoundReframeContract.admits(
        reframeText: normalized,
        ledger: reframeEvidenceLedger,
      )) {
        return null;
      }
    }

    // Integrate: no question; no empathy filler; mind-loop bridge required.
    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.integrate &&
        (normalized.contains('?') ||
            _integrateForbiddenDrift(normalized) ||
            !_matchesIntegrateContract(_normalizeForMatch(normalized)))) {
      return null;
    }

    // Closure: no question; personalized tonight boundary required.
    if (what == ConversationPhase.validation &&
        expressionMode == ConversationExpressionMode.closure &&
        (normalized.contains('?') ||
            _closureForbiddenDrift(normalized) ||
            !_matchesClosureContract(_normalizeForMatch(normalized)))) {
      return null;
    }

    // Receipt: do not admit invented tomorrow / racing when the person
    // did not name those objects this turn.
    if (what == ConversationPhase.validation &&
        expressionMode != ConversationExpressionMode.repair &&
        expressionMode != ConversationExpressionMode.integrate &&
        expressionMode != ConversationExpressionMode.closure &&
        _receiptInventedAgenda(normalized, userUtterance)) {
      return null;
    }

    // Bound Conversation DNA: every anti-rule and principle must hold.
    if (!_satisfiesDna(
      text: normalized,
      what: what,
      dna: dna,
      expressionMode: expressionMode,
      userUtterance: userUtterance,
      mirrorGroundingUtterance: mirrorGroundingUtterance,
    )) {
      return null;
    }

    // Emit the validated single utterance (normalized trim). No rewrite.
    return ConversationUtterance(text: normalized);
  }

  bool _singleSpeechOutcome(
    String text,
    ConversationPhase what, {
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
  }) {
    if (text.contains('\n')) {
      return false;
    }
    final sentenceEnds = RegExp(r'[.!?]+').allMatches(text).length;
    final int maxEnds;
    if (what == ConversationPhase.validation ||
        what == ConversationPhase.naming) {
      if (expressionMode == ConversationExpressionMode.observePurity ||
          expressionMode == ConversationExpressionMode.postReframeListen) {
        maxEnds = 1;
      } else if (expressionMode == ConversationExpressionMode.narrow) {
        maxEnds = 2;
      } else if (expressionMode == ConversationExpressionMode.reframe) {
        maxEnds = 2;
      } else if (expressionMode == ConversationExpressionMode.integrate) {
        maxEnds = 2;
      } else if (expressionMode == ConversationExpressionMode.closure) {
        maxEnds = 3;
      } else {
        maxEnds = 3;
      }
    } else if (what == ConversationPhase.continuity ||
        what == ConversationPhase.release) {
      maxEnds = 3;
    } else if (what == ConversationPhase.permission) {
      maxEnds = 2;
    } else if (what == ConversationPhase.neutralEntry &&
        expressionMode == ConversationExpressionMode.lightChat) {
      maxEnds = 2;
    } else {
      maxEnds = 1;
    }
    return sentenceEnds <= maxEnds;
  }

  /// Contract-level WHAT faithfulness.
  ///
  /// Allows natural wording variation inside the sealed WHAT.
  /// Rejects non-speech emission and semantic drift into another agenda/phase.
  bool _faithfulToWhat(
    String text,
    ConversationPhase what, {
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
    String? userUtterance,
    String? mirrorGroundingUtterance,
  }) {
    switch (what) {
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        return false;
      case ConversationPhase.validation:
      case ConversationPhase.naming:
      case ConversationPhase.permission:
      case ConversationPhase.release:
      case ConversationPhase.continuity:
      case ConversationPhase.neutralEntry:
        break;
    }

    final lower = _normalizeForMatch(text);

    if (!_matchesPhase(
      lower,
      what,
      expressionMode: expressionMode,
      userUtterance: userUtterance,
      mirrorGroundingUtterance: mirrorGroundingUtterance,
    )) {
      return false;
    }

    for (final other in _speakablePhases) {
      if (other == what) continue;
      // Integrate/Closure use personalized put-down language by design;
      // do not cross-reject against Permission/Release phase signatures.
      if (what == ConversationPhase.validation &&
          (expressionMode == ConversationExpressionMode.integrate ||
              expressionMode == ConversationExpressionMode.closure)) {
        continue;
      }
      // Later-phase lines often contain incidental soft frames (“perhaps…”,
      // “it’s…”) + textures (“quiet”, “carry”) that false-match Receipt
      // texture-first. Only classic Receipt stems collide.
      // Naming is excluded here — soft Receipt openers (“it sounds…”) are
      // legal Naming lead-ins (handled below).
      if (other == ConversationPhase.validation &&
          (what == ConversationPhase.continuity ||
              what == ConversationPhase.release ||
              what == ConversationPhase.permission)) {
        if (ReceiptRealizationContract.hasClassicStem(lower)) {
          return false;
        }
        continue;
      }
      // Enough must not reuse Release night-hold. Hard put-down AND
      // night-can-hold / let-the-night-hold are Release drift under continuity.
      if (what == ConversationPhase.continuity &&
          other == ConversationPhase.release) {
        if (_containsAny(lower, const [
          'set this down',
          'set it down',
          'let it rest',
          'let this rest',
          'let go for now',
          'leave it here',
          'leave this here',
          'leave some of',
          'night can hold',
          'the night can hold',
          'let the night hold',
          'gece tutabilir',
          'geceye bırak',
          'geceye birak',
        ])) {
          return false;
        }
        continue;
      }
      // Enough handoffs may say “take your time…” while settling into quiet;
      // that must not count as Neutral Entry drift.
      if (what == ConversationPhase.continuity &&
          other == ConversationPhase.neutralEntry) {
        if (_containsAny(lower, const [
          'preparing a',
          'preparing something',
          'leave you with',
          'leaving you with',
          'quiet for you',
          'rest for you',
          'a little rest',
          'a little quiet',
          'biraz sessizlik',
          'biraz dinlenme',
          'dinlenmeyle bırakıyorum',
          'sessizlikle bırakıyorum',
        ])) {
          continue;
        }
      }
      // Naming may open with soft Receipt frames (“it sounds…”) while naming
      // the load with a Guard Naming stem — do not cross-reject on Receipt.
      if (what == ConversationPhase.naming &&
          other == ConversationPhase.validation) {
        continue;
      }
      // Receipt may mention overthinking / won't-stop texture without being
      // a Naming speech-act. Only English Naming speech-act stems collide;
      // TR night-texture (“zihninde / dönüp duruyor”) is legal Receipt.
      if (what == ConversationPhase.validation &&
          other == ConversationPhase.naming) {
        if (_containsAny(lower, const [
          'holding on',
          'weighing',
          'still there',
          'lingering',
          'on your mind',
        ])) {
          return false;
        }
        continue;
      }
      // Release put-down may include “don’t need to carry” idiom; that must
      // not count as Permission obligation-ease under cross-phase.
      if (what == ConversationPhase.release &&
          other == ConversationPhase.permission) {
        if (_containsAny(lower, const [
          'night can hold',
          'the night can hold',
          'set this down',
          'set it down',
          'set some of',
          'leave it here',
          'leave some of',
          'let go for now',
          'let go of that',
          'let go of this',
          'let go tonight',
        ])) {
          continue;
        }
      }
      if (_matchesPhase(lower, other)) {
        return false;
      }
    }

    return true;
  }

  /// Normalize typography so semantic Naming frames match reliably.
  String _normalizeForMatch(String text) {
    return text
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('ʼ', "'")
        .replaceAll('´', "'")
        .replaceAll('`', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('…', '...');
  }

  /// Semantic signature of a speakable protocol phase.
  bool _matchesPhase(
    String lower,
    ConversationPhase phase, {
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
    String? userUtterance,
    String? mirrorGroundingUtterance,
  }) {
    switch (phase) {
      case ConversationPhase.validation:
        if (expressionMode == ConversationExpressionMode.repair) {
          return _matchesRepairContract(lower);
        }
        if (expressionMode == ConversationExpressionMode.observePurity) {
          return _matchesObservePurityContract(
            lower,
            userUtterance: userUtterance,
            mirrorGroundingUtterance: mirrorGroundingUtterance,
          );
        }
        if (expressionMode == ConversationExpressionMode.narrow) {
          return _matchesNarrowContract(lower);
        }
        if (expressionMode == ConversationExpressionMode.reframe) {
          return _matchesReframeContract(lower);
        }
        if (expressionMode == ConversationExpressionMode.integrate) {
          return _matchesIntegrateContract(lower);
        }
        if (expressionMode == ConversationExpressionMode.closure) {
          return _matchesClosureContract(lower);
        }
        if (expressionMode == ConversationExpressionMode.postReframeListen) {
          return _matchesPostReframeListenContract(lower);
        }
        if (expressionMode == ConversationExpressionMode.groundedHold) {
          return GroundedHoldContract.admits(
            noctaText: lower,
            userUtterance: userUtterance,
            groundingBlob: mirrorGroundingUtterance,
          );
        }
        return _matchesReceiptContract(
          lower,
          userUtterance: userUtterance,
          mirrorGroundingUtterance: mirrorGroundingUtterance,
        );
      case ConversationPhase.naming:
        return _matchesNamingContract(lower);
      case ConversationPhase.permission:
        return _matchesPermissionContract(lower);
      case ConversationPhase.release:
        return _matchesReleaseContract(lower);
      case ConversationPhase.continuity:
        // Enough-only close cues. Do not share Release put-down stems
        // (night can hold / can rest here) — cross-phase reject otherwise.
        // Word-boundary end so “a little quiet” ≠ “a little quieter”.
        return _containsAnyBounded(lower, const [
          'nothing more',
          'no more is needed',
          'nothing else needed',
          'nothing else needs',
          'nothing else',
          "that's enough",
          'thats enough',
          'enough for now',
          "that's all for tonight",
          'thats all for tonight',
          'all for tonight',
          'words can rest',
          'the words can rest',
          'this can end here',
          'we can stop here',
          'leave it at that',
          'no more needed',
          // Soft rest-audio handoff (Golden Conversations V2 TYPE)
          'preparing a',
          'preparing something',
          'preparing a session',
          'preparing a little',
          'leave you with',
          'leaving you with',
          'quiet for you',
          'rest for you',
          'a little rest',
          'a little quiet',
          // Turkish Enough / handoff
          'biraz sessizlik hazırlıyorum',
          'biraz dinlenme hazırlıyorum',
          'bir oturum hazırlıyorum',
          'dinlenmeyle bırakıyorum',
          'sessizlikle bırakıyorum',
          'biraz dinlenmeyle',
          'biraz sessizlikle',
          'şimdi seni dinlenmeyle bırakıyorum',
          'kelimeler dinlenebilir',
          'bu kadar yeter',
          'daha fazlası gerekmiyor',
        ]);
      case ConversationPhase.neutralEntry:
        if (expressionMode == ConversationExpressionMode.lightChat) {
          return _matchesLightChatContract(
            lower,
            userUtterance: userUtterance,
            mirrorGroundingUtterance: mirrorGroundingUtterance,
          );
        }
        return _matchesNeutralEntryContract(lower);
      case ConversationPhase.audio:
      case ConversationPhase.silence:
        return false;
    }
  }

  /// Guard Neutral Entry Contract V1.
  ///
  /// Admits brief greeting acknowledgment only.
  /// Fail closed on invented emotion/presence, questions, and other-WHAT drift.
  bool _matchesNeutralEntryContract(String lower) {
    if (_neutralEntryUnsafe(lower)) {
      return false;
    }

    // Word-boundary for short stems so "this"/"thinking" do not false-match.
    if (RegExp(r'\bhi\b').hasMatch(lower) ||
        RegExp(r'\bhey\b').hasMatch(lower)) {
      return true;
    }

    return _containsAny(lower, _neutralEntryAckCues);
  }

  static const List<String> _neutralEntryAckCues = [
    'hello',
    'good evening',
    'good night',
    'good morning',
    "whenever you're ready",
    'whenever you are ready',
    "when you're ready",
    'when you are ready',
    'take your time',
    // Turkish Neutral Entry parity (greeting ack only — not a safety loosen).
    'merhaba',
    'hazır olduğunda',
    'hazir oldugunda',
  ];

  bool _neutralEntryUnsafe(String lower) {
    return _containsAny(lower, const [
      '?',
      'how are you',
      'how are you feeling',
      'tell me',
      'what is keeping',
      'what\'s keeping',
      'stillness',
      'being present',
      'just being present',
      "you're present",
      'you are present',
      'your presence',
      'mindful',
      'mindfulness',
      'inner peace',
      'heavy',
      'heaviness',
      'dread',
      'lonely',
      'loneliness',
      'ache',
      'anxious',
      'anxiety',
      'overwhelm',
      'insomnia',
      'can\'t sleep',
      'cannot sleep',
      'go to sleep',
      'have you tried',
      'you should',
      'try this',
      'that sounds',
      'it sounds',
      'makes sense',
      'do not have to',
      "don't have to",
      'let it rest',
      'let this rest',
      'set this down',
      'set it down',
      'holding on',
      'nothing more',
      "that's enough",
    ]);
  }

  bool _observePurityReframeDrift(String text) {
    final lower = _normalizeForMatch(text);
    return _containsAny(lower, const [
      'belki',
      'sanki',
      'aslında',
      'aslinda',
      'perhaps',
      'maybe',
      'almost as if',
      'almost like',
      'part of your mind',
    ]);
  }

  bool _genericReframeFatigue(String lower) {
    return _containsAny(lower, const [
      'belki bunu birakmakta',
      'belki bunu bırakmakta',
      'sanki bu sana agir',
      'sanki bu sana ağır',
      'belki zihnin',
      'sanki zihnin',
      'maybe you are struggling',
      'maybe your mind',
      'almost like this is heavy',
      'belki bunu birak',
      'belki bunu bırak',
    ]);
  }

  bool _reframeBelkiSankiDrift(String lower) {
    return _containsAny(lower, const ['belki', 'sanki', 'perhaps', 'maybe']);
  }

  bool _matchesObservePurityContract(
    String lower, {
    String? userUtterance,
    String? mirrorGroundingUtterance,
  }) {
    if (_observePurityReframeDrift(lower)) return false;
    if (lower.contains('?')) return false;
    if (_receiptOverInference(lower)) return false;
    if (_matchesReceiptContract(
      lower,
      userUtterance: userUtterance,
      mirrorGroundingUtterance: mirrorGroundingUtterance,
    )) {
      return true;
    }
    return _containsAny(lower, const [
          'kafanda',
          'aklinda',
          'aklında',
          'gece',
          'yarin',
          'yarın',
          'hâlâ',
          'hala',
          'donup',
          'dönüp',
          'duruyor',
          'orada',
          'yakinda',
          'yakında',
          'still',
          'head',
          'tonight',
          'tomorrow',
          'there',
          'close',
        ]) &&
        lower.trim().length >= 8;
  }

  bool _matchesNarrowContract(String lower) {
    if (_narrowGenericTherapy(lower)) return false;
    if (!lower.contains('?')) return false;
    if (_narrowRefinementQuestion(lower)) return true;
    return lower.contains('yoksa') ||
        RegExp(r'\bor\b').hasMatch(lower) ||
        lower.contains(' mi ') ||
        lower.contains(' mı ') ||
        lower.contains(' mu ') ||
        lower.contains(' mü ');
  }

  bool _narrowRefinementQuestion(String lower) {
    return _containsAny(lower, const [
      'eksik kalan',
      'tam oturmayan',
      'peki eksik',
      'dogru gibi. peki',
      'doğru gibi. peki',
      'dogru gibi, peki',
      'doğru gibi, peki',
    ]);
  }

  bool _narrowGenericTherapy(String lower) {
    return _containsAny(lower, const [
      'nasil hissettiriyor',
      'nasıl hissettiriyor',
      'biraz daha anlat',
      'ne dusunuyorsun',
      'ne düşünüyorsun',
      'how does that make you feel',
      'tell me more',
      'want to share',
      'what do you think',
    ]);
  }

  bool _matchesReframeContract(String lower) {
    if (lower.contains('?')) return false;
    if (_genericReframeFatigue(lower)) return false;
    if (_receiptOverInference(lower)) return false;
    return _containsAny(lower, const [
      'olabilir',
      'gibi',
      'sanirim',
      'sanırım',
      'galiba',
      'might',
      'could',
      'seems',
    ]);
  }

  bool _matchesPostReframeListenContract(String lower) {
    if (lower.contains('?')) return false;
    return _containsAny(lower, const [
      'tamam',
      'anladim',
      'anladım',
      'anliyorum',
      'anlıyorum',
      'evet',
      'orada',
      'okay',
      'got it',
      'i hear',
      'understood',
    ]);
  }

  bool _integrateForbiddenDrift(String text) {
    final lower = _normalizeForMatch(text);
    return _containsAny(lower, const [
      'anliyorum',
      'anlıyorum',
      'bu cok zor',
      'bu çok zor',
      'belki zihnin',
      'birakabilirsin',
      'bırakabilirsin',
    ]);
  }

  bool _closureForbiddenDrift(String text) {
    final lower = _asciiFoldTr(_normalizeForMatch(text));
    if (_containsAny(lower, const ['anliyorum'])) return true;
    if (lower.contains('bu gece bunu cozmek zorunda degilsin')) {
      return true;
    }
    return false;
  }

  bool _matchesIntegrateContract(String lower) {
    if (lower.contains('?')) return false;
    if (_integrateForbiddenDrift(lower)) return false;
    return _containsAny(lower, const [
      'zihnin',
      'zihin',
      'mind',
      'calisiyor',
      'çalışıyor',
      'trying',
      'guvence',
      'güvence',
      'risk gibi',
      'loop',
      'bu yuzden',
      'bu yüzden',
      'o zaman',
    ]);
  }

  bool _matchesClosureContract(String lower) {
    if (lower.contains('?')) return false;
    if (_closureForbiddenDrift(lower)) return false;
    final n = _asciiFoldTr(lower);
    final hasTonight = _containsAny(n, const [
      'bu gece',
      'tonight',
      'yarin',
      'tomorrow',
      'sabah',
    ]);
    final hasPutDown = _containsAny(n, const [
      'zorunda degilsin',
      "don't have to",
      'do not have to',
      'kesinlestiremez',
      'birak',
      'put down',
      'leave',
      'rest',
    ]);
    return hasTonight && hasPutDown;
  }

  String _asciiFoldTr(String s) {
    return s
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ı', 'i')
        .replaceAll('ç', 'c')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u');
  }

  bool _tooManyQuestions(String text) {
    return '?'.allMatches(text).length > 1;
  }

  /// Guard Repair Contract V1 (Slice 1).
  bool _matchesRepairContract(String lower) {
    if (_repairUnsafe(lower)) return false;
    return _containsAny(lower, const [
      'yanlis okudum',
      'yanlış okudum',
      'orayi yanlis',
      'orayı yanlış',
      'read that wrong',
      'read it wrong',
      'misread',
      'misunderstood',
      'haklisin',
      'haklısın',
      "you're right",
      'you are right',
      'kept saying',
      'same thing',
      'ayni yere',
      'aynı yere',
      'baska yerden',
      'başka yerden',
    ]);
  }

  bool _repairUnsafe(String lower) {
    return _containsAny(lower, const [
      'gerekmiyor',
      'zorunda degilsin',
      'zorunda değilsin',
      "don't have to",
      'do not have to',
      'let go',
      'let it rest',
      'let this rest',
      'bırak',
      'birak',
      'geceye bırak',
      'geceye birak',
      'bu kadar yeter',
      'nothing more',
    ]);
  }

  /// Guard Light Chat Contract V1 (Slice 1).
  bool _matchesLightChatContract(
    String lower, {
    String? userUtterance,
    String? mirrorGroundingUtterance,
  }) {
    if (_lightChatUnsafe(lower)) return false;
    if (userUtterance != null) {
      const light = LightConversationDetector();
      if (light.hasRealLoadMarkers(userUtterance)) return false;
    }
    if (_isPlayfulLightAck(lower) && userUtterance != null) {
      final corpus =
          '${mirrorGroundingUtterance ?? ''} $userUtterance'.trim();
      if (VentStackDetector.hasFrustrationMarkers(corpus) ||
          VentStackDetector.isMultiStressorStack(corpus)) {
        return false;
      }
      if (SessionVentMemory.isPseudoPositiveContinuation(userUtterance) &&
          (VentStackDetector.hasFrustrationMarkers(
                mirrorGroundingUtterance ?? '',
              ) ||
              VentStackDetector.isMultiStressorStack(
                mirrorGroundingUtterance ?? '',
              ))) {
        return false;
      }
    }
    return lower.trim().isNotEmpty;
  }

  bool _isPlayfulLightAck(String lower) {
    return _containsAny(lower, const [
      'guzel :)',
      'güzel :)',
      'guzel.',
      'güzel.',
      'oh, nice',
      'oh nice',
      'nice :)',
    ]);
  }

  bool _isPartialConfirmUserLine(String userUtterance) {
    final n = userUtterance.toLowerCase();
    return RegExp(
      r'\b(evet ama|dogru ama|doğru ama|biraz ama|kismi dogru|kısmı doğru|'
      r'tam degil|tam değil|sadece o)\b',
    ).hasMatch(n);
  }

  bool _matchesGroundedHoldContract(String lower) {
    if (lower.contains('?')) return false;
    if (_genericReframeFatigue(lower)) return false;
    if (_receiptOverInference(lower)) return false;
    return _containsAny(lower, const [
      'henuz',
      'henüz',
      'tam adini',
      'tam adını',
      'kaybetmedim',
      'uyanik tut',
      'uyanık tut',
      'burada kalabilir',
      'cozmek zorunda degilsin',
      'çözmek zorunda değilsin',
      'still keeping you awake',
      'do not have to name',
    ]);
  }

  bool _lightChatUnsafe(String lower) {
    return _containsAny(lower, const [
      'how are you feeling',
      'stillness',
      'being present',
      'mindful',
      'inner peace',
      'heavy',
      'heaviness',
      'dread',
      'lonely',
      'loneliness',
      'ache',
      'anxious',
      'anxiety',
      'overwhelm',
      'insomnia',
      "can't sleep",
      'cannot sleep',
      'go to sleep',
      'have you tried',
      'you should',
      'try this',
      'that sounds',
      'it sounds',
      'makes sense',
      'do not have to',
      "don't have to",
      'gerekmiyor',
      'dusunmene gerek',
      'düşünmene gerek',
      'let it rest',
      'let this rest',
      'set this down',
      'set it down',
      'holding on',
      'nothing more',
      "that's enough",
      'belki',
      'sanki',
      'zor geliyor',
      'ağır geliyor',
      'agir geliyor',
      'yük',
    ]);
  }

  bool _containsAny(String lower, List<String> markers) {
    for (final marker in markers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }

  /// Like [_containsAny], but the marker must end on a word boundary.
  /// Prevents “a little quiet” from matching inside “a little quieter”.
  bool _containsAnyBounded(String lower, List<String> markers) {
    for (final marker in markers) {
      final escaped = RegExp.escape(marker);
      if (RegExp('$escaped\\b').hasMatch(lower)) return true;
    }
    return false;
  }

  /// Fail closed on English+Turkish mixed inside one utterance.
  bool _isMixedLanguage(String text) {
    final lower = _normalizeForMatch(text);
    final hasTurkishScript = RegExp(r'[ğüşıöçâîû]').hasMatch(lower);
    final hasTurkishLexeme = _containsAny(lower, const [
      'zorunda',
      'bırak',
      'birak',
      'gece',
      'belki',
      'sanki',
      'zihin',
      'zihn',
      'şimdi',
      'simdi',
      'değil',
      'degil',
      'gibi',
      'yarın',
      'yarin',
      'dinlenme',
      'sessizlik',
      'hazırlıyorum',
      'hazirliyorum',
      'beklemek',
      'sadece',
      'istemiyorum',
      'endişe',
      'endise',
    ]) ||
        RegExp(r'\bzor\b').hasMatch(lower);
    final hasTurkish = hasTurkishScript || hasTurkishLexeme;
    final hasEnglish = RegExp(
      r"\b(you|your|the|tonight|don't|dont|need|perhaps|mind|leave|preparing|enough|softening|hear)\b",
    ).hasMatch(lower);
    return hasTurkish && hasEnglish;
  }

  /// Fail closed when the reply is clearly the other language than the user.
  /// Mixed or unknown user language does not lock.
  bool _matchesUserLanguage(
    String assistant,
    String? userUtterance, {
    String? mirrorGroundingUtterance,
  }) {
    if (SessionLocale.isEnglishShortAck(assistant) &&
        SessionLocale.prefersTurkish(userUtterance, mirrorGroundingUtterance) &&
        !SessionLocale.prefersEnglish(mirrorGroundingUtterance)) {
      return false;
    }

    var userLang = _nightLanguage(userUtterance);
    if (userLang == null || userLang == 'mixed') {
      userLang = _nightLanguage(mirrorGroundingUtterance);
    }
    if ((userLang == null || userLang == 'en') &&
        SessionLocale.prefersTurkish(userUtterance, mirrorGroundingUtterance)) {
      userLang = 'tr';
    }
    if (SessionLocale.prefersTurkish(userUtterance, mirrorGroundingUtterance) &&
        SessionLocale.isEnglishShortAck(assistant)) {
      return false;
    }
    if (userLang == null || userLang == 'mixed') {
      if (SessionLocale.prefersTurkish(userUtterance, mirrorGroundingUtterance) &&
          SessionLocale.isEnglishShortAck(assistant)) {
        return false;
      }
      return true;
    }
    if (userLang == 'tr' && SessionLocale.isEnglishShortAck(assistant)) {
      return false;
    }
    final replyLang = _nightLanguage(assistant);
    if (replyLang == 'en' &&
        SessionLocale.prefersTurkish(userUtterance, mirrorGroundingUtterance) &&
        !SessionLocale.prefersEnglish(mirrorGroundingUtterance)) {
      return false;
    }
    if (replyLang == null || replyLang == 'mixed') {
      if (userLang == 'tr' &&
          RegExp(r'\b(the|you|your|okay|sure|got it|alright|hear)\b')
              .hasMatch(assistant.toLowerCase())) {
        return false;
      }
      return true;
    }
    return replyLang == userLang;
  }

  bool _violatesListenOnlyContract(
    String assistant, {
    required ConversationExpressionMode expressionMode,
    required ConversationPhase what,
  }) {
    if (what != ConversationPhase.validation) return false;
    switch (expressionMode) {
      case ConversationExpressionMode.narrow:
      case ConversationExpressionMode.reframe:
      case ConversationExpressionMode.integrate:
        return true;
      case ConversationExpressionMode.observePurity:
      case ConversationExpressionMode.standard:
      case ConversationExpressionMode.lightChat:
      case ConversationExpressionMode.postReframeListen:
      case ConversationExpressionMode.closure:
      case ConversationExpressionMode.repair:
      case ConversationExpressionMode.groundedHold:
        return ListenOnlyPreference.violatesListenOnly(assistant);
    }
  }

  bool _isEnglishShortAck(String text) => SessionLocale.isEnglishShortAck(text);

  /// Fail closed when assistant names load objects absent from user corpus.
  bool _inventedNarrowLoadLexeme(
    String assistant, {
    String? userUtterance,
    String? mirrorGroundingUtterance,
  }) {
    final corpus =
        '${userUtterance ?? ''} ${mirrorGroundingUtterance ?? ''}'.toLowerCase();
    final asst = assistant.toLowerCase();
    if (RegExp(r'\bbaskı\b').hasMatch(asst) &&
        !RegExp(r'\bbaskı\b').hasMatch(corpus)) {
      return true;
    }
    if (RegExp(r'\byük\b').hasMatch(asst) &&
        !corpus.contains('yük') &&
        !corpus.contains('ağırlık')) {
      return true;
    }
    return false;
  }

  /// Receipt-only: invented tomorrow / racing / swirl when this turn
  /// did not name those objects.
  bool _receiptInventedAgenda(String assistant, String? userUtterance) {
    if (userUtterance == null) return false;
    final user = userUtterance.toLowerCase();
    final asst = assistant.toLowerCase();
    final userHasTomorrow = user.contains('tomorrow') ||
        RegExp(r'\byarın\b').hasMatch(user) ||
        RegExp(r'\byarin\b').hasMatch(user);
    final asstHasTomorrow = asst.contains('tomorrow') ||
        RegExp(r'\byarın\b').hasMatch(asst) ||
        RegExp(r'\byarin\b').hasMatch(asst) ||
        asst.contains("what's to come") ||
        asst.contains('whats to come') ||
        asst.contains('future moment') ||
        asst.contains('future scene');
    if (!userHasTomorrow && asstHasTomorrow) {
      return true;
    }
    final userHasMeeting = user.contains('meeting') ||
        user.contains('toplantı') ||
        user.contains('toplantida');
    final asstHasMeeting = asst.contains('meeting') ||
        asst.contains('toplantı') ||
        asst.contains('toplantida');
    if (!userHasMeeting && asstHasMeeting) {
      return true;
    }
    final userHasList = user.contains('list') ||
        user.contains('to-do') ||
        user.contains('todo') ||
        user.contains('yapılacak') ||
        user.contains('yapilacak');
    final asstHasList = asst.contains('to-do') ||
        asst.contains('todo list') ||
        asst.contains('the list');
    if (!userHasList && asstHasList) {
      return true;
    }
    final userHasMotion = user.contains('racing') ||
        user.contains('swirl') ||
        user.contains('spiral') ||
        user.contains('loop') ||
        user.contains('thinking') ||
        user.contains('düşün') ||
        user.contains('dusun') ||
        user.contains('kafa') ||
        user.contains('zihn') ||
        user.contains('durmuyor') ||
        user.contains('overthink') ||
        user.contains('mind');
    final asstHasRacing = asst.contains('racing') ||
        asst.contains('swirling') ||
        asst.contains('spinning thoughts');
    if (!userHasMotion && asstHasRacing) {
      return true;
    }
    return false;
  }

  String? _nightLanguage(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final lower = _normalizeForMatch(text);
    final hasTurkishScript = RegExp(r'[ğüşıöçâîû]').hasMatch(lower);
    final hasTurkishLexeme = _containsAny(lower, const [
      'zorunda',
      'bırak',
      'birak',
      'gece',
      'belki',
      'sanki',
      'zihin',
      'zihn',
      'şimdi',
      'simdi',
      'değil',
      'degil',
      'gibi',
      'yarın',
      'yarin',
      'dinlenme',
      'sessizlik',
      'hazırlıyorum',
      'hazirliyorum',
      'uyuyamiyorum',
      'uyuyamıyorum',
      'konusmak',
      'konuşmak',
      'bilmiyorum',
      'kafam',
      'aklim',
      'aklım',
      'ozledim',
      'özledim',
      'durmuyor',
      'kafayi',
      'kafayı',
      'dusun',
      'düşün',
      'yalniz',
      'yalnız',
      'sakinim',
      'rahatlad',
      'rahatladim',
      'rahatladım',
    ]);
    final hasTurkish = hasTurkishScript || hasTurkishLexeme;
    final hasEnglish = RegExp(
      r"\b(i|you|your|the|tonight|don't|dont|need|perhaps|mind|leave|"
      r"preparing|thinking|can't|cannot|about|tomorrow|feel|feeling|"
      r"enough|softening|hear|this|down|hold|thoughts|feels|already|"
      r"swirling|racing|miss|him|idk)\b",
    ).hasMatch(lower);
    if (hasTurkish && hasEnglish) return 'mixed';
    if (hasTurkish) return 'tr';
    if (hasEnglish) return 'en';
    return null;
  }

  /// Guard Receipt Contract V1.6.
  ///
  /// Admits felt receipt / First Stop Moment wording via the shared
  /// [ReceiptRealizationContract]: classic stems or texture-first /
  /// soft-functional frame+texture pairs, excluding Naming-stem drift and
  /// compound second moves. Fail closed on invented psychology / stillness /
  /// presence / hard diagnosis. Mechanism-agnostic — no psychological scoring.
  bool _matchesReceiptContract(
    String lower, {
    String? userUtterance,
    String? mirrorGroundingUtterance,
  }) {
    if (_receiptOverInference(lower)) {
      return false;
    }

    // Contract-level Receipt drift bans apply before classic or texture-first.
    if (ReceiptRealizationContract.hasForbiddenNamingStem(lower)) {
      return false;
    }
    if (ReceiptRealizationContract.hasCompoundSecondMove(lower)) {
      return false;
    }

    // Classic soft stems (preserved — including FaithfulTestVendor paths).
    if (ReceiptRealizationContract.hasClassicStem(lower)) {
      return true;
    }

    if (ReceiptRealizationContract.matchesTextureFirst(lower)) {
      return true;
    }

    // B2.2 — source-grounded surface mirror (no night-language crutch required).
    if (userUtterance != null &&
        userUtterance.trim().isNotEmpty &&
        SurfaceMirrorContract.matches(
          lower,
          userUtterance,
          groundingUtterance: mirrorGroundingUtterance,
        )) {
      return true;
    }

    // B2.2 — brief conversational landing when mirror abstains.
    if (ConversationalLandingContract.matches(lower)) {
      return true;
    }

    return false;
  }

  /// Fail-closed Receipt exclusions: invented stillness / presence / psychology.
  bool _receiptOverInference(String lower) {
    return _containsAny(lower, const [
      'stillness',
      'being present',
      'just being present',
      "you're present",
      'youre present',
      'you are present',
      'just being here',
      'your presence',
      'mindful',
      'mindfulness',
      'inner peace',
      'moment of peace',
      'moment of stillness',
      'because you',
      'because your',
      'this means',
      'that means you',
      'deep down',
      'unconsciously',
      'subconscious',
      'root cause',
      'attachment style',
      'diagnos',
      'disorder',
      'psycholog',
      'clinical',
      'therapy',
      'therapist',
      'uykuya',
      'go to sleep',
      'fall asleep',
      'hard to sleep',
      // Naming speech-act drift inside Receipt (EN)
      'on your mind',
      'holding on',
      'weighing on',
      'still weighing',
    ]);
  }

  /// Guard Permission Contract V1.0 ([PermissionRealizationContract]).
  ///
  /// Admits obligation-ease / non-resolution wording from the shared contract.
  /// Rejects Release enactment speech acts (let go / set down / put down…).
  /// Fail closed on advice, invented problems, and other-WHAT drift.
  /// Structural only — not psychological scoring.
  bool _matchesPermissionContract(String lower) {
    return PermissionRealizationContract.matchesObligationEase(lower);
  }

  /// Guard Release Contract V1.1.
  ///
  /// Admits quiet putting-down wording.
  /// Keeps classic stems (including FaithfulTestVendor) and adds natural
  /// variants so “Let it rest for now” is not structurally required.
  /// Includes bounded `set … down` put-down pattern (not universal).
  /// Fail closed on sleep commands and other-WHAT drift (cross-phase).
  bool _matchesReleaseContract(String lower) {
    if (_releaseUnsafe(lower)) {
      return false;
    }

    if (_containsAny(lower, _releaseClassicStems)) {
      return true;
    }

    if (_matchesReleaseSetDownPattern(lower)) {
      return true;
    }

    return _containsAny(lower, _releaseNaturalPutDownCues);
  }

  /// Bounded set-down pattern: `set` … `down` with restward/load cue.
  ///
  /// Admits short legal variants such as “set those thoughts down for now”
  /// without admitting arbitrary “set … down” text.
  bool _matchesReleaseSetDownPattern(String lower) {
    if (!RegExp(r'\bset\b.{0,40}\bdown\b').hasMatch(lower)) {
      return false;
    }

    return _containsAny(lower, const [
      'for now',
      'tonight',
      'for tonight',
      'thoughts',
      'the weight',
      'this weight',
      'here for',
      'some of that',
      'some of this',
      'some of it',
      'of that down',
      'of this down',
    ]);
  }

  /// Classic Release stems — still valid (FaithfulTestVendor path).
  static const List<String> _releaseClassicStems = [
    'let this rest',
    'let it rest',
    'set this down',
    'set it down',
    'put this down',
    'put it down',
    'release this',
    'let go for now',
  ];

  /// Natural putting-down cues (not a reply library).
  /// Avoids Permission-like “no need to / don't have to” stems.
  static const List<String> _releaseNaturalPutDownCues = [
    'lay this down',
    'lay it down',
    'leave it here',
    'leave this here',
    'leave that here',
    'leave some of that here',
    'leave some of this here',
    'leave some of it here',
    'leave some of that',
    'leave some of this',
    'leave it for the night',
    'leave this for the night',
    'leave that for the night',
    'loosen your grip',
    'loosen the grip',
    'stop holding',
    'stop gripping',
    'night can hold',
    'the night can hold',
    // Avoid “let the night hold…” — collides with Enough soft handoff lines.
    'set it aside',
    'set this aside',
    'set the weight down',
    'put the weight down',
    'rest it here',
    'rest this here',
    'ease your hold',
    'drop the grip',
    // Bounded let-go (temporal/place) — not bare “let go” alone.
    'let go for tonight',
    'let go tonight',
    'let go of that tonight',
    'let go of this tonight',
    'let go of it tonight',
    'let go of that for now',
    'let go of this for now',
    // Turkish Release (same speech-act)
    'gece tutabilir',
    'gece taşıyabilir',
    'gece seni tutsun',
    'bir kenara bırak',
    'bir kenara koy',
    'şimdi kenara koy',
    'simdi kenara koy',
    'kenara koy',
    'burada bırak',
    'şimdilik bırak',
    'simdilik birak',
    'şimdilik burada bırak',
    'bırakabilirsin',
    'bırakmana izin',
    'tutabilir',
    'taşıyabilir',
    'yumuşakça bırak',
    'yumusakca birak',
    'şimdi bırak',
    'burada tut',
    'geceye bırak',
    'bu yükü bırak',
    'bu yuku birak',
    'bu yükü burada bırak',
    'taşımayı bırak',
    'tasiyi birak',
    'tutuşunu gevşet',
    'tutusunu gevset',
    // Intentionally omit bare "can rest here" — collides with Enough
    // “words can rest here …” under cross-phase faithfulness.
  ];

  bool _releaseUnsafe(String lower) {
    return _containsAny(lower, const [
      'go to sleep',
      'you should sleep',
      'fall asleep',
      'make yourself sleep',
      'force yourself to sleep',
      'sleep now',
      'have you tried',
      'you should',
      'try this',
      'tip:',
      'action plan',
      'diagnos',
      'therapist',
      'therapy',
    ]);
  }

  /// Guard Naming Contract V2.
  ///
  /// Admits quiet recognition of what is already evident.
  /// Keeps V1 canonical stems and adds semantic Naming patterns.
  /// Fail closed on interpretation, diagnosis, or psychology explanation.
  bool _matchesNamingContract(String lower) {
    // Fail closed: Naming must not become interpretation / diagnosis / psych.
    if (_namingInterpretationOrDiagnosis(lower)) {
      return false;
    }

    // V1 canonical stems (preserved).
    if (_containsAny(lower, _namingCanonicalStems)) {
      return true;
    }

    // V2 semantic quiet-recognition patterns.
    return _matchesNamingSemanticPattern(lower);
  }

  /// V1 Naming stems — still valid admission paths.
  static const List<String> _namingCanonicalStems = [
    'holding on',
    'weighing',
    'still there',
    'lingering',
    'on your mind',
    // Turkish quiet-recognition
    'aklında',
    'aklinda',
    'zihninde',
    'hâlâ orada',
    'hala orada',
    'duruyor',
    'tutunuyor',
    // Note: do not use bare “ağırlığı” here — Receipt loneliness texture
    // (“yalnızlığın ağırlığı”) must not cross-reject under Naming stems.
    'dönüp duruyor',
    'donup duruyor',
  ];

  /// Evident ongoing-load tokens that may be quietly named.
  static const List<String> _namingEvidentLoadTokens = [
    'loop',
    'loops',
    'looping',
    'replay',
    'replaying',
    'racing',
    'spinning',
    'churning',
    'repeating',
    'rumination',
    'ruminating',
    'overthink',
    'overthinking',
    'going over',
    'going through',
    'yalnız',
    'yalnizlik',
    'yalnızlık',
    'yalniz',
    'lonely',
    'loneliness',
  ];

  /// Persistence / continuation cues paired with evident load.
  static const List<String> _namingPersistenceCues = [
    'keep ',
    'keeps ',
    'keeping ',
    'still ',
    'over and over',
    "won't stop",
    'wont stop',
    'will not stop',
    'coming back',
    'won\'t quit',
    'wont quit',
  ];

  /// Quiet-recognition frames that name what is happening (not Permission/Release).
  static const List<String> _namingRecognitionFrames = [
    "what's happening",
    'whats happening',
    'what is happening',
    "that's what's happening",
    'thats whats happening',
    "that's what is happening",
    'thats what is happening',
  ];

  /// Soft-perspective / golden-reframe TYPE cues (not positivity advice).
  /// Admitted only when paired with evident load or canonical Naming stem.
  static const List<String> _namingSoftPerspectiveCues = [
    'the hard part',
    'part of what',
    'not the thought',
    'not only the',
    'keeping watch',
    'staying safe',
    'if you stop',
    'cost of stopping',
    'makes letting go',
    'makes it hard to stop',
  ];

  bool _matchesNamingSemanticPattern(String lower) {
    final hasLoad = _containsAny(lower, _namingEvidentLoadTokens);
    final hasCanonical = _containsAny(lower, _namingCanonicalStems);
    final hasMindHold = _containsAny(lower, const [
      'thinking',
      'your mind',
      'the mind',
      'holding',
      'letting go',
    ]);

    // Pattern C: soft perspective + (load / canonical / mind-hold cue)
    // Golden reframe TYPE — perspective shift, not positivity advice.
    if (_containsAny(lower, _namingSoftPerspectiveCues) &&
        (hasLoad || hasCanonical || hasMindHold)) {
      return true;
    }

    if (!hasLoad) {
      return false;
    }

    // Pattern A: recognition frame + evident load
    // e.g. "that's what's happening: the loops keep repeating"
    if (_containsAny(lower, _namingRecognitionFrames)) {
      return true;
    }

    // Pattern B: evident load + persistence cue
    // e.g. "those loops keep repeating"
    // Intentionally requires persistence so Receipt lines like
    // "that sounds exhausting, with your mind caught in a loop"
    // do not collide into Naming for cross-phase rejection.
    if (_containsAny(lower, _namingPersistenceCues)) {
      return true;
    }

    return false;
  }

  /// Fail-closed Naming exclusions: interpretation / diagnosis / psychology.
  bool _namingInterpretationOrDiagnosis(String lower) {
    return _containsAny(lower, const [
      'because you',
      'because your',
      'this means',
      'that means you',
      'deep down',
      'unconsciously',
      'subconscious',
      'root cause',
      'the reason is',
      'you are afraid',
      'you\'re afraid',
      'youre afraid',
      'your trauma',
      'attachment style',
      'projection',
      'diagnos',
      'disorder',
      'psycholog',
      'clinical',
      'therapy',
      'therapist',
    ]);
  }

  /// Enforces the bound [dna]: all anti-rules and all principles.
  /// Admit/reject only.
  bool _satisfiesDna({
    required String text,
    required ConversationPhase what,
    required ConversationDNA dna,
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
    String? userUtterance,
    String? mirrorGroundingUtterance,
  }) {
    // Only the bound canonical DNA may authorize emission.
    if (!identical(dna, ConversationDNA.instance)) {
      return false;
    }

    final lower = _normalizeForMatch(text);

    for (final antiRule in ConversationDNA.antiRules) {
      if (!_antiRuleClear(
        lower: lower,
        what: what,
        antiRule: antiRule,
        expressionMode: expressionMode,
        userUtterance: userUtterance,
        mirrorGroundingUtterance: mirrorGroundingUtterance,
      )) {
        return false;
      }
    }

    for (final principle in ConversationDNA.principles) {
      if (!_principleClear(
        lower: lower,
        text: text,
        what: what,
        principle: principle,
        expressionMode: expressionMode,
        userUtterance: userUtterance,
        mirrorGroundingUtterance: mirrorGroundingUtterance,
      )) {
        return false;
      }
    }

    return true;
  }

  bool _antiRuleClear({
    required String lower,
    required ConversationPhase what,
    required ConversationDNAAntiRule antiRule,
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
    String? userUtterance,
    String? mirrorGroundingUtterance,
  }) {
    switch (antiRule.name) {
      case 'Multiple insights in one turn':
        return !_containsAny(lower, const [
          ' also ',
          ' additionally ',
          ' another ',
          '1.',
          '2.',
          ' first ',
          ' second ',
          'tip:',
          'try this',
        ]);
      case 'Analysis, scores, or pattern narration as content':
        return !_containsAny(lower, const [
          'score',
          'diagnos',
          'pattern shows',
          'i detected',
          'analysis',
          'your anxiety level',
          'your pattern',
          'i classified',
          'based on your data',
        ]);
      case 'Engagement hooks or follow-up bait':
        if (expressionMode == ConversationExpressionMode.lightChat ||
            expressionMode == ConversationExpressionMode.repair ||
            expressionMode == ConversationExpressionMode.narrow) {
          if (_tooManyQuestions(lower)) return false;
          return !_containsAny(lower, const [
            'tell me more',
            'what else',
            'let’s keep talking',
            "let's keep talking",
            'want to keep going',
            "let's keep going",
            'lets keep going',
            'keep going?',
            'keep talking',
            'want to talk',
            'share more',
          ]);
        }
        return !_containsAny(lower, const [
          '?',
          'tell me more',
          'what else',
          'let’s keep talking',
          "let's keep talking",
          'want to keep going',
          "let's keep going",
          'lets keep going',
          'keep going?',
          'keep talking',
          'want to talk',
          'share more',
        ]);
      case 'Sleep commands or performance coaching':
        return !_containsAny(lower, const [
          'go to sleep',
          'you should sleep',
          'fall asleep',
          'make yourself sleep',
          'force yourself to sleep',
          'sleep better tonight',
          'improve your sleep',
        ]);
      case 'Clinical / diagnostic / therapeutic framing':
        return !_containsAny(lower, const [
          'therapist',
          'therapy',
          'clinical',
          'disorder',
          'crisis',
          'medication',
          'diagnos',
          'psycholog',
          'treatment plan',
        ]);
      case 'Rewriting the decided conversational move':
        // Enforced by the WHAT faithfulness gate before DNA checks.
        // Re-assert against the same sealed WHAT; never rewrite text.
        return _faithfulToWhat(
          lower,
          what,
          expressionMode: expressionMode,
          userUtterance: userUtterance,
          mirrorGroundingUtterance: mirrorGroundingUtterance,
        );
      default:
        // Unknown anti-rule on a non-canonical DNA binding cannot pass.
        return false;
    }
  }

  bool _principleClear({
    required String lower,
    required String text,
    required ConversationPhase what,
    required ConversationDNAPrinciple principle,
    ConversationExpressionMode expressionMode =
        ConversationExpressionMode.standard,
    String? userUtterance,
    String? mirrorGroundingUtterance,
  }) {
    switch (principle.id) {
      case 1: // Subtract, do not add
        return !_containsAny(lower, const [
          'have you tried',
          "let's work on",
          'lets work on',
          'action plan',
          'homework',
          'new problem',
          'another issue',
          'we should examine',
          'think about why',
        ]);
      case 2: // Fewest helpful words
        final words = text
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
        return words <= _maxHelpfulWords;
      case 3: // One help, not many
        return !_containsAny(lower, const [
          ' and also ',
          ' also try ',
          ' additionally ',
          ' another tip',
          'as well as',
          'not only',
        ]);
      case 4: // Understood, not analyzed
        return !_containsAny(lower, const [
          'score',
          'diagnos',
          'pattern shows',
          'i detected',
          'analysis',
          'i labeled',
          'system shows',
          'your anxiety level',
        ]);
      case 5: // Attention, not storage
        return !_containsAny(lower, const [
          'i stored',
          'database',
          'in my memory',
          'your profile says',
          'according to your record',
          'from your data',
        ]);
      case 6: // Relief over engagement
        if (expressionMode == ConversationExpressionMode.lightChat ||
            expressionMode == ConversationExpressionMode.repair ||
            expressionMode == ConversationExpressionMode.narrow) {
          if (_tooManyQuestions(text)) return false;
          return !_containsAny(lower, const [
            'tell me more',
            'what else',
            'let’s keep talking',
            "let's keep talking",
            'keep talking',
            'continue this',
          ]);
        }
        return !_containsAny(lower, const [
          '?',
          'tell me more',
          'what else',
          'let’s keep talking',
          "let's keep talking",
          'keep talking',
          'continue this',
        ]);
      case 7: // Silence can be success — reject presence-filling
        return !_containsAny(lower, const [
          'just checking in',
          "i'm still here",
          'im still here',
          'i am here if',
          "don't go quiet",
          'dont go quiet',
          'say something',
        ]);
      case 8: // Sleep is never forced
        return !_containsAny(lower, const [
          'go to sleep',
          'you should sleep',
          'fall asleep',
          'make yourself sleep',
          'force yourself to sleep',
          'sleep now',
        ]);
      case 9: // Stay inside the decided help
        // Enforced by WHAT faithfulness before DNA; nothing further here.
        return true;
      case 10: // Remain human and non-clinical
        return !_containsAny(lower, const [
          'therapist',
          'therapy',
          'clinical',
          'disorder',
          'crisis',
          'medication',
          'as an ai',
          'as a chatbot',
          'doctor',
          'productivity',
          'optimize your',
        ]);
      default:
        return false;
    }
  }
}
