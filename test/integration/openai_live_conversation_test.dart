import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:slowave/config/app_config.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/openai_vendor_provider.dart';

/// Integration Day 1 — real OpenAI turn on the live HcosLiveEntry path.
///
/// Run with:
///   flutter test --dart-define-from-file=config/secrets.local.json \
///     test/integration/openai_live_conversation_test.dart
///
/// Flutter's default test binding stubs HttpClient to HTTP 400; this suite
/// installs a real [HttpOverrides] for the live vendor call only.
void main() {
  test(
    'AppConfig → OpenAIVendorProvider → ConversationEngine → User utterance',
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final previousOverrides = HttpOverrides.current;
      HttpOverrides.global = _RealHttpOverrides();
      addTearDown(() {
        HttpOverrides.global = previousOverrides;
      });

      await AppConfig.load();

      expect(
        AppConfig.hasOpenAiApiKey,
        isTrue,
        reason:
            'OPENAI_API_KEY must be injected via --dart-define-from-file '
            '(config/secrets.local.json)',
      );

      // Same factory as AISleepChatScreen (Welcome→Consent→/ai-chat host).
      final orchestrator = HcosLiveEntry.createOrchestrator();
      final provider =
          orchestrator.conversationEngine.languageModelClient.vendorProvider;

      expect(
        provider,
        isA<OpenAIVendorProvider>(),
        reason: 'Live path must nest OpenAIVendorProvider behind LanguageModelClient',
      );
      expect(
        (provider! as OpenAIVendorProvider).apiKey.trim(),
        isNotEmpty,
        reason: 'AppConfig must seed dotenv before OpenAIVendorProvider.fromEnv',
      );

      // Probe wire auth before cognitive turn (status only; never log the key).
      final probe = await http.get(
        Uri.parse('https://api.openai.com/v1/models'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.openAiApiKey}',
        },
      );
      expect(
        probe.statusCode,
        200,
        reason:
            'OPENAI_API_KEY was injected but OpenAI returned HTTP '
            '${probe.statusCode}. Replace the key in config/secrets.local.json '
            'with a valid project key, then re-run.',
      );

      final mind = HcosLiveEntry.emptyMindModel();
      final session = HcosLiveEntry.openNightSession(mind);

      final result = await orchestrator.processTurn(
        message: "My mind won't settle tonight.",
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
      );

      expect(result.exitDecision, ExitDecision.continueConversation);
      expect(
        result.utterance,
        isNotNull,
        reason: 'ConversationEngine must return one OpenAI-backed utterance',
      );
      expect(result.utterance!.text.trim().isNotEmpty, isTrue);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // HttpClient() re-enters HttpOverrides; clear briefly to build a real client.
    HttpOverrides.global = null;
    try {
      return HttpClient(context: context);
    } finally {
      HttpOverrides.global = this;
    }
  }
}
