import 'transition_profile.dart';

/// Deterministic Nocta Transition speech from an existing [TransitionProfile].
///
/// Uses [TransitionProfile.transitionNeed] only — never invents a second
/// profile from keywords when Discovery already produced one.
class NoctaTransitionSurface {
  const NoctaTransitionSurface();

  String compile(
    TransitionProfile profile, {
    required bool preferTurkish,
  }) {
    final need = profile.transitionNeed.trim();
    if (preferTurkish) return _tr(need);
    return _en(need);
  }

  String _en(String need) {
    switch (need) {
      case 'permission_to_leave_tomorrow_unresolved':
        return 'You can leave tomorrow unresolved tonight. I\'ll take you into quiet sound.';
      case 'enough_checking_for_tonight':
        return 'That\'s enough checking for tonight. I\'ll leave you with quiet sound.';
      case 'set_tomorrow_down':
        return 'We can set tomorrow down here. I\'ll leave you with quiet sound.';
      case 'soft_off_watch':
        return 'You can come off watch for tonight. I\'ll leave you with quiet sound.';
      case 'park_the_thread':
        return 'We can park that thread for tonight. I\'ll leave you with quiet sound.';
      case 'release_the_exchange':
        return 'You can let that exchange rest tonight. I\'ll leave you with quiet sound.';
      case 'companionship_presence':
        return 'I\'m here with you into the quiet. I\'ll leave you with soft sound.';
      case 'somatic_downshift':
        return 'We can let the body settle now. I\'ll leave you with quiet sound.';
      case 'decide_tomorrow_permission':
        return 'You don\'t have to decide tonight. I\'ll leave you with quiet sound.';
      case 'gentle_mind_rest':
      default:
        return 'We can rest the mind here. I\'ll leave you with quiet sound.';
    }
  }

  String _tr(String need) {
    switch (need) {
      case 'permission_to_leave_tomorrow_unresolved':
        return 'Yarını bu gece çözülmemiş bırakabilirsin. Seni sese bırakıyorum.';
      case 'enough_checking_for_tonight':
        return 'Bu gece bu kadar kontrol yeter. Seni sese bırakıyorum.';
      case 'set_tomorrow_down':
        return 'Yarını burada bırakabiliriz. Seni sese bırakıyorum.';
      case 'soft_off_watch':
        return 'Bu gece nöbeti bırakabilirsin. Seni sese bırakıyorum.';
      case 'park_the_thread':
        return 'O ipi bu gece kenara koyabiliriz. Seni sese bırakıyorum.';
      case 'release_the_exchange':
        return 'O konuşmayı bu gece bırakabilirsin. Seni sese bırakıyorum.';
      case 'companionship_presence':
        return 'Sessizliğe birlikte geçiyoruz. Seni yumuşak sese bırakıyorum.';
      case 'somatic_downshift':
        return 'Bedenin yavaşlayabilir. Seni sese bırakıyorum.';
      case 'decide_tomorrow_permission':
        return 'Bu gece karar vermek zorunda değilsin. Seni sese bırakıyorum.';
      case 'gentle_mind_rest':
      default:
        return 'Zihni burada bırakabiliriz. Seni sese bırakıyorum.';
    }
  }
}
