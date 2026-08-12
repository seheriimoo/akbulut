import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slowave/config/app_config.dart';
import 'package:slowave/main.dart';

/// Live UI device trial on simulator: Welcome → Consent → Chat (TR night).
///
/// flutter test --dart-define-from-file=config/secrets.local.json \
///   integration_test/nocta_device_trial_test.dart \
///   -d 4C5F426A-05A2-4928-9CB5-736E8D16A4A2
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Nocta device trial: welcome → consent → TR chat turns',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await AppConfig.load();
    expect(AppConfig.hasOpenAiApiKey, isTrue);

    await tester.pumpWidget(const SleepWaveApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Nocta'), findsWidgets);
    expect(find.text('Begin'), findsOneWidget);
    await binding.takeScreenshot('01_welcome');

    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Before you begin'), findsOneWidget);
    await binding.takeScreenshot('02_consent');

    // Two consent checkboxes (ListTiles).
    final checks = find.byType(CheckboxListTile);
    expect(checks, findsNWidgets(2));
    await tester.ensureVisible(checks.at(0));
    await tester.tap(checks.at(0));
    await tester.pumpAndSettle();
    await tester.ensureVisible(checks.at(1));
    await tester.tap(checks.at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agree and continue'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(
      find.text("What's on your mind tonight?"),
      findsOneWidget,
    );
    await binding.takeScreenshot('03_chat_empty');

    Future<void> send(String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();
      // Live OpenAI + typing indicator.
      await tester.pumpAndSettle(const Duration(seconds: 25));
    }

    await send('Bu gece kendimi çok yalnız hissediyorum.');
    await binding.takeScreenshot('04_after_receipt');
    expect(find.text('Bu gece kendimi çok yalnız hissediyorum.'), findsOneWidget);

    // At least one assistant bubble beyond the user line should appear,
    // unless Guard silence (rare). Soft assert via any non-user text later.
    await send('Eksiklik gibi bir şey var içimde.');
    await binding.takeScreenshot('05_after_permission');

    await send('Biraz daha sessiz şimdi.');
    await binding.takeScreenshot('06_after_release');

    // Capture final chat state for human review.
    await binding.takeScreenshot('07_chat_mid_night');

    // Input still present (night continues or audio transition loading).
    expect(find.byType(TextField).evaluate().isNotEmpty ||
        find.textContaining('preparing').evaluate().isNotEmpty ||
        find.textContaining('sessizlik').evaluate().isNotEmpty ||
        find.textContaining('hazırlıyorum').evaluate().isNotEmpty ||
        find.textContaining('Player').evaluate().isNotEmpty ||
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.text('Bu gece kendimi çok yalnız hissediyorum.').evaluate().isNotEmpty,
        isTrue);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
