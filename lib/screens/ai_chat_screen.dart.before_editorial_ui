import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../features/player/player_screen.dart';

class AISleepChatScreen extends StatefulWidget {
  const AISleepChatScreen({super.key});

  @override
  State<AISleepChatScreen> createState() => _AISleepChatScreenState();
}

class _AISleepChatScreenState extends State<AISleepChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  int aiMessageCount = 0;
  bool isTyping = false;
  bool isLoadingAudio = false;
  String _lastUserInput = "";
  SleepState? _conversationState;
  final List<String> _userMessages = [];

@override
void initState() {
  super.initState();
}

  @override
  void dispose() {
  _controller.dispose();
  _scrollController.dispose();
  super.dispose();
}

Future<void> _sendInitialMessage() async {
  final starters = [
      "Şu an seni uyanık tutan şey daha çok zihinsel mi yoksa bir his gibi mi geliyor?",
      "Uykuya geçmeni zorlaştıran şey daha çok düşünceler mi yoksa bedenindeki bir gerginlik mi?",
     "🌙 Zihninde kalan bir şey mi var yoksa sadece gevşeyememe hali mi? 🤍",
     "Bugünden kalan bir şey mi seni hâlâ uyanık tutuyor?",
    ];
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || isTyping || isLoadingAudio) return;

    _lastUserInput = text;
    _conversationState ??= AIService.detectState(text);
    _userMessages.add(text);

    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });

    _scrollToBottom();
    await _generateAIResponse(text);
  }

  Future<void> _generateAIResponse(String userInput) async {
    if (!mounted) return;

    setState(() => isTyping = true);

    await Future.delayed(const Duration(milliseconds: 900));
    _conversationState ??= AIService.detectState(userInput);

    final reply = await AIService.generateReply(
  userInput: userInput,
  aiMessageCount: aiMessageCount,
  conversationHistory: _userMessages,
  conversationState: _conversationState,
);
    if (!mounted) return;

    setState(() => isTyping = false);

    if (reply.isNotEmpty) {
      await _addAIMessage(reply);
    }

    aiMessageCount++;

    if (aiMessageCount >= 3) {
      await _startAudioFlow();
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

    setState(() => isLoadingAudio = true);

                        

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final analysis = _analyzeSleepInput(_lastUserInput);

    final blocker = switch (_conversationState) {
      SleepState.overthinking => "mind",
      SleepState.workStress => "stress",
      SleepState.emotional => "stress",
      SleepState.relationship => "relationship",
      SleepState.loneliness => "loneliness",
      SleepState.physical => "body",
      _ => "mind",
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => 
         PlayerScreen(
          goal: "sleep",
          blocker: blocker,
          sleepLatency: "medium",
          energy: "medium",
          sessionLength: const Duration(minutes: 20),
        ),
      ),
    );
  }

  Map<String, int> _analyzeSleepInput(String input) {
    final text = input.toLowerCase();

    int sleepLatency = 1;
    int energy = 1;

    if (text.contains("düşün") ||
        text.contains("zihin") ||
        text.contains("kafam") ||
        text.contains("kuruntu") ||
        text.contains("takıldım")) {
      sleepLatency = 2;
    }

    if (text.contains("rahat") ||
        text.contains("sakin") ||
        text.contains("uykum var")) {
      sleepLatency = 0;
    }

    if (text.contains("stres") ||
        text.contains("gergin") ||
        text.contains("kaygı") ||
        text.contains("panik") ||
        text.contains("huzursuz")) {
      energy = 2;
    }

    if (text.contains("yorgun") ||
        text.contains("bitkin") ||
        text.contains("tükendim") ||
        text.contains("halsiz")) {
      energy = 0;
    }

    return {
      "sleepLatency": sleepLatency,
      "energy": energy,
    };
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

                return _MessageBubble(message: _messages[index]);
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
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                enabled: aiMessageCount < 3 && !isLoadingAudio && !isTyping,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Tell me what's keeping you awake...",
                    hintStyle: TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
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

  const _ChatMessage({
    required this.text,
    required this.isUser,
  });
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
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
  color: isUser
      ? Colors.white.withOpacity(0.07)
      : Colors.white.withOpacity(0.05),

  borderRadius: BorderRadius.only(
    topLeft: const Radius.circular(18),
    topRight: const Radius.circular(18),
    bottomLeft: Radius.circular(isUser ? 18 : 6),
    bottomRight: Radius.circular(isUser ? 6 : 18),
  ),

    border: Border.all(
    color: Colors.white.withOpacity(0.10),
    width: 1,
  ),
),

        child: Text(
        message.text,
        style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        height: 1.42,
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