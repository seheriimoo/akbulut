import 'night_mind_map.dart';
import 'night_pattern_id.dart';

/// Non-clinical Sleep Mind Mirror content (evidence-bound).
class SleepMindMirror {
  final String title;
  final String body;
  final NightPatternId pattern;
  final List<String> evidenceIds;
  final bool lowConfidence;

  const SleepMindMirror({
    required this.title,
    required this.body,
    required this.pattern,
    required this.evidenceIds,
    this.lowConfidence = false,
  });

  String get combined => '$title. $body';
}

/// Compiles a grounded mirror from [NightMindMap] — never diagnosis.
class SleepMindMirrorCompiler {
  const SleepMindMirrorCompiler();

  SleepMindMirror compile(
    NightMindMap map, {
    bool lowConfidence = false,
    bool preferTurkish = false,
  }) {
    // Never invent rehearsal/prep mirror for non-rehearsal leading patterns.
    final pattern = map.leadingPattern;
    final title = preferTurkish ? _titleTr(pattern) : _titleEn(pattern);
    final body = preferTurkish
        ? _bodyTr(map, pattern, lowConfidence: lowConfidence)
        : _bodyEn(map, pattern, lowConfidence: lowConfidence);
    return SleepMindMirror(
      title: title,
      body: body,
      pattern: pattern,
      evidenceIds: List.unmodifiable(map.evidenceIds),
      lowConfidence: lowConfidence,
    );
  }

  String _titleEn(NightPatternId pattern) {
    switch (pattern) {
      case NightPatternId.worstCaseRehearsal:
        return 'Rehearsing possibilities to feel prepared';
      case NightPatternId.preparationRehearsal:
        return 'Thinking as preparation';
      case NightPatternId.certaintyChase:
        return 'Chasing one more check';
      case NightPatternId.earlyTomorrowCarry:
        return 'Carrying tomorrow into tonight';
      case NightPatternId.protectiveHolding:
        return 'Holding watch so nothing is missed';
      case NightPatternId.unfinishedLoop:
        return 'An unfinished thread still open';
      case NightPatternId.relationalReplay:
        return 'Replaying an exchange';
      case NightPatternId.lonelinessPresence:
        return 'Absence keeping the night awake';
      case NightPatternId.bodyAlarm:
        return 'Body alarm still running';
      case NightPatternId.decisionPendulum:
        return 'Swinging between choices';
      case NightPatternId.unknown:
        return 'What your mind is doing tonight';
    }
  }

  String _titleTr(NightPatternId pattern) {
    switch (pattern) {
      case NightPatternId.worstCaseRehearsal:
        return 'Hazır hissetmek için ihtimalleri prova etmek';
      case NightPatternId.preparationRehearsal:
        return 'Düşünmeyi hazırlık gibi kullanmak';
      case NightPatternId.certaintyChase:
        return 'Bir kontrol daha peşinde olmak';
      case NightPatternId.earlyTomorrowCarry:
        return 'Yarını bu geceye taşımak';
      case NightPatternId.protectiveHolding:
        return 'Bir şey kaçmasın diye nöbette kalmak';
      case NightPatternId.unfinishedLoop:
        return 'Bitmemiş bir ipucu hâlâ açık';
      case NightPatternId.relationalReplay:
        return 'Bir konuşmayı yeniden oynamak';
      case NightPatternId.lonelinessPresence:
        return 'Eksiklik bu geceyi uyutmuyor';
      case NightPatternId.bodyAlarm:
        return 'Beden alarmı hâlâ çalışıyor';
      case NightPatternId.decisionPendulum:
        return 'İki seçenek arasında salınmak';
      case NightPatternId.unknown:
        return 'Zihninin bu gece ne yaptığı';
    }
  }

  String _bodyEn(
    NightMindMap map,
    NightPatternId pattern, {
    required bool lowConfidence,
  }) {
    final hedge = lowConfidence
        ? 'From what you\'ve shared so far, it may be that '
        : 'From what you\'ve described, ';
    switch (pattern) {
      case NightPatternId.worstCaseRehearsal:
      case NightPatternId.preparationRehearsal:
        return '$hedge'
            'your mind doesn\'t seem stuck on one single outcome. '
            '${map.thoughtForm != null ? 'It keeps generating possibilities. ' : ''}'
            '${map.perceivedUtility != null ? 'Thinking them through seems to promise preparedness. ' : ''}'
            '${map.actualEffect == 'perpetuates_new_scenarios' ? 'But each check seems to open another one. ' : ''}'
            'So what may be keeping you awake tonight isn\'t only the day ahead — '
            'it may be the sense that you need to be fully ready before you can let the night go.';
      case NightPatternId.certaintyChase:
        return '$hedge'
            'your mind may be chasing a little more certainty before it can rest. '
            'Each almost-finished check can quietly demand one more.';
      case NightPatternId.earlyTomorrowCarry:
        return '$hedge'
            'tomorrow seems to be arriving early — occupying the night before it begins.';
      case NightPatternId.protectiveHolding:
        return '$hedge'
            'part of you may be keeping watch, as if stopping would leave something uncovered.';
      case NightPatternId.lonelinessPresence:
        return '$hedge'
            'the absence of someone or something may be what stays loud when the day goes quiet.';
      case NightPatternId.bodyAlarm:
        return '$hedge'
            'your body may still be sounding an alarm, even when thoughts try to explain it.';
      case NightPatternId.relationalReplay:
        return '$hedge'
            'an exchange may still be replaying — words already said, and what they might mean.';
      case NightPatternId.unfinishedLoop:
        return '$hedge'
            'something unfinished may still be holding a door open in your mind.';
      case NightPatternId.decisionPendulum:
        return '$hedge'
            'your mind may be swinging between choices, as if picking one would close the night.';
      case NightPatternId.unknown:
        return '$hedge'
            'something about this night is still holding your attention. '
            'We can leave it gently named without forcing a label.';
    }
  }

  String _bodyTr(
    NightMindMap map,
    NightPatternId pattern, {
    required bool lowConfidence,
  }) {
    final hedge = lowConfidence
        ? 'Şimdiye kadar paylaştıklarından, belki '
        : 'Anlattıklarından, ';
    switch (pattern) {
      case NightPatternId.worstCaseRehearsal:
      case NightPatternId.preparationRehearsal:
        return '$hedge'
            'zihnin tek bir sonuca takılı kalmıyor gibi. '
            '${map.thoughtForm != null ? 'İhtimaller üretmeye devam ediyor. ' : ''}'
            '${map.perceivedUtility != null ? 'Bunları düşünmek hazırlıklı hissettirmeyi vadediyor. ' : ''}'
            '${map.actualEffect == 'perpetuates_new_scenarios' ? 'Ama her kontrol yeni bir senaryo daha açıyor. ' : ''}'
            'Bu gece uyutmayan şey yalnızca yarın olmayabilir — '
            'tamamen hazır olmadan geceyi bırakamamış gibi hissetmek olabilir.';
      case NightPatternId.certaintyChase:
        return '$hedge'
            'zihnin dinlenmeden önce biraz daha emin olmak istiyor olabilir. '
            'Neredeyse bitmiş her kontrol, sessizce bir tane daha isteyebilir.';
      case NightPatternId.earlyTomorrowCarry:
        return '$hedge'
            'yarın erken gelmiş gibi — gece daha başlamadan yer kaplıyor.';
      case NightPatternId.protectiveHolding:
        return '$hedge'
            'bir yanın nöbette kalıyor olabilir; durursan bir şeyin açıkta kalacağından korkuyormuş gibi.';
      case NightPatternId.lonelinessPresence:
        return '$hedge'
            'birinin ya da bir şeyin eksikliği, gün sessizleşince daha yüksek kalıyor olabilir.';
      case NightPatternId.bodyAlarm:
        return '$hedge'
            'bedenin hâlâ alarm veriyor olabilir; düşünceler bunu açıklamaya çalışsa bile.';
      case NightPatternId.relationalReplay:
        return '$hedge'
            'bir konuşma hâlâ yeniden oynuyor olabilir — söylenenler ve ne anlama gelebilecekleri.';
      case NightPatternId.unfinishedLoop:
        return '$hedge'
            'bitmemiş bir şey zihninde bir kapıyı açık tutuyor olabilir.';
      case NightPatternId.decisionPendulum:
        return '$hedge'
            'zihnin seçenekler arasında salınıyor olabilir; birini seçmek geceyi kapatacakmış gibi.';
      case NightPatternId.unknown:
        return '$hedge'
            'bu gece hâlâ bir şey dikkatini tutuyor. '
            'Zorla etiketlemeden, yumuşakça yanında durabiliriz.';
    }
  }
}
