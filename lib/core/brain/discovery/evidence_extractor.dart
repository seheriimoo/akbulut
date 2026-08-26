import '../conversation_grounding_buffer.dart';
import '../thinking_function_hypothesis.dart';
import 'discovery_dimension.dart';
import 'negation_correction_contract.dart';
import 'night_mind_map.dart';

/// Deterministic evidence extraction into [NightMindMap].
///
/// Extract first; ask only for genuinely missing high-value dimensions.
///
/// Hardening contract (human audit):
/// - Explicit user language must resolve into map dimensions (EN + TR stems).
/// - Temporary-relief + restart loops must land as [actualEffect].
/// - Acute somatic phrases flag [NightMindMap.acuteSomaticCaution]
///   (safety route — not a sleep-pattern Mirror).
/// - Explicit negation/correction > prior hypothesis (never Mirror the reject).
class EvidenceExtractor {
  const EvidenceExtractor({
    this.negationCorrection = const NegationCorrectionContract(),
  });

  final NegationCorrectionContract negationCorrection;

  NightMindMap extract({
    required NightMindMap prior,
    required String message,
    ConversationGroundingBuffer? grounding,
    ThinkingFunctionHypothesis? thinkingFunction,
  }) {
    final text = _norm(message);
    // Explicit correction first — clears conflicting prior inference.
    var map = negationCorrection.apply(prior: prior, text: text);
    map = map.withThinkingFunction(thinkingFunction);
    final evidence = [...map.evidenceIds];
    final resolved = {...map.resolvedDimensions};
    final blockPrep = negationCorrection.blocksPreparednessExtraction(text);
    final blockLonely = negationCorrection.blocksLonelinessExtraction(text);

    void resolve(DiscoveryDimension d, String id) {
      resolved.add(d);
      evidence.add(id);
    }

    String? topic = map.topicDomain;
    if (_has(text, [
      r'\btomorrow\b',
      r'\byarin\b',
      r'\bmeeting\b',
      r'\btoplanti\b',
      r'\binterview\b',
      r'\bmulakat\b',
    ])) {
      topic = topic ?? 'tomorrow';
      resolve(DiscoveryDimension.topicDomain, 'lex:topic_tomorrow');
    } else if (_has(text, [
      r'\bex\b',
      r'\bmesaj\w*',
      r'\brelationship\b',
      r'\beski\b',
      r'\bkavga\b',
      r'\bsevgili\b',
      r'\bhim\b',
      r'\bher\b',
      r'\bthem\b',
    ])) {
      topic = topic ?? 'relationship';
      resolve(DiscoveryDimension.topicDomain, 'lex:topic_relational');
    }

    String? temporal = map.temporalOrientation;
    if (_has(text, [
      r'\btomorrow\b',
      r'\byarin\b',
      r'\bnext day\b',
      r'\bfuture\b',
      r'\bileride\b',
    ])) {
      temporal = 'future';
      resolve(DiscoveryDimension.temporalOrientation, 'lex:temporal_future');
    } else if (_has(text, [
      r'\bearlier\b',
      r'\btoday\b',
      r'\bbugun\b',
      r'\bsaid\b',
      r'\breplay\b',
      r'\baz once\b',
    ])) {
      temporal = temporal ?? 'present_or_past';
      resolve(DiscoveryDimension.temporalOrientation, 'lex:temporal_present');
    }

    String? thoughtForm = map.thoughtForm;
    if (_has(text, [
      r'\bscenario\w*',
      r'\bsenaryo\w*',
      r'\bihtimal\w*',
      r'\bher ihtimal\b',
      r'different .{0,20}(ways|outcomes)',
      r'\bevery possibility\b',
      r'\bends? badly\b',
      r'\bkotu ihtimal\b',
      r'\bwhat if\b',
    ])) {
      thoughtForm = 'multiplying_negative_scenarios';
      resolve(DiscoveryDimension.thoughtForm, 'lex:thought_scenarios');
    } else if (_has(text, [
      r'\brehears\w*',
      r'\brehearsing\b',
      r'\bprova\w*',
      r'\bcalisiyorum\b',
      r'\bpractice what\b',
      r'\brunning .{0,12}(lines|answers|what i)\b',
    ])) {
      thoughtForm = thoughtForm ?? 'preparation_rehearsal_loop';
      resolve(DiscoveryDimension.thoughtForm, 'lex:thought_rehearse');
    } else if (_has(text, [
      r'\breplay\b',
      r'\bkeep going over\b',
      r'\bdonup\b',
      r'\bokuyup\b',
      r'\bmesajini okuy\w*',
      r'\bmesaj\w* okuy\w*',
      r'\bkeske\b',
      r'\bsoylemeseydim\b',
    ])) {
      thoughtForm = thoughtForm ?? 'relational_or_event_replay';
      resolve(DiscoveryDimension.thoughtForm, 'lex:thought_replay');
    } else if (_has(text, [
      r'\bflipping\b',
      r'\bshould i\b',
      r'\bkarar\b',
      r'\bsecemiyorum\b',
      r'\bor not\b',
    ])) {
      thoughtForm = thoughtForm ?? 'decision_oscillation';
      resolve(DiscoveryDimension.thoughtForm, 'lex:thought_decision');
    } else if (_has(text, [
      r"can'?t stop thinking",
      r'\bstop thinking about\b',
      r'\bkafam (susmuyor|durmuyor)\b',
      r'\bdusun\w* durmuyor\b',
    ])) {
      thoughtForm = thoughtForm ?? 'repetitive_forward_load';
      resolve(DiscoveryDimension.thoughtForm, 'lex:thought_carry');
    }

    String? utility = map.perceivedUtility;
    if (blockPrep) {
      // Do not (re)resolve preparedness from a negated utterance.
      utility = null;
      resolved.remove(DiscoveryDimension.perceivedUtility);
      resolved.remove(DiscoveryDimension.thinkingFunction);
      resolved.remove(DiscoveryDimension.loopStructure);
    } else if (_has(text, [
      r'\bmore prepared\b',
      r'\bbe prepared\b',
      r'\bfeel(?:ing)? (?:more )?prepared\b',
      r'\bprepared\b',
      r'\bpreparation\b',
      r'\bhazir\w*',
      r'\boff guard\b',
      r'\bcaught\b',
      r'\bblindsid\w*',
      r'\byakalanmak\b',
    ])) {
      utility = 'thinking_as_preparation';
      resolve(DiscoveryDimension.perceivedUtility, 'lex:utility_prep');
      resolve(DiscoveryDimension.thinkingFunction, 'lex:function_prep');
    } else if (_has(text, [
      r'\bone more\b',
      r'\balmost\b',
      r'\bcertainty\b',
      r'\bemin\b',
      r'\bbir daha\b',
      r'\bfigured\b',
    ])) {
      utility = utility ?? 'seeking_certainty';
      resolve(DiscoveryDimension.perceivedUtility, 'lex:utility_certainty');
      resolve(DiscoveryDimension.thinkingFunction, 'lex:function_certainty');
    } else if (_has(text, [
      r"can'?t let (it )?go",
      r'\blet it go\b',
      r'\bstop watching\b',
      r'\bif i stop\b',
      r'\bkeep(ing)? watch\b',
      r'\bsomething will slip\b',
      r'\bwill slip\b',
      r'\bbirakamiyorum\b',
      r'\bkacir\w*',
      r'\bnobet\w*',
    ])) {
      utility = utility ?? 'protective_watch';
      resolve(DiscoveryDimension.perceivedUtility, 'lex:utility_watch');
      resolve(DiscoveryDimension.thinkingFunction, 'lex:function_hold');
    }

    String? effect = map.actualEffect;
    if (_has(text, [
      r'\banother\b',
      r'\bnew scenario\b',
      r'\byeni (bir )?senaryo\b',
      r'\bkeeps (creating|coming)\b',
      r'\byenisi\b',
      r'\bstill (creating|running)\b',
      r'\bmore (scenarios|possibilit)\w*',
      r'\bkapanmiyor\b',
      r'\bnever closes\b',
      r'\bopens another\b',
      r'\bher kontrol\b',
      r'\byeni bir senaryo aciyor\b',
      r'\bstart again\b',
      r'\bbegin again\b',
      r'\bhelps for a (second|moment|bit)\b',
      r'\bhelps .{0,20}then .{0,20}(start|begin) again\b',
      r'\brahatlatiyor .{0,20}sonra\b',
    ])) {
      effect = 'perpetuates_new_scenarios';
      resolve(DiscoveryDimension.actualEffect, 'lex:effect_perpetuate');
    }

    String? loop = map.loopStructure;
    final formForLoop = thoughtForm ?? map.thoughtForm;
    final utilityForLoop = utility ?? map.perceivedUtility;
    if ((formForLoop == 'multiplying_negative_scenarios' ||
            formForLoop == 'preparation_rehearsal_loop') &&
        (utilityForLoop != null || effect != null || map.actualEffect != null)) {
      loop = 'scenario→check→temporary_prep→new_scenario';
      resolve(DiscoveryDimension.loopStructure, 'struct:loop_rehearsal');
    }

    // Acute somatic caution: heart + breath / can't-breathe style phrases.
    // Product safety — do not treat as ordinary sleep-pattern Mirror fuel.
    var acuteSomatic = map.acuteSomaticCaution;
    final heartCue = _has(text, [
      r'\bheart\b',
      r'\bchest\b',
      r'\bkalp\w*',
      r'\bgogus\b',
      r'\bpanic\b',
    ]);
    final breathCue = _has(text, [
      r'\bbreath\w*',
      r"can'?t breathe",
      r'\bnefes\w*',
      r'\bnefesim yetmiyor\b',
      r'\btitriyor\b',
    ]);
    if ((heartCue && breathCue) ||
        _has(text, [
          r'\bnefesim yetmiyor\b',
          r"can'?t breathe",
          r'\bshort of breath\b',
        ])) {
      acuteSomatic = true;
      evidence.add('lex:acute_somatic_caution');
    }

    String? arousal = map.arousalType;
    if (heartCue || breathCue || acuteSomatic) {
      arousal = acuteSomatic ? 'somatic_acute' : 'somatic';
      resolve(DiscoveryDimension.arousalType, 'lex:arousal_soma');
    } else if (thoughtForm != null || utility != null) {
      arousal = arousal ?? 'cognitive';
      if (arousal == 'cognitive' &&
          !resolved.contains(DiscoveryDimension.arousalType)) {
        resolve(DiscoveryDimension.arousalType, 'lex:arousal_cognitive');
      }
    }

    String? emotional = map.emotionalDriver;
    String? need = map.unresolvedNeed;
    // Loneliness: stem match (yalnizim, yalnızlık, alone tonight, miss having someone).
    if (!blockLonely &&
        _has(text, [
      r'\blonely\b',
      r'\balone\b',
      r'\byalniz\w*',
      r'\bmiss (him|her|them)\b',
      r'\bi miss\b',
      r'\bmiss having\b',
      r'\bmissing someone\b',
      r'\bsomeone here\b',
      r'\bozledim\b',
      r'\bozluyorum\b',
      r'\bozlem\w*',
      r'\bsessizlik\b',
      r'\bquiet and i miss\b',
      r'\byaninda (biri|birinin)\b',
    ])) {
      emotional = emotional ?? 'loneliness_absence';
      need = need ?? 'companionship_presence';
      resolve(DiscoveryDimension.emotionalDriver, 'lex:emotion_lonely');
      resolve(DiscoveryDimension.unresolvedNeed, 'lex:need_presence');
      topic = topic ?? 'relationship';
      resolve(DiscoveryDimension.topicDomain, 'lex:topic_lonely');
    } else if (_has(text, [
      r'\bkavga\b',
      r'\bkeske\b',
      r'\bsoylemeseydim\b',
      r'\bmesaj\w*',
    ])) {
      emotional = emotional ?? 'relational_regret_replay';
      need = need ?? 'repair_or_release_exchange';
      resolve(DiscoveryDimension.emotionalDriver, 'lex:emotion_relational');
      resolve(DiscoveryDimension.unresolvedNeed, 'lex:need_repair');
    } else if (_has(text, [
      r'\bbitmedi\b',
      r'\byarim\b',
      r'\bunfinished\b',
      r'\bopen thread\b',
    ])) {
      need = need ?? 'park_unfinished_thread';
      resolve(DiscoveryDimension.unresolvedNeed, 'lex:need_unfinished');
      resolve(DiscoveryDimension.thoughtForm, 'lex:thought_unfinished');
      thoughtForm = thoughtForm ?? 'unfinished_open_thread';
    }

    return map.copyWith(
      topicDomain: topic,
      temporalOrientation: temporal,
      thoughtForm: thoughtForm,
      perceivedUtility: utility,
      clearPerceivedUtility: blockPrep && utility == null,
      clearThinkingFunction: blockPrep,
      actualEffect: effect,
      loopStructure: blockPrep ? null : loop,
      clearLoopStructure: blockPrep,
      arousalType: arousal,
      emotionalDriver: emotional,
      unresolvedNeed: need,
      resolvedDimensions: resolved,
      evidenceIds: evidence.toSet().toList(),
      acuteSomaticCaution: acuteSomatic,
      hypothesisReopenRequired: map.hypothesisReopenRequired || blockPrep,
    );
  }

  /// True if any pattern matches [text] (already normalized).
  static bool _has(String text, List<String> patterns) {
    for (final p in patterns) {
      if (RegExp(p).hasMatch(text)) return true;
    }
    return false;
  }

  static String _norm(String message) {
    return message
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('â', 'a')
        .trim();
  }
}
