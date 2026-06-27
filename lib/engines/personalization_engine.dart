import '../models/session_model.dart';
import '../models/user_profile.dart';

class SomniaPersonalizationEngine {
  const SomniaPersonalizationEngine();

  SomniaSession recommendSession(SomniaUserProfile profile) {
    if (profile.hasRacingThoughts) {
      return SomniaSession(
        id: 'racing_thoughts_reset',
        title: 'Quiet Mind',
        backgroundAssetPath:
            'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a',
        totalDuration: const Duration(minutes: 30),
        breathingType: 'extended_exhale',
        goal: 'calm_thoughts',
      );
    }

    if (profile.stressLevel >= 7) {
      return SomniaSession(
        id: 'stress_reset',
        title: 'Nervous System Reset',
        backgroundAssetPath:
            'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a',
        totalDuration: const Duration(minutes: 30),
        breathingType: 'slow_breathing',
        goal: 'stress_relief',
      );
    }

    if (profile.sleepLatencyMinutes >= 30) {
      return SomniaSession(
        id: 'long_sleep_latency',
        title: 'Deep Sleep Entry',
        backgroundAssetPath:
            'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_45m.m4a',
        totalDuration: const Duration(minutes: 45),
        breathingType: 'nervous_system_calming',
        goal: 'fall_asleep_faster',
      );
    }

    return SomniaSession(
      id: 'default_sleep_session',
      title: 'Soft Sleep Entry',
      backgroundAssetPath:
          'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a',
      totalDuration: const Duration(minutes: 30),
      breathingType: 'slow_breathing',
      goal: 'sleep_onset',
    );
  }
}