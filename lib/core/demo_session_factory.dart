import '../models/session_model.dart';

class DemoSessionFactory {
  static SomniaSession defaultSession() {
    return const SomniaSession(
      id: 'demo_sleep_session',
      title: 'Soft Sleep Entry',
      backgroundAssetPath:
          'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m_clean.m4a',
      totalDuration: Duration(minutes: 30),
      breathingType: 'slow_breathing',
      goal: 'sleep_onset',
    );
  }
}