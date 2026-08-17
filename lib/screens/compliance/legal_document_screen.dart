import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../compliance/compliance_texts.dart';

enum LegalDocumentKind { privacyPolicy, termsOfService }

/// In-app Privacy Policy / Terms entry point.
///
/// Always shows the full baseline body. Hosted URL can be opened externally
/// when it is a usable https URL (not a placeholder stub).
class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentKind kind;

  const LegalDocumentScreen({super.key, required this.kind});

  String get _title => kind == LegalDocumentKind.privacyPolicy
      ? 'Privacy Policy'
      : 'Terms of Service';

  String get _body => kind == LegalDocumentKind.privacyPolicy
      ? ComplianceTexts.privacyPolicyBody
      : ComplianceTexts.termsOfServiceBody;

  String get _hostedUrl => kind == LegalDocumentKind.privacyPolicy
      ? ComplianceTexts.privacyPolicyUrl
      : ComplianceTexts.termsOfServiceUrl;

  bool get _hostedUrlUsable =>
      ComplianceTexts.isUsableHostedLegalUrl(_hostedUrl);

  Future<void> _openHosted(BuildContext context) async {
    if (!_hostedUrlUsable) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hosted legal URL is not configured yet.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final uri = Uri.parse(_hostedUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the hosted page.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copyHosted(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _hostedUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _title,
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 0.6,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Text(
                  _body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.45,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  Text(
                    'Hosted page: $_hostedUrl',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                  if (!_hostedUrlUsable)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Hosted URL looks like a placeholder — publish a live page before App Store submission.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => _openHosted(context),
                    child: Text(
                      'Open hosted $_title',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _copyHosted(context),
                    child: Text(
                      'Copy hosted $_title link',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
