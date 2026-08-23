/// Fixed V1 conversation-quality scenario fixtures (Step 1).
///
/// Structural harness inputs only. Not Evaluator scores. Not Human Gold.
library;

/// One fixed user-night script for structural validation.
class V1ScenarioFixture {
  final String id;
  final String title;
  final List<String> userTurns;

  /// If true, vendor returns Guard-rejected language (null emission expected).
  final bool forceGuardReject;

  /// If true, after the script Exit must authorize audio at least once.
  final bool requireAudioTransitionByEnd;

  /// If true, Exit must never authorize audio during the script.
  final bool forbidAudioTransition;

  const V1ScenarioFixture({
    required this.id,
    required this.title,
    required this.userTurns,
    this.forceGuardReject = false,
    this.requireAudioTransitionByEnd = false,
    this.forbidAudioTransition = false,
  });
}

/// Canonical Step 1 set: S01–S20.
const List<V1ScenarioFixture> v1ScenarioFixtures = [
  V1ScenarioFixture(
    id: 'S01',
    title: 'Overthinking — looping thoughts',
    userTurns: [
      'I keep replaying everything I still have to figure out for tomorrow. My mind will not settle.',
      'It is the same loops over and over. I cannot get them to stop.',
      'I am still thinking about all of it.',
    ],
  ),
  V1ScenarioFixture(
    id: 'S02',
    title: 'Overthinking — short cannot stop thinking',
    userTurns: [
      'I cannot stop thinking.',
    ],
  ),
  V1ScenarioFixture(
    id: 'S03',
    title: 'Future anxiety — tomorrow dread',
    userTurns: [
      'Tomorrow already feels heavy. What if it all goes wrong?',
      'I keep thinking about what if I mess everything up.',
    ],
  ),
  V1ScenarioFixture(
    id: 'S04',
    title: 'Future anxiety — diffuse worst-case thinking',
    userTurns: [
      'What if everything falls apart and I cannot fix it?',
      "My mind won't stop running through the worst versions.",
    ],
  ),
  V1ScenarioFixture(
    id: 'S05',
    title: 'Work stress — unfinished work/deadline',
    userTurns: [
      'I still have so much unfinished work before the deadline.',
      'I keep thinking about the tasks I did not finish.',
    ],
  ),
  V1ScenarioFixture(
    id: 'S06',
    title: 'Money stress — bills/scarcity loop',
    userTurns: [
      'The bills keep looping in my head.',
      "I cannot stop thinking about money and what if it is not enough.",
    ],
  ),
  V1ScenarioFixture(
    id: 'S07',
    title: 'Relationship distress — conflict residue',
    userTurns: [
      'We argued again and it is still sitting with me.',
      'I keep replaying what was said.',
    ],
  ),
  V1ScenarioFixture(
    id: 'S08',
    title: 'Missing someone — relational longing',
    userTurns: [
      'I miss them tonight.',
      'The quiet just makes it louder.',
    ],
  ),
  V1ScenarioFixture(
    id: 'S09',
    title: 'Loneliness',
    userTurns: [
      'I feel alone in this room.',
      'No one is here and it feels heavy.',
    ],
  ),
  V1ScenarioFixture(
    id: 'S10',
    title: 'Emotional pain without clear story',
    userTurns: [
      'It just hurts tonight.',
      'I do not even know how to explain it.',
    ],
  ),
  V1ScenarioFixture(
    id: 'S11',
    title: 'Ambiguous short message',
    userTurns: [
      'idk',
      'tired',
    ],
  ),
  V1ScenarioFixture(
    id: 'S12',
    title: 'Ambiguous fragment',
    userTurns: [
      'ugh',
    ],
  ),
  V1ScenarioFixture(
    id: 'S13',
    title: 'Topic change: work → relationship',
    userTurns: [
      'Work is still in my head.',
      'Actually it is us. The fight will not leave me alone.',
    ],
  ),
  V1ScenarioFixture(
    id: 'S14',
    title: 'Topic change late: emotional arc → money',
    userTurns: [
      'I feel raw after everything today.',
      'Something is still holding on.',
      'Now the money stress is back too.',
    ],
  ),
  V1ScenarioFixture(
    id: 'S15',
    title: 'Full multi-turn mental-load night',
    userTurns: [
      'I keep replaying tomorrow. My mind will not settle.',
      'Same loops. I cannot get them to stop.',
      'I am still thinking.',
      'It is quieter but not gone.',
      'I can let this rest for now.',
    ],
  ),
  V1ScenarioFixture(
    id: 'S16',
    title: 'Compressed relational-absence night',
    userTurns: [
      'I miss them.',
      'That is enough for tonight.',
    ],
  ),
  V1ScenarioFixture(
    id: 'S17',
    title: 'Correct sleep-transition timing',
    // Calm turns advance Release ladder to transitionReady → audio.
    userTurns: [
      'I am here.',
      'Still here.',
      'A little quieter.',
      'Softening.',
      'Ready to rest.',
    ],
    requireAudioTransitionByEnd: true,
  ),
  V1ScenarioFixture(
    id: 'S18',
    title: 'High activation — must not transition too early',
    // Perception: "thinking" + "what if" / "mind won't stop" → high activation.
    userTurns: [
      'I am thinking and what if it all collapses tonight.',
      "My mind won't stop and I keep thinking what if I fail.",
      'Still thinking - what if tomorrow is worse.',
    ],
    forbidAudioTransition: true,
  ),
  V1ScenarioFixture(
    id: 'S19',
    title: 'Multi-turn grounding continuity',
    userTurns: [
      'first grounding line about the day',
      'second grounding line still awake',
      'third grounding line current turn',
      'fourth grounding line should drop the oldest',
    ],
  ),
  V1ScenarioFixture(
    id: 'S20',
    title: 'Guard reject — safe fallback, never rejected text',
    userTurns: [
      'I keep replaying everything for tomorrow.',
    ],
    forceGuardReject: true,
  ),
];