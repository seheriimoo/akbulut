import '../session_engine/session_engine.dart';
import '../session_engine/sleep_session.dart';
import 'user_sleep_profile.dart';

class PersonalizationEngine {
  final SessionEngine _sessionEngine;

  PersonalizationEngine({SessionEngine? sessionEngine})
      : _sessionEngine = sessionEngine ?? SessionEngine();

  SleepSession getRecommendedSession(UserSleepProfile profile) {
    return _sessionEngine.getRecommendedSession(
      sleepLatency: profile.sleepLatency,
      stressLevel: profile.stressLevel,
    );
  }
}
