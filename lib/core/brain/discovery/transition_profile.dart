import '../thinking_function_kind.dart';
import 'night_mind_map.dart';
import 'night_pattern_id.dart';
import 'sleep_mind_mirror.dart';

/// Internal profile for Nocta Transition selection/adaptation.
///
/// Presentation-plane input. Not a diagnosis. Not generative-audio claim.
class TransitionProfile {
  final NightPatternId pattern;
  final ThinkingFunctionKind? function;
  final String? loopSketch;
  final String arousalType;
  final String transitionNeed;

  /// Catalog blocker key compatible with existing [NightAudioHandoff] / beds.
  final String blockerKey;

  final List<String> adaptationHints;

  const TransitionProfile({
    required this.pattern,
    required this.transitionNeed,
    required this.blockerKey,
    this.function,
    this.loopSketch,
    this.arousalType = 'cognitive',
    this.adaptationHints = const [],
  });
}

class TransitionProfileBuilder {
  const TransitionProfileBuilder();

  TransitionProfile fromMap(NightMindMap map, {SleepMindMirror? mirror}) {
    final pattern = map.leadingPattern;
    final need = _need(pattern);
    final blocker = _blocker(pattern, map);
    return TransitionProfile(
      pattern: pattern,
      function: map.thinkingFunction,
      loopSketch: map.loopStructure,
      arousalType: map.arousalType ?? 'cognitive',
      transitionNeed: need,
      blockerKey: blocker,
      adaptationHints: [
        if (mirror != null) 'mirror:${mirror.pattern.name}',
        'need:$need',
        if (map.perceivedUtility != null) 'utility:${map.perceivedUtility}',
      ],
    );
  }

  String _need(NightPatternId pattern) {
    switch (pattern) {
      case NightPatternId.worstCaseRehearsal:
      case NightPatternId.preparationRehearsal:
        return 'permission_to_leave_tomorrow_unresolved';
      case NightPatternId.certaintyChase:
        return 'enough_checking_for_tonight';
      case NightPatternId.earlyTomorrowCarry:
        return 'set_tomorrow_down';
      case NightPatternId.protectiveHolding:
        return 'soft_off_watch';
      case NightPatternId.unfinishedLoop:
        return 'park_the_thread';
      case NightPatternId.relationalReplay:
        return 'release_the_exchange';
      case NightPatternId.lonelinessPresence:
        return 'companionship_presence';
      case NightPatternId.bodyAlarm:
        return 'somatic_downshift';
      case NightPatternId.decisionPendulum:
        return 'decide_tomorrow_permission';
      case NightPatternId.unknown:
        return 'gentle_mind_rest';
    }
  }

  /// Maps pattern → existing bed family keys (loneliness/relationship/stress/mind).
  String _blocker(NightPatternId pattern, NightMindMap map) {
    switch (pattern) {
      case NightPatternId.lonelinessPresence:
        return 'loneliness';
      case NightPatternId.relationalReplay:
        return 'relationship';
      case NightPatternId.bodyAlarm:
        return 'stress';
      case NightPatternId.worstCaseRehearsal:
      case NightPatternId.preparationRehearsal:
      case NightPatternId.certaintyChase:
      case NightPatternId.earlyTomorrowCarry:
      case NightPatternId.protectiveHolding:
      case NightPatternId.unfinishedLoop:
      case NightPatternId.decisionPendulum:
      case NightPatternId.unknown:
        if (map.arousalType == 'somatic') return 'stress';
        return 'mind';
    }
  }
}
