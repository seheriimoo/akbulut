import 'sleep_session.dart';

class SessionEngine {
  static const List<SleepSession> defaultSessions = [
    SleepSession(
      id: 'deep_sleep_10',
      title: 'Deep Sleep',
      duration: Duration(minutes: 10),
      backgroundAsset:
          'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m_clean.m4a',
      voiceAsset: null,
    ),
    SleepSession(
      id: 'deep_sleep_30',
      title: 'Deep Sleep',
      duration: Duration(minutes: 30),
      backgroundAsset:
          'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m_clean.m4a',
      voiceAsset: null,
    ),
    SleepSession(
      id: 'deep_sleep_45',
      title: 'Deep Sleep',
      duration: Duration(minutes: 45),
      backgroundAsset:
          'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m_clean.m4a',
      voiceAsset: null,
    ),
    SleepSession(
      id: 'deep_sleep_60',
      title: 'Deep Sleep',
      duration: Duration(minutes: 60),
      backgroundAsset:
          'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m_clean.m4a',
      voiceAsset: null,
    ),
  ];

  SleepSession getRecommendedSession({
    required String sleepLatency,
    required String stressLevel,
  }) {
    if (sleepLatency == 'More than 40 minutes' || stressLevel == 'High') {
      return defaultSessions.firstWhere((s) => s.id == 'deep_sleep_45');
    }

    if (sleepLatency == '20–40 minutes') {
      return defaultSessions.firstWhere((s) => s.id == 'deep_sleep_30');
    }

    return defaultSessions.firstWhere((s) => s.id == 'deep_sleep_10');
  }

  SleepSession getSessionById(String id) {
    return defaultSessions.firstWhere(
      (session) => session.id == id,
      orElse: () => defaultSessions.first,
    );
  }
}