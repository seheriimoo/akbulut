class SleepAIResult {
  final String category;
  final String reply;
  final String sessionTitle;
  final bool shouldCloseChat;

  const SleepAIResult({
    required this.category,
    required this.reply,
    required this.sessionTitle,
    required this.shouldCloseChat,
  });
}

class SleepSpecialistEngine {
  static SleepAIResult process({
    required String userText,
    required int userMessageCount,
    String? previousCategory,
    String language = 'en',
  }) {
    final isTR = language == 'tr';

    String category = 'unknown';// basit tutuyoruz şimdilik

    String reply;

    if (userMessageCount <= 1) {
      reply = isTR
          ? 'Zihnin biraz aktif görünüyor. Bu daha çok sürekli düşünceler mi yoksa tek bir konuya takılma mı?'
          : 'Your mind feels active. Is it nonstop thoughts or one thing looping?';
    } else {
      reply = isTR
          ? 'Tamam, şimdi seni uykuya geçirelim.'
          : 'Alright, let’s guide you into sleep now.';
    }

    return SleepAIResult(
      category: category,
      reply: reply,
      sessionTitle: 'Gentle Sleep Entry',
      shouldCloseChat: userMessageCount >= 2,
    );
  }
}