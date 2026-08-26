/// Conversational discovery act selected by [DiscoveryPlanner].
///
/// Policy maps this to expression mode / flags. LLM realizes HOW only.
enum DiscoveryAct {
  /// No discovery override — existing HCOS arc owns the turn.
  deferToArc,

  /// First-turn meet (Receipt/Observe) — no question, no still-here sink.
  meet,

  /// Resolve ambiguity in one dimension.
  clarifyingQuestion,

  /// Split two competing hypotheses.
  discriminatingQuestion,

  /// Explore function / loop / utility.
  deepeningQuestion,

  /// Confirm leading mechanism with user language.
  confirmationQuestion,

  /// Brief grounded reflection then one objective question.
  reflectThenQuestion,

  /// Mechanism recognition (existing standard Recognition path).
  recognition,

  /// Post-recognition integrate-lite deepen (existing flag path).
  postRecognitionDeepen,

  /// End discovery; emit Sleep Mind Mirror.
  sleepMindMirror,

  /// Soft hold / no new probe (anti-interrogation).
  hold,
}
