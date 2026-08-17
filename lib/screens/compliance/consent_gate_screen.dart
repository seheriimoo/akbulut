import 'package:flutter/material.dart';

import '../../compliance/compliance_texts.dart';
import '../../compliance/consent_store.dart';
import '../night_gate.dart';
import 'legal_document_screen.dart';

/// First-run LLM disclosure + non-clinical disclaimer + legal acceptance.
class ConsentGateScreen extends StatefulWidget {
  const ConsentGateScreen({super.key});

  @override
  State<ConsentGateScreen> createState() => _ConsentGateScreenState();
}

class _ConsentGateScreenState extends State<ConsentGateScreen> {
  bool _acceptedLlm = false;
  bool _acceptedDisclaimer = false;
  bool _submitting = false;

  bool get _canContinue => _acceptedLlm && _acceptedDisclaimer && !_submitting;

  Future<void> _continue() async {
    if (!_canContinue) return;
    setState(() => _submitting = true);
    await ConsentStore.acceptBaseline();
    if (!mounted) return;
    final allowed = await ensureNightConversationAllowed(context);
    if (!mounted) return;
    if (!allowed) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      return;
    }
    Navigator.pushReplacementNamed(context, '/ai-chat');
  }

  void _openLegal(LegalDocumentKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(kind: kind),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              Text(
                'Before you begin',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please review these notices. Nocta cannot start a night session until you agree.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _NoticeCard(
                        title: 'Not clinical care',
                        body: ComplianceTexts.nonClinicalDisclaimer,
                      ),
                      const SizedBox(height: 12),
                      _NoticeCard(
                        title: 'Cloud AI processing',
                        body: ComplianceTexts.llmCloudDisclosure,
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        value: _acceptedDisclaimer,
                        onChanged: (value) {
                          setState(() => _acceptedDisclaimer = value ?? false);
                        },
                        activeColor: Colors.white24,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'I understand Nocta is not medical, therapy, or crisis care.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                      CheckboxListTile(
                        value: _acceptedLlm,
                        onChanged: (value) {
                          setState(() => _acceptedLlm = value ?? false);
                        },
                        activeColor: Colors.white24,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'I agree that my chat messages may be sent to a cloud AI provider to generate replies.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        children: [
                          TextButton(
                            onPressed: () =>
                                _openLegal(LegalDocumentKind.privacyPolicy),
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                _openLegal(LegalDocumentKind.termsOfService),
                            child: Text(
                              'Terms of Service',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Opacity(
                opacity: _canContinue ? 1 : 0.4,
                child: GestureDetector(
                  onTap: _canContinue ? _continue : null,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      _submitting ? 'Saving…' : 'Agree and continue',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        letterSpacing: 0.8,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final String title;
  final String body;

  const _NoticeCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
