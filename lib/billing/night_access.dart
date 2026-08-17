/// V1 free-night gate. Not HCOS. Not Conversation.
///
/// Completed nights are [LivingMindStore] totals written only after
/// [HcosLiveEntry.completeNightSession] (audio finished or silence close).
/// Opening Welcome/Chat does not consume a night.
class NightAccess {
  const NightAccess._();

  /// Full HCOS + 30m audio nights before the conversation gate.
  static const int freeCompletedNights = 3;

  /// Premium (including store trial entitlement) never hits the 3-night gate.
  static bool canStartConversation({
    required bool isPremium,
    required int completedNights,
  }) {
    if (isPremium) return true;
    return completedNights < freeCompletedNights;
  }

  /// Soft post-night copy after the third completed free night only.
  static bool shouldShowPostThirdNightNote({
    required bool isPremium,
    required int completedNights,
  }) {
    return !isPremium && completedNights == freeCompletedNights;
  }
}
