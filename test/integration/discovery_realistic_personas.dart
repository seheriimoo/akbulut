/// Realistic follow-up scripts for discovery human-acceptance.
///
/// Do NOT use generic cross-pattern replies ("So I feel prepared",
/// "Hazırlıklı hissediyorum", "new scenario") on relational / loneliness /
/// unfinished openings — that contaminates the night into rehearsal.
library;

/// Pattern-true user continuations keyed by night id (C01–C14).
const Map<String, List<String>> discoveryRealisticFollowUps = {
  'C01': [
    // earlyTomorrowCarry — stay with tomorrow load
    "It's mostly tomorrow — I keep dragging it into tonight.",
    'Not one clean thought. Tomorrow just sits there.',
    'Still carrying tomorrow. Not ready to put it down.',
  ],
  'C02': [
    // already info-rich — usually ends at T1 Mirror
  ],
  'C03': [
    // preparation — deepen the loop if asked, stay on prep
    'I keep practicing the answers. It settles for a second, then I restart.',
    'Still rehearsing. Still not done.',
  ],
  'C04': [
    // certainty — usually T1 Mirror
  ],
  'C05': [
    // protective holding — stay on watch/slip
    "If I look away I feel like something will go wrong.",
    "I'm still watching it. I can't put it down.",
  ],
  'C06': [
    // loneliness — usually T1 Mirror
  ],
  'C07': [
    // relationalReplay TR — stay on fight/message/regret (NOT prep)
    'Mesajına bakıp duruyorum. Keşke o cümleyi geri alabilsem.',
    'Kavgayı baştan oynuyorum. Onarım yok gibi.',
    'Hâlâ aynı cümlede takılıyım.',
  ],
  'C08': [
    // unfinished → may shift to loneliness if user says so
    'Birinin yanında olmasını özlüyorum.',
  ],
  'C09': [
    // acute somatic — should NOT be treated as sleep Mirror fuel
    // (safety hold; no discovery follow-ups required)
  ],
  'C10': [
    // decision — if they pivot to loneliness, keep that
    'I just miss having someone here.',
    "I'm still stuck between texting and not.",
  ],
  'C11': [
    // TR prep rich — usually Mirror soon
    'Durmuyor. Her kontrol yeni bir ihtimal açıyor.',
  ],
  'C12': [
    // short tomorrow — stay on tomorrow, don't invent prep
    'Yarın aklımdan çıkmıyor.',
    'Tek bir şey değil ama yarın hep orada.',
    'Hâlâ yarını taşıyorum.',
  ],
  'C13': [
    // ambiguous what-if — if asked about utility, stay soft
    'I keep imagining it falling apart.',
    "I don't feel prepared. I feel scared it'll go wrong.",
  ],
  'C14': [
    // loneliness TR — stay with alone/miss
    'Yanımda kimse yok. Sessizlik ağır.',
    'Hâlâ yalnızım. Birinin olması lazım gibi.',
  ],
};

/// Banned harness phrases that hijack non-rehearsal nights into prep/rehearsal.
const List<String> discoveryHarnessBannedOnNonRehearsal = [
  'hazırlıklı hissediyorum',
  'so i feel prepared',
  'yeni bir senaryo',
  'each check creates another',
  'her seferinde yeni bir senaryo',
];
