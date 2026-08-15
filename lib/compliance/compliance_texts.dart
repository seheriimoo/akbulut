/// SHIP / P0-3 compliance copy and hosted legal URL accessors.
///
/// In-app screens always show the full baseline body for App Review even when
/// public pages are not yet live. Hosted URLs must be published by the owner
/// before App Store Connect submission.
///
/// Optional overrides (dart-define / dart-define-from-file):
///   PRIVACY_POLICY_URL
///   TERMS_OF_SERVICE_URL
///
/// Does not belong to HCOS or billing.
class ComplianceTexts {
  ComplianceTexts._();

  /// Canonical intended public Privacy Policy URL for V1.
  static const String defaultPrivacyPolicyUrl =
      'https://seheriimoo.github.io/akbulut/privacy/';

  /// Canonical intended public Terms of Service URL for V1.
  static const String defaultTermsOfServiceUrl =
      'https://seheriimoo.github.io/akbulut/terms/';

  static const String _privacyOverride = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
  );
  static const String _termsOverride = String.fromEnvironment(
    'TERMS_OF_SERVICE_URL',
  );

  /// Resolved Privacy Policy URL (override if usable, else default).
  static String get privacyPolicyUrl {
    final override = _privacyOverride.trim();
    if (isUsableHostedLegalUrl(override)) return override;
    return defaultPrivacyPolicyUrl;
  }

  /// Resolved Terms of Service URL (override if usable, else default).
  static String get termsOfServiceUrl {
    final override = _termsOverride.trim();
    if (isUsableHostedLegalUrl(override)) return override;
    return defaultTermsOfServiceUrl;
  }

  /// True when [url] is a non-placeholder https URL suitable for ASC / paywall.
  static bool isUsableHostedLegalUrl(String url) {
    final value = url.trim();
    if (value.isEmpty) return false;
    final upper = value.toUpperCase();
    if (upper.startsWith('REPLACE_WITH_')) return false;
    if (upper.contains('EXAMPLE.COM')) return false;
    if (upper.contains('PLACEHOLDER')) return false;
    if (upper == 'TODO' || upper == 'YOUR_URL_HERE') return false;
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    if (uri.scheme != 'https') return false;
    if (uri.host.isEmpty) return false;
    if (uri.host == 'localhost' || uri.host.endsWith('.local')) return false;
    return true;
  }

  static const String nonClinicalDisclaimer =
      'Nocta is a nighttime companionship and sleep-transition experience. '
      'It is not a medical device, not clinical care, not therapy, and not a '
      'crisis or emergency service. If you are in danger or need urgent help, '
      'contact local emergency services or a crisis hotline.';

  static const String llmCloudDisclosure =
      'When you chat with Nocta, your messages are sent over the internet to a '
      'cloud language-model provider so Nocta can generate a reply. Do not share '
      'information you are not comfortable sending to a third-party AI service.';

  static const String privacyPolicyBody = '''
Privacy Policy (V1 baseline)

Last updated: 2026-08-13

STATUS: In-app baseline aligned with legal/site publish tree. Public HTTPS depends on owner enabling GitHub Pages (no custom domain) and running the deploy workflow.

Nocta (“we”, “us”) is operated by Seher Akbulut, an individual developer. Nocta provides a nighttime sleep-transition experience.

1. Information you provide
You may type messages during a night session. Those messages are processed to generate a reply and guide the sleep transition. Nocta V1 does not require creating an account or providing your name or email to use the core night path.

2. AI conversation content
Chat messages (and the compiled prompt material derived from the current turn) are transmitted to a third-party cloud language-model provider (OpenAI) over the internet so Nocta can generate a reply. Do not share information you are not comfortable sending to a third-party AI service. Short-term in-session conversation grounding is kept only for the active night and is not written into durable memory as dialogue.

3. Inferred information
On device, Nocta may derive temporary session signals (for example emotional/mental-pattern labels used to shape the night). A limited subset of pattern identifiers and related metadata may be stored locally to support cross-night continuity. Dialogue transcripts are not stored in that local continuity store.

4. Purchases and subscriptions
If you subscribe or buy premium access, purchase status is handled through Apple and our payments partner (RevenueCat). We do not store your full payment card details in the app. Apple may process payment identifiers under Apple’s policies.

5. Crash reports
If crash reporting is enabled for a build, technical crash diagnostics may be sent to Sentry. The app is configured to avoid sending payment secrets and to scrub likely conversation payloads from crash reports where feasible. Crash reporting may be disabled when no reporting endpoint is configured.

6. Device storage
The app may store local preferences and continuity data on your device using on-device storage (for example consent flags, session counters, last sleep-blocker hint, and pattern metadata). Uninstalling the app typically removes this on-device data.

7. Not for medical or crisis use
Nocta is not a medical service and is not intended for diagnosis, treatment, therapy, or emergency support. If you need urgent help, contact local emergency services or a crisis hotline.

8. How we use information
We use the information above to operate the night conversation, generate replies, unlock premium session length when purchased, keep basic local continuity, and maintain app stability.

9. Third parties
Depending on the feature used, processing may involve:
- OpenAI (cloud AI replies)
- Apple (App Store / In-App Purchase)
- RevenueCat (subscription entitlement status)
- Sentry (crash diagnostics, when configured)

Each provider processes data under its own terms and privacy policy.

10. Retention
On-device consent and continuity data remain until cleared by the user (for example by uninstall) or by a future in-app control. Cloud AI and payment providers retain data according to their own retention policies.

11. Your choices
You may decline consent screens and not use the chat features that require cloud AI. You may manage or cancel Apple subscriptions in your Apple ID subscription settings. For privacy requests related to Nocta, contact privacy@nocta.app. In-app deletion of Living Mind continuity data is not yet shipped in V1; uninstalling the app typically clears local app storage.

12. Age requirement and children
Nocta is intended only for users aged 18 and older. Nocta is not directed to children or minors and is not a children’s app. We do not knowingly collect personal information from anyone under 18.
If we become aware that personal information has been provided by a person under 18, contact privacy@nocta.app. We will take reasonable steps available to us, which may include deleting on-device continuity data associated with that use where we can identify it and guiding you to uninstall the app to clear local storage. We do not claim technical capabilities beyond what the current product supports.
This contractual minimum age (18+) is separate from Apple’s App Store age rating, which is chosen in App Store Connect.

13. International processing
Cloud providers may process data in the United States or other countries where they operate.

14. Changes
We may update this Privacy Policy. The “Last updated” date will change when we do. Material changes should also be reflected on the hosted Privacy Policy URL.

15. Contact
Operator: Seher Akbulut (individual developer).
Postal / business address: not published. A residential address is not listed.
privacy@nocta.app

This in-app policy matches the V1 hosted legal substance. Public URLs: https://seheriimoo.github.io/akbulut/privacy/ and https://seheriimoo.github.io/akbulut/terms/ (after owner enables GitHub Pages).
''';

  static const String termsOfServiceBody = '''
Terms of Service (V1 baseline)

Last updated: 2026-08-13

STATUS: In-app baseline aligned with legal/site publish tree. Public HTTPS depends on owner enabling GitHub Pages (no custom domain) and running the deploy workflow.

By using Nocta you agree to these Terms. Nocta is operated by Seher Akbulut, an individual developer.

1. The service
Nocta offers conversational nighttime companionship and an audio sleep-transition experience. Features may change as the product evolves. Nocta may be unavailable at times due to maintenance, network, or provider outages.

2. Eligibility and age requirement
You must be at least 18 years old to use Nocta. Nocta is not intended for children or minors. By using Nocta, you represent that you are 18 or older and able to enter a binding agreement under applicable law.
This contractual minimum age is separate from Apple’s App Store age rating, which is configured in App Store Connect and is not chosen by this draft.

3. Acceptable use
Do not misuse the service, attempt to disrupt it, reverse engineer it unlawfully, or use it for unlawful purposes. Do not attempt to bypass payment, consent, or safety controls.

4. AI-generated content
Replies may be generated by automated systems and can be imperfect, incomplete, or unsuitable. They are not professional, medical, legal, or therapeutic advice.

5. Health & safety / emergencies
Nocta is not medical care, therapy, diagnosis, or crisis support. If you are in danger or need urgent help, contact local emergency services or a crisis hotline. Do not rely on Nocta for emergency assistance.

6. Subscriptions & purchases
Paid features (when offered) are billed through Apple as In-App Purchases / auto-renewable subscriptions. Price and duration are shown in the paywall / App Store product page before purchase. Manage or cancel subscriptions in your Apple ID settings. Refunds follow Apple’s policies. Billing identity and payment method are handled by Apple; subscription status may also be verified through RevenueCat.

7. Apple’s Licensed Application End User License Agreement
If you download Nocta from the App Store, Apple’s Standard Licensed Application End User License Agreement (EULA) applies. Nocta V1 does not use a custom EULA. These Terms describe the Nocta service in addition to Apple’s Standard EULA.

8. Intellectual property
Nocta’s branding, software, audio beds, and related materials are owned by Seher Akbulut or licensors. You receive a limited, personal, non-transferable license to use the app as provided.

9. Disclaimer
The app is provided “as is” and “as available” without warranties of uninterrupted or error-free operation to the fullest extent permitted by law.

10. Limitation of liability
To the fullest extent permitted by law, Seher Akbulut is not liable for indirect, incidental, special, consequential, or punitive damages, or for loss of data or profits, arising from your use of the app. Nothing in these Terms limits or excludes any mandatory consumer rights that cannot be waived under the laws applicable to your country of residence.

11. Termination
We may suspend or discontinue access if these Terms are violated or if the service is discontinued. You may stop using Nocta at any time and may cancel paid subscriptions through Apple.

12. Governing law
These Terms are governed by the laws of the Republic of Türkiye, without choosing an exclusive court or city venue in this draft.
If you are a consumer, mandatory consumer rights available under the laws of your country of residence remain available and are not displaced by this governing-law statement to the extent such rights cannot be waived.

13. Contact
Operator: Seher Akbulut (individual developer).
Postal / business address: not published. A residential address is not listed.
support@nocta.app

This in-app Terms text matches the V1 hosted legal substance. Public URL: https://seheriimoo.github.io/akbulut/terms/ (after owner enables GitHub Pages).
''';
}
