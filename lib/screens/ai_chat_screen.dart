import 'package:flutter/material.dart';
import '../billing/premium_product_access.dart';
import '../core/brain/cognitive_orchestrator.dart';
import '../core/brain/cognitive_turn_result.dart';
import '../core/brain/exit_decision.dart';
import '../core/brain/hcos_live_entry.dart';
import '../core/brain/living_mind_model.dart';
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
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  /// Sole production cognitive entry (Sprint 6 Cutover).
  late final CognitiveOrchestrator _orchestrator;

  /// Durable mind host for session-end write only (not mutated mid-turn).
  late LivingMindModel _mindModel;

  /// Temporary NightSession carried across turns (app shell lifecycle host).
  /// WorkingMindView is read only from this session.
  NightSession? _session;

  /// Sole production turn result returned to the app (Sprint 6 Gap #2).
  CognitiveTurnResult? _lastTurnResult;

  bool isTyping = false;
  bool isLoadingAudio = false;

  bool get _acceptsUserInput {
    if (isTyping || isLoadingAudio) return false;
    if (_session == null) return false;
    final exit = _lastTurnResult?.exitDecision;
    if (exit == null) return true;
    return exit == ExitDecision.continueConversation;
  }

  @override
  void initState() {
    super.initState();

    _orchestrator = HcosLiveEntry.createOrchestrator();
    _mindModel = HcosLiveEntry.emptyMindModel();
    _session = HcosLiveEntry.openNightSession(_mindModel);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendInitialMessage();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendInitialMessage() async {
    if (!mounted) return;

    setState(() {
      _messages.add(
        const _ChatMessage(
          text:
              "I'm here to understand what your mind is carrying tonight.\n\nWhenever you're ready, tell me what's on your mind.",
          isUser: false,
        ),
      );
    });

    _scrollToBottom();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !_acceptsUserInput) return;

    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });

    _scrollToBottom();
    await _generateAIResponse(text);
  }

  Future<void> _generateAIResponse(String userInput) async {
    if (!mounted) return;

    final session = _session;
    if (session == null) return;

    setState(() => isTyping = true);

    await Future.delayed(const Duration(milliseconds: 900));

    // Sole production turn result: CognitiveTurnResult.
    // WorkingMindView comes only from the carried NightSession.
    // No AIService / NoctaAIBrain / ReasoningEngine in the live path.
    final CognitiveTurnResult result = await _orchestrator.processTurn(
      message: userInput,
      session: session,
      workingMind: HcosLiveEntry.workingMindOf(session),
    );

    // Mid-session NightSession updates come only from CognitiveTurnResult.
    _session = HcosLiveEntry.applyTurnResult(result);
    _lastTurnResult = result;

    if (!mounted) return;

    setState(() => isTyping = false);

    final reply = result.utterance?.text;
    if (reply != null && reply.isNotEmpty) {
      await _addAIMessage(reply);
    }

    // Production exit cutover: ExitDecision from CognitiveTurnResult only.
    // completeNightSession runs after audio (or immediately on silence).
    switch (result.exitDecision) {
      case ExitDecision.continueConversation:
        break;
      case ExitDecision.transitionToAudio:
        await _startAudioFlow();
        break;
      case ExitDecision.silence:
        await _finishNightAndShowClosing();
        break;
    }
  }

  /// Ends the temporary NightSession through the canonical session-end path.
  /// Discards the session afterward. Does not mutate WorkingMindView ad hoc.
  Future<void> _closeNightSession() async {
    final session = _session;
    if (session == null) return;

    _mindModel = HcosLiveEntry.completeNightSession(
      orchestrator: _orchestrator,
      session: session,
      model: _mindModel,
    );
    _session = null;
  }

  /// Canonical MemoryEngine write, then calm closing presentation.
  Future<void> _finishNightAndShowClosing() async {
    await _closeNightSession();

    if (!mounted) return;

    setState(() => isLoadingAudio = false);

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const NightCompleteScreen()),
    );
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

    setState(() => isLoadingAudio = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

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

    // Presentation-only player handoff. Not HCOS cognition.
    // NightSession stays open until audio ends → completeNightSession.
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          goal: 'sleep',
          blocker: 'mind',
          sleepLatency: 'medium',
          energy: 'medium',
          sessionLength: access.sessionLength,
          audioAssetPath: access.sleepBedAsset,
          premiumUnlocked: access.isPremium,
        ),
      ),
    );

    if (!mounted) return;

    await _finishNightAndShowClosing();
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
              itemCount: _messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (isTyping && index == _messages.length) {
                  return const _TypingBubble();
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
                  enabled: _acceptsUserInput,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "What's on your mind tonight?",
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: (isLoadingAudio || isTyping) ? null : _handleSend,
              icon: Icon(
                Icons.arrow_upward_rounded,
                color: (isLoadingAudio || isTyping)
                    ? Colors.white24
                    : Colors.white70,
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

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          "hazırlanıyor…",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
