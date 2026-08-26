import 'discovery_dimension.dart';
import 'night_mind_map.dart';
import 'night_pattern_id.dart';

/// Explicit user negation / correction over prior (or same-turn) inference.
///
/// Epistemic rule: explicit correction > previous hypothesis.
/// When the user rejects a claim (e.g. preparedness), conflicting map fields
/// must be cleared, the contradiction recorded, Mirror blocked until reopen,
/// and a fresh discriminating objective preferred.
class NegationCorrectionContract {
  const NegationCorrectionContract();

  /// Apply corrections to [prior] given normalized [text].
  NightMindMap apply({
    required NightMindMap prior,
    required String text,
  }) {
    var map = prior;
    final contradictions = [...map.contradictions];
    var reopen = map.hypothesisReopenRequired;

    if (_negatesPreparedness(text)) {
      final cleared = _clearPreparedness(map);
      if (cleared.$2) {
        contradictions.add('correction:not_preparedness');
        reopen = true;
      }
      map = cleared.$1;
    }

    if (_negatesLoneliness(text)) {
      final cleared = _clearLoneliness(map);
      if (cleared.$2) {
        contradictions.add('correction:not_loneliness');
        reopen = true;
      }
      map = cleared.$1;
    }

    if (_isGeneralCorrection(text) &&
        map.leadingPattern != NightPatternId.unknown) {
      contradictions.add('correction:general_reject_leading');
      reopen = true;
      map = map.copyWith(
        leadingPattern: NightPatternId.unknown,
        mapConfidence: 0.2,
        hypotheses: const [],
      );
    }

    if (!reopen && contradictions.length == map.contradictions.length) {
      return map;
    }

    return map.copyWith(
      contradictions: contradictions,
      hypothesisReopenRequired: reopen,
    );
  }

  /// True when this turn negates preparedness — extractor must not resolve prep.
  bool blocksPreparednessExtraction(String text) => _negatesPreparedness(text);

  /// True when this turn negates loneliness extraction.
  bool blocksLonelinessExtraction(String text) => _negatesLoneliness(text);

  static bool _negatesPreparedness(String text) {
    return _has(text, [
      r"don'?t feel (?:more )?prepared",
      r'do not feel (?:more )?prepared',
      r"isn'?t about (?:feeling )?prepared",
      r'is not about (?:feeling )?prepared',
      r"not (?:about |feeling )?prepared\b",
      r"i'?m not prepar",
      r'not preparing',
      r"doesn'?t (?:feel like|mean) prepar",
      r'hazirlikli hissetmiyorum',
      r'hazir hissetmiyorum',
      r'hazirlik degil',
      r'hazirlikli degil',
      r'hazirlanmiyorum',
      r'mesele hazirlik degil',
      r'hazirlik icin degil',
    ]);
  }

  static bool _negatesLoneliness(String text) {
    return _has(text, [
      r"don'?t miss (him|her|them|anyone)",
      r'not (lonely|alone)',
      r"i'?m not (lonely|alone)",
      r'onu ozlemiyorum',
      r'yalniz degilim',
      r'yalnizlik degil',
      r'ozlemiyorum aslinda',
    ]);
  }

  static bool _isGeneralCorrection(String text) {
    // Short explicit reject without naming the claim.
    return _has(text, [
      r'^no\.?$',
      r'^hayir\.?$',
      r'^hayır\.?$',
      r"that'?s not (it|what i mean)",
      r'not what i mean',
      r"i don'?t mean that",
      r'mesele o degil',
      r'o degil',
      r'yanlis anladin',
      r'yanlis anladınız',
      r'yanlis anladiniz',
    ]);
  }

  static (NightMindMap, bool) _clearPreparedness(NightMindMap map) {
    final had = map.perceivedUtility == 'thinking_as_preparation' ||
        map.resolvedDimensions.contains(DiscoveryDimension.perceivedUtility) ||
        map.leadingPattern == NightPatternId.preparationRehearsal ||
        map.leadingPattern == NightPatternId.worstCaseRehearsal &&
            map.perceivedUtility == 'thinking_as_preparation';

    // Always strip prep utility/function/loop even mid-turn before extract.
    final resolved = {...map.resolvedDimensions}
      ..remove(DiscoveryDimension.perceivedUtility)
      ..remove(DiscoveryDimension.thinkingFunction)
      ..remove(DiscoveryDimension.loopStructure);

    var lead = map.leadingPattern;
    var conf = map.mapConfidence;
    if (lead == NightPatternId.preparationRehearsal) {
      lead = NightPatternId.unknown;
      conf = 0.25;
    }

    final next = map.copyWith(
      clearPerceivedUtility: true,
      clearThinkingFunction: map.thinkingFunction != null,
      clearLoopStructure: true,
      resolvedDimensions: resolved,
      leadingPattern: lead,
      mapConfidence: conf,
      hypotheses: lead == NightPatternId.unknown ? const [] : map.hypotheses,
    );
    return (next, true);
  }

  static (NightMindMap, bool) _clearLoneliness(NightMindMap map) {
    final had = map.emotionalDriver == 'loneliness_absence' ||
        map.leadingPattern == NightPatternId.lonelinessPresence;
    if (!had &&
        !map.resolvedDimensions
            .contains(DiscoveryDimension.emotionalDriver)) {
      return (map, false);
    }
    final resolved = {...map.resolvedDimensions}
      ..remove(DiscoveryDimension.emotionalDriver)
      ..remove(DiscoveryDimension.unresolvedNeed);
    return (
      map.copyWith(
        clearEmotionalDriver: true,
        clearUnresolvedNeed: true,
        resolvedDimensions: resolved,
        leadingPattern: map.leadingPattern == NightPatternId.lonelinessPresence
            ? NightPatternId.unknown
            : map.leadingPattern,
        mapConfidence: map.leadingPattern == NightPatternId.lonelinessPresence
            ? 0.25
            : map.mapConfidence,
      ),
      true,
    );
  }

  static bool _has(String text, List<String> patterns) {
    for (final p in patterns) {
      if (RegExp(p).hasMatch(text)) return true;
    }
    return false;
  }
}
