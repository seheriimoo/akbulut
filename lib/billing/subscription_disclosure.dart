/// App Store Guideline 3.1.2 subscription copy for the live paywall.
///
/// Prices and product titles still come from the store. This is the
/// auto-renew / legal footer that must sit near purchase.
/// Does not belong to HCOS or Conversation.
class SubscriptionDisclosure {
  const SubscriptionDisclosure._();

  /// Auto-renewing subscription terms shown near the buy control.
  static const String autoRenewTerms =
      'Payment is charged to your Apple ID at confirmation of purchase. '
      'Subscription automatically renews unless canceled at least 24 hours '
      'before the end of the current period. Your account is charged for '
      'renewal within 24 hours prior to the end of the current period. '
      'Manage subscriptions and turn off auto-renewal in Account Settings '
      'after purchase.';

  static const String privacyLinkLabel = 'Privacy Policy';
  static const String termsLinkLabel = 'Terms of Service';
}
