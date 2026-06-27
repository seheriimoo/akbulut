import '../models/user_sleep_profile.dart';

class SleepSessionSelector {

  static String chooseSession(UserSleepProfile profile) {

    if (profile.racingThoughts) {
      return "calm_air";
    }

    if (profile.stressLevel >= 4) {
      return "deep_relax";
    }

    if (profile.sleepLatency >= 30) {
      return "long_sleep_entry";
    }

    return "soft_sleep_entry";
  }

}