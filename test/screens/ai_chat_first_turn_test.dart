import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/screens/ai_chat_screen.dart';

/// Task 16 — empty-chat first-turn UX.
///
/// Opening Chat must wait for the user. No automatic HCOS expression,
/// no fabricated greeting, no typing indicator before first send.
void main() {
  testWidgets('Chat opens empty, idle, and ready for user input', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AISleepChatScreen()));
    await tester.pump();

    // No fabricated opening assistant speech / greeting / filler.
    expect(find.textContaining('Good evening'), findsNothing);
    expect(find.textContaining('How are you'), findsNothing);
    expect(find.textContaining('Welcome'), findsNothing);
    expect(find.textContaining('I\'m here'), findsNothing);
    expect(find.textContaining('I am here'), findsNothing);

    // No typing indicator before the user sends.
    expect(find.text('…'), findsNothing);
    expect(find.text('hazırlanıyor…'), findsNothing);

    // Quiet-hold cue is for null expression after a turn — not on open.
    expect(find.text('·'), findsNothing);
    expect(
      find.textContaining('Nocta couldn’t reply'),
      findsNothing,
    );
    expect(find.textContaining('This build has no AI key'), findsNothing);

    // Input accepts the first message immediately.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isTrue);
    expect(find.text("What's on your mind tonight?"), findsOneWidget);

    // Message list is empty (only the input chrome is present).
    expect(find.byType(ListView), findsOneWidget);
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.childrenDelegate.estimatedChildCount ?? 0, 0);
  });

  testWidgets('empty submit does not start a turn (input stays idle)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AISleepChatScreen()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // Still no typing indicator / assistant speech after whitespace-only submit.
    expect(find.text('…'), findsNothing);
    expect(find.textContaining('Good evening'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });
}
