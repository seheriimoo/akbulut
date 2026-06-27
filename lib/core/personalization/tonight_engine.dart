import '../session_engine/session_engine.dart';
import '../session_engine/sleep_session.dart';
import 'tonight_problem.dart';

class TonightEngine {
  final SessionEngine _sessionEngine = SessionEngine();

  SleepSession sessionForProblem(TonightProblem problem) {
    switch (problem) {
      case TonightProblem.racingThoughts:
        return _sessionEngine.getSessionById('deep_sleep_30');

      case TonightProblem.stress:
        return _sessionEngine.getSessionById('deep_sleep_45');

      case TonightProblem.cantFallAsleep:
        return _sessionEngine.getSessionById('deep_sleep_10');

      case TonightProblem.wantDeepSleep:
        return _sessionEngine.getSessionById('deep_sleep_60');
    }
  }
}
