import 'dart:async';

import 'package:flutter/material.dart';
import '../billing/premium_product_access.dart';
import '../billing/sleep_bed_catalog.dart';
import '../core/brain/cognitive_orchestrator.dart';
import '../core/brain/cognitive_turn_result.dart';
import '../core/brain/exit_decision.dart';
import '../core/brain/hcos_live_entry.dart';
import '../core/brain/living_mind_model.dart';
import '../core/brain/living_mind_store.dart';
import '../core/brain/night_audio_handoff.dart';
import '../core/brain/night_session.dart';
import '../features/player/player_screen.dart';
import 'night_complete_screen.dart';
import 'paywall_screen.dart';

class AISleepChatScreen extends StatefulWidget {
  const AISleepChatScreen({super.key});

  @override
  State<AISleepChatScreen> createState() => _AISleepChatScreenState();
}

class _AISleepChatScreenState extends State<AISleepChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final LivingMindStore _mindStore = const LivingMindStore();
  final NightAudioHandoff _audioHandoff = const NightAudioHandoff();
  final SleepBedCatalog _sleepBeds = const SleepBedCatalog();

  /// Sole production cognitive entry (Sprint 6 Cutover).
  late final CognitiveOrchestrator _orchestrator;

  /// Durable mind host for session-end write only (not mutated mid-turn).
  late LivingMindModel _mindModel;

  /// Temporary NightSession carried across turns (app shell lifecycle host).
  /// WorkingMindView is read only from this session.
  NightSession? _session;

  /// Sole production turn result returned to the app (Sprint 6 Gap #2).
  CognitiveTurnResult? _lastTurnResult;

  /// Last night's blocker hint for continuity when this night is thin.
  String? _lastBlockerHint;

  bool isTyping = false;
  bool isLoadingAudio = false;

  /// True when Player returned load-failure; stay on chat and offer retry.
  /// Does not invent dialogue. Does not close the NightSession.
  bool _audioHandoffFailed = false;

  /// True when user left Player early (pop null); stay on chat and offer continue.
  /// Not an error. Does not invent dialogue. Does not close the NightSession.
  bool _audioContinueAvailable = false;

  /// Visible idle cue when expression returned no utterance (null / Guard reject)
  /// while conversation may continue. Not assistant speech. Not invented dialogue.
  bool _expressionQuiet = false;

  /// Blocks re-entrant send while a turn is already accepted.
  bool _sendInFlight = false;

  /// Ensures paywall/Player handoff starts at most once per transition.
  bool _audioFlowRunning = false;

  bool get _acceptsUserInput {
    if (_sendInFlight || isTyping || isLoadingAudio) return false;
    if (_audioFlowRunning) return false;
    if (_audioContinueAvailable) return false;
    if (_session == null) return false;
    final exit = _lastTurnResult?.exitDecision;
    if (exit == null) return true;
    // After load-fail, reopen free text despite transition exit still standing.
    if (exit == ExitDecision.transitionToAudio) {
      return _audioHandoffFailed;
    }
    if (exit == ExitDecision.silence) return false;
    return exit == ExitDecision.continueConversation;
  }

  void _dismissKeyboardAndClearDraft() {
    _inputFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    _controller.clear();
  }

  /// Same-language mirror for chrome CTAs (EN/TR). Not a localization system.
  String get _continueAudioLabel {
    final recentUser = _messages
        .where((m) => m.isUser)
        .map((m) => m.text)
        .join(' ')
        .toLowerCase();
    if (RegExp(r'[ğüşıöç]').hasMatch(recentUser) ||
        recentUser.contains('gece') ||
        recentUser.contains('yalnız') ||
        recentUser.contains('zorunda') ||
        recentUser.contains('belki')) {
      return 'Sese devam et';
    }
    return 'Continue to audio';
  }

  @override
  void initState() {
    super.initState();

    // Open a clean NightSession host only. Do not call processTurn, do not
    // invent an opening assistant utterance, and do not show typing.
    // The first HCOS turn begins only after the user submits a non-empty message.
    _orchestrator = HcosLiveEntry.createOrchestrator();
    _mindModel = HcosLiveEntry.emptyMindModel();
    _session = HcosLiveEntry.openNightSession(_mindModel);
    unawaited(_bootstrapMindContinuity());
  }

  Future<void> _bootstrapMindContinuity() async {
    final sessions = await _mindStore.loadTotalSessions();
    final blocker = await _mindStore.loadLastBlocker();
    final mental = await _mindStore.loadMentalPatterns();
    final emotional = await _mindStore.loadEmotionalPatterns();
    if (!mounted) return;
    setState(() {
      _lastBlockerHint = blocker;
      _mindModel = _mindModel.copyWith(
        identity: _mindModel.identity.copyWith(
          totalSessions: sessions > 0
              ? sessions
              : _mindModel.identity.totalSessions,
        ),
        mentalPatterns:
            mental.isEmpty ? _mindModel.mentalPatterns : mental,
        emotionalPatterns:
            emotional.isEmpty ? _mindModel.emotionalPatterns : emotional,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_acceptsUserInput) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Accept once: lock before any await so rapid double-submit cannot fork.
    _sendInFlight = true;
    _inputFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    _controller.clear();

    setState(() {
      _expressionQuiet = false;
      _messages.add(_ChatMessage(text: text, isUser: true));
    });

    _scrollToBottom();
    try {
      await _generateAIResponse(text);
    } finally {
      if (mounted) {
        setState(() => _sendInFlight = false);
      } else {
        _sendInFlight = false;
      }
    }
  }

  Future<void> _generateAIResponse(String userInput) async {
    if (!mounted) return;

    final session = _session;
    if (session == null) return;

    setState(() {
      isTyping = true;
      _expressionQuiet = false;
    });

    try {
      // Sole production turn result: CognitiveTurnResult.
      // Typing is shown only while processTurn is in flight (no artificial wait).
      // WorkingMindView comes only from the carried NightSession.
      // Grounding buffer is rehydrated from the prior turn result (session host).
      // No AIService / NoctaAIBrain / ReasoningEngine in the live path.
      final priorGrounding = _lastTurnResult == null
          ? null
          : HcosLiveEntry.groundingBufferOf(_lastTurnResult!);
      final CognitiveTurnResult result = await _orchestrator.processTurn(
        message: userInput,
        session: session,
        workingMind: HcosLiveEntry.workingMindOf(session),
        conversationGroundingBuffer: priorGrounding,
      );

      // Mid-session NightSession updates come only from CognitiveTurnResult.
      _session = HcosLiveEntry.applyTurnResult(result);
      _lastTurnResult = result;

      if (!mounted) return;

      final reply = result.utterance?.text;
      final hasExpression = reply != null && reply.isNotEmpty;

      // Lock conversation chrome the instant Exit is definitive.
      if (result.exitDecision == ExitDecision.transitionToAudio ||
          result.exitDecision == ExitDecision.silence) {
        _dismissKeyboardAndClearDraft();
      }

      // Hide typing immediately on completion / null / Guard reject.
      // No fabricated assistant speech.
      setState(() {
        isTyping = false;
        _expressionQuiet = !hasExpression &&
            result.exitDecision == ExitDecision.continueConversation;
        if (result.exitDecision == ExitDecision.transitionToAudio) {
          isLoadingAudio = true;
          _audioHandoffFailed = false;
          _audioContinueAvailable = false;
        }
      });

      if (hasExpression) {
        await _addAIMessage(reply);
      }

      // Production exit cutover: ExitDecision from CognitiveTurnResult only.
      // completeNightSession runs after audio (or immediately on silence).
      // Exit flows proceed even when expression was null (no filler speech).
      switch (result.exitDecision) {
        case ExitDecision.continueConversation:
          break;
        case ExitDecision.transitionToAudio:
          if (hasExpression) {
            await Future<void>.delayed(const Duration(milliseconds: 1600));
            if (!mounted) return;
          }
          await _startAudioFlow();
          break;
        case ExitDecision.silence:
          await _finishNightAndShowClosing();
          break;
      }
    } catch (_) {
      // Fail closed in UI: never crash, never invent assistant speech.
      if (!mounted) return;
      setState(() {
        isTyping = false;
        _expressionQuiet = _session != null;
      });
    }
  }

  Future<void> _addAIMessage(String text) async {
    if (!mounted) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: false));
    });

    _scrollToBottom();
  }

  Future<void> _startAudioFlow() async {
    if (!mounted) return;
    // Single-flight: ignore re-entrant calls from double submit / double CTA.
    if (_audioFlowRunning) return;
    _audioFlowRunning = true;

    setState(() {
      isLoadingAudio = true;
      _audioHandoffFailed = false;
      _audioContinueAvailable = false;
    });
    _dismissKeyboardAndClearDraft();

    // Premium is offered at the live Conversation → Audio boundary.
    // Entitlement ownership stays in BillingService; HCOS is unchanged.
    var access = await PremiumProductAccess.resolve();
    if (!access.isPremium && mounted) {
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      if (!mounted) return;
      access = await PremiumProductAccess.resolve();
    }

    if (!mounted) return;

    final session = _session;
    final blocker = session == null
        ? (_lastBlockerHint ?? 'mind')
        : _audioHandoff.blockerFor(
            session: session,
            grounding: _lastTurnResult?.conversationGroundingBuffer,
          );
    final bedAsset = _sleepBeds.assetFor(blocker: blocker, access: access);

    // Presentation-only player handoff. Not HCOS cognition.
    // NightSession stays open until audio ends → completeNightSession.
    // Player return contract:
    //   true  → bed completed naturally → close night
    //   false → bed load/play failed → stay on chat + retry
    //   null  → user left player early → stay on chat + continue CTA
    final playerOk = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          goal: 'sleep',
          blocker: blocker,
          sleepLatency: _sleepBeds.sleepLatencyFor(blocker),
          energy: _sleepBeds.energyFor(blocker),
          sessionLength: access.sessionLength,
          audioAssetPath: bedAsset,
          premiumUnlocked: access.isPremium,
        ),
      ),
    );

    if (!mounted) return;

    _lastBlockerHint = blocker;

    if (playerOk == false) {
      // Do not auto-complete the night on audio failure.
      _audioFlowRunning = false;
      setState(() {
        isLoadingAudio = false;
        _audioHandoffFailed = true;
        _audioContinueAvailable = false;
        _expressionQuiet = false;
      });
      return;
    }

    if (playerOk == null) {
      // Early leave is not failure and not night completion.
      _audioFlowRunning = false;
      setState(() {
        isLoadingAudio = false;
        _audioHandoffFailed = false;
        _audioContinueAvailable = true;
        _expressionQuiet = false;
      });
      return;
    }

    await _finishNightAndShowClosing(blockerHint: blocker);
  }

  Future<void> _retryAudioHandoff() async {
    if (!mounted || isLoadingAudio || _audioFlowRunning) return;
    if (_lastTurnResult?.exitDecision != ExitDecision.transitionToAudio) {
      return;
    }
    setState(() {
      _audioHandoffFailed = false;
      _audioContinueAvailable = false;
    });
    await _startAudioFlow();
  }

  /// Re-opens the same handoff bed after an intentional early Player leave.
  Future<void> _continueAudioHandoff() async {
    if (!mounted || isLoadingAudio || _audioFlowRunning) return;
    if (_lastTurnResult?.exitDecision != ExitDecision.transitionToAudio) {
      return;
    }
    if (_session == null) return;
    setState(() {
      _audioContinueAvailable = false;
      _audioHandoffFailed = false;
    });
    await _startAudioFlow();
  }

  /// Ends the temporary NightSession through the canonical session-end path.
  /// Discards the session afterward. Does not mutate WorkingMindView ad hoc.
  Future<void> _closeNightSession({String? blockerHint}) async {
    final session = _session;
    if (session == null) return;

    _mindModel = HcosLiveEntry.completeNightSession(
      orchestrator: _orchestrator,
      session: session,
      model: _mindModel,
    );
    _session = null;

    await _mindStore.saveAfterNight(
      totalSessions: _mindModel.identity.totalSessions,
      blocker: blockerHint ?? _lastBlockerHint ?? 'mind',
      mentalPatterns: _mindModel.mentalPatterns,
      emotionalPatterns: _mindModel.emotionalPatterns,
    );
  }

  /// Canonical MemoryEngine write, then calm closing presentation.
  Future<void> _finishNightAndShowClosing({String? blockerHint}) async {
    await _closeNightSession(blockerHint: blockerHint);

    if (!mounted) return;

    setState(() => isLoadingAudio = false);

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const NightCompleteScreen()),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02030A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Nocta",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              itemCount: _messages.length +
                  (isTyping ? 1 : 0) +
                  (_expressionQuiet && !isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (isTyping && index == _messages.length) {
                  return const _TypingBubble();
                }

                if (_expressionQuiet &&
                    !isTyping &&
                    index == _messages.length) {
                  return const _QuietHoldCue();
                }

                final message = _messages[index];

                if (!message.isUser) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.7,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }

                return _MessageBubble(message: message);
              },
            ),
          ),
          if (isLoadingAudio) const _AudioPreparingCue(),
          if (_audioHandoffFailed && !isLoadingAudio)
            _AudioRetryCue(onRetry: _retryAudioHandoff),
          if (_audioContinueAvailable &&
              !_audioHandoffFailed &&
              !isLoadingAudio)
            _AudioContinueCue(
              label: _continueAudioLabel,
              onContinue: _continueAudioHandoff,
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _inputFocus,
                  enabled: _acceptsUserInput,
                  readOnly: !_acceptsUserInput,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "What's on your mind tonight?",
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) {
                    if (_acceptsUserInput) {
                      unawaited(_handleSend());
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _acceptsUserInput ? _handleSend : null,
              icon: Icon(
                Icons.arrow_upward_rounded,
                color: _acceptsUserInput ? Colors.white70 : Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.white.withOpacity(0.07)
              : Colors.white.withOpacity(0.05),

          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isUser ? 22 : 10),
            bottomRight: Radius.circular(isUser ? 10 : 22),
          ),

          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),

        child: Text(
          message.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.55,
          ),
        ),
      ),
    );
  }
}

/// In-flight expression cue only. Not assistant speech. Not invented dialogue.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '…',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 16,
            height: 1.2,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

/// Minimal non-conversational chrome when expression is absent.
/// Not an assistant reply. Not invented dialogue.
class _QuietHoldCue extends StatelessWidget {
  const _QuietHoldCue();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          '·',
          style: TextStyle(
            color: Colors.white24,
            fontSize: 14,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Soft prep cue while paywall/player handoff is in flight.
/// Not assistant speech. Matches Nocta quiet chrome language.
class _AudioPreparingCue extends StatelessWidget {
  const _AudioPreparingCue();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
        child: Text(
          'Preparing a little quiet…',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 14,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

/// Shown only after Player load/play failure. Offers retry without closing night.
class _AudioRetryCue extends StatelessWidget {
  const _AudioRetryCue({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
        child: Column(
          children: [
            Text(
              'This quiet session could not start.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 14,
                fontWeight: FontWeight.w300,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => unawaited(onRetry()),
              child: Container(
                width: double.infinity,
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
                  'Tekrar dene',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown after intentional early Player leave. Not an error. Not assistant speech.
class _AudioContinueCue extends StatelessWidget {
  const _AudioContinueCue({
    required this.label,
    required this.onContinue,
  });

  final String label;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
        child: GestureDetector(
          onTap: () => unawaited(onContinue()),
          child: Container(
            width: double.infinity,
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
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 14,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
