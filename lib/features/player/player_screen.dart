import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PlayerScreen extends StatefulWidget {
  final String blocker;
  final String sleepLatency;
  final String energy;
  final String goal;
  final Duration sessionLength;

  const PlayerScreen({
    super.key,
    required this.blocker,
    required this.sleepLatency,
    required this.energy,
    required this.goal,
    required this.sessionLength,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _bgPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  static const double _targetVolume = 1.0;

  bool _ready = false;
  bool _playing = false;

  Timer? _sessionTimer;

  late final AnimationController _breathController;
  late final Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _breathAnimation = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: Curves.easeInOut,
      ),
    );

    _breathController.repeat(reverse: true);
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      print("INIT AUDIO START");
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      final audioPath = _buildAudioPath();
      final assetPath = audioPath.replaceFirst("assets/", "");

      final test = await rootBundle.load(audioPath);
      print("ROOT BUNDLE OK: ${test.lengthInBytes} bytes");

      print("🎧 Selected audio: $audioPath");
      print("ASSET PATH = $assetPath");

      await _bgPlayer.setReleaseMode(ReleaseMode.stop);
      await _bgPlayer.setVolume(_targetVolume);
      await _bgPlayer.setSourceAsset(assetPath);

      if (!mounted) return;

      setState(() {
        _ready = true;
        _playing = false;
      });
      print("_ready SET TRUE");
    } catch (e, st) {
      print("AUDIO ERROR: $e");
      print(st);
    }
  }

  String _buildAudioPath() {
    switch (widget.blocker) {
      case "mind":
        return "assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a";
      case "stress":
        return "assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a";
      case "body":
        return "assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a";
      case "overstimulated":
        return "assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a";
      case "wired":
        return "assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a";
      case "deep":
        return "assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a";
      case "relationship":
        return "assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a";
      case "loneliness":
        return "assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a";
      default:
        return "assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a";
    }
  }

  String _buildSessionTitle() {
    switch (widget.blocker) {
      case "mind":
        return "Quiet Mind";
      case "stress":
        return "Stress Release";
      case "body":
        return "Body Relaxation";
      case "overstimulated":
        return "Deep Calm";
      case "wired":
        return "Wind Down";
      case "deep":
        return "Deep Sleep";
      case "relationship":
        return "Letting Go";
      case "loneliness":
        return "Comfort";
      default:
        return "Personalized Sleep";
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(widget.sessionLength, () async {
      await _bgPlayer.stop();

      if (!mounted) return;

      setState(() {
        _playing = false;
      });
    });
  }

  Future<void> _togglePlay() async {
    if (!_ready) {
      print("_READY BLOCKED PLAY");
      return;
    }

    if (_playing) {
      print("PAUSE PRESSED");
      await _bgPlayer.pause();

      if (!mounted) return;

      setState(() {
        _playing = false;
      });
    } else {
      print("START / RESUME PRESSED");
      await _bgPlayer.resume();
      await _bgPlayer.setVolume(_targetVolume);

      if (!mounted) return;

      setState(() {
        _playing = true;
      });

      _startSessionTimer();

      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(0.95);

      Future.delayed(const Duration(seconds: 30), () async {
        print("TTS START");
        final result = await _tts.speak("Tomorrow can stay where it is. Nothing more is needed from you tonight.");
        print("TTS RESULT = $result");
      });
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _breathController.dispose();
    _bgPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionTitle = _buildSessionTitle();

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Nocta",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              AnimatedBuilder(
                animation: _breathAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breathAnimation.value,
                    child: Container(
                      width: 150,
                      height: 150,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        "✦",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 58,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              const Text(
                "Tonight's Session",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                sessionTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.2,
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: double.infinity,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(29),
                  ),
                  child: Text(
                    _playing ? "Pause Session" : "Start Session",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}