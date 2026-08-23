/// B3 — Hypothesis kinds derivable only from user evidence (not LLM-invented).
enum ReframeHypothesisKind {
  /// User named fear of how they appear / judgment / inadequacy (tepki, yetersiz).
  appearanceInTheirEyes,

  /// User tied tomorrow / meeting / presentation to staying awake (not bare "iş").
  tomorrowPressureReturn,

  /// User named missing trust felt when together (özlem + güven/onunlayken).
  trustWhenTogether,

  /// User named loneliness + wanting someone's presence (not thin standalone).
  lonelinessPresence,

  /// User named both longing and resentment in evidence window.
  mixedLongingResentment,

  /// User stated boss/patron trust concern explicitly.
  bossTrustAbsence,

  /// User wants to hear someone breathe / presence in silence (relational).
  presenceInSilence,
}
