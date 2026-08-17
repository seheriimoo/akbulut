import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'sleep_audio_session.dart';

class PlayerScreen extends StatefulWidget {
  final String blocker;
  final String sleepLatency;
  final String energy;
  final String goal;
  final Duration sessionLength;

  /// Sleep bed asset resolved by entitlement access (free vs premium).
  final String audioAssetPath;

  /// True when [BillingService] premium entitlement unlocked this session.
  final bool premiumUnlocked;

  const PlayerScreen({
    super.key,
    required this.blocker,
    required this.sleepLatency,
    required this.energy,
    required this.goal,
    required this.sessionLength,
    this.audioAssetPath =
        'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a',
    this.premiumUnlocked = false,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final AudioPlayer _bgPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  static const double _targetVolume = 1.0;

  bool _ready = false;
  bool _playing = false;
  bool _finishing = false;
  bool _loading = true;
  bool _loadFailed = false;

  Timer? _sessionTimer;
  /// Remaining bed time; shrinks only while the session timer is armed.
  late Duration _remaining;
  DateTime? _timerArmedAt;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;

  late final AnimationController _breathController;
  late final Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remaining = widget.sessionLength;

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Background / lock-screen: keep sleep bed playing; do not pause on inactive.
    if (state == AppLifecycleState.resumed && _playing) {
      unawaited(SleepAudioSession.activate());
    }
  }

  Future<void> _initAudio() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });

    try {
      final audioPath = _buildAudioPath();
      final assetPath = audioPath.replaceFirst('assets/', '');

      // Validate bed asset before arming platform audio / Start affordance.
      await rootBundle.load(audioPath);

      await SleepAudioSession.configureForBackgroundPlayback(_bgPlayer);

      final session = await AudioSession.instance;
      _interruptionSub = session.interruptionEventStream.listen((event) async {
        if (event.begin) {
          return;
        }
        // Resume after transient interruptions when the sleep session is active.
        if (_playing &&
            (event.type == AudioInterruptionType.pause ||
                event.type == AudioInterruptionType.unknown)) {
          await SleepAudioSession.activate();
          await _bgPlayer.resume();
        }
      });

      await _bgPlayer.setVolume(_targetVolume);
      await _bgPlayer.setSourceAsset(assetPath);

      if (!mounted) return;

      setState(() {
        _ready = true;
        _loading = false;
        _loadFailed = false;
      });

      // Complete Conversation → Audio handoff by starting the sleep bed.
      await _startPlayback();
    } catch (e, st) {
      debugPrint('AUDIO ERROR: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() {
        _ready = false;
        _playing = false;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  String _buildAudioPath() => widget.audioAssetPath;

  String _buildSessionTitle() {
    switch (widget.blocker) {
      case 'mind':
        return 'Quiet Mind';
      case 'stress':
        return 'Stress Release';
      case 'body':
        return 'Body Relaxation';
      case 'overstimulated':
        return 'Deep Calm';
      case 'wired':
        return 'Wind Down';
      case 'deep':
        return 'Deep Sleep';
      case 'relationship':
        return 'Letting Go';
      case 'loneliness':
        return 'Comfort';
      default:
        return 'Personalized Sleep';
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    if (_remaining <= Duration.zero) {
      unawaited(_finishAudioSession(completedNaturally: true));
      return;
    }
    _timerArmedAt = DateTime.now();
    _sessionTimer = Timer(_remaining, () {
      unawaited(_finishAudioSession(completedNaturally: true));
    });
  }

  /// Stops countdown while paused so remaining time does not advance.
  void _pauseSessionTimer() {
    final armedAt = _timerArmedAt;
    if (armedAt != null) {
      _remaining = sessionRemainingAfterElapsed(
        remaining: _remaining,
        elapsed: DateTime.now().difference(armedAt),
      );
    }
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _timerArmedAt = null;
  }

  /// Stops the sleep bed and returns to the night host.
  ///
  /// Pop contract for [AISleepChatScreen]:
  ///   true  → bed completed naturally → close night
  ///   null  → user left early → stay on chat + continue CTA
  ///   false → load/play failure (via [_leaveAfterLoadFailure]) → stay + retry
  Future<void> _finishAudioSession({required bool completedNaturally}) async {
    if (_finishing) return;
    setState(() => _finishing = true);

    _sessionTimer?.cancel();
    _sessionTimer = null;
    _timerArmedAt = null;

    // Only tear down platform audio when a bed was actually armed.
    // Avoid hanging End Session on load-failure recovery.
    if (_ready || _playing) {
      try {
        await _bgPlayer.stop();
        await SleepAudioSession.deactivate();
      } catch (_) {
        // Best-effort teardown before leaving the player.
      }
    }

    if (!mounted) return;

    setState(() => _playing = false);
    // true = natural end; null = user left early (stay on chat + continue).
    Navigator.of(context).pop(completedNaturally ? true : null);
  }

  Future<void> _startPlayback() async {
    try {
      await SleepAudioSession.activate();
      await _bgPlayer.resume();
      await _bgPlayer.setVolume(_targetVolume);

      if (!mounted) return;

      setState(() {
        _playing = true;
        _ready = true;
        _loading = false;
        _loadFailed = false;
      });

      _startSessionTimer();
    } catch (e, st) {
      debugPrint('AUDIO PLAY ERROR: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() {
        _ready = false;
        _playing = false;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  /// Leave the player after a load failure without awaiting audio teardown.
  void _leaveAfterLoadFailure() {
    if (_finishing || !_loadFailed) return;
    setState(() => _finishing = true);
    // Pop after rebuild so PopScope canPop allows the route to leave.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(false);
    });
  }

  Future<void> _togglePlay() async {
    if (_loadFailed || _loading || !_ready || _finishing) return;

    if (_playing) {
      await _bgPlayer.pause();
      _pauseSessionTimer();
      if (!mounted) return;
      setState(() => _playing = false);
      return;
    }

    await _startPlayback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    _interruptionSub?.cancel();
    _breathController.dispose();
    unawaited(_bgPlayer.dispose());
    unawaited(_tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionTitle = _buildSessionTitle();

    return PopScope(
      // Allow imperative pop once finish/leave has begun; otherwise intercept.
      canPop: _finishing,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_finishAudioSession(completedNaturally: false));
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Nocta',
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox.shrink(),
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
                          color: Colors.white.withValues(alpha: 0.06),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          '✦',
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
                const SizedBox(height: 8),
                Text(
                  widget.premiumUnlocked
                      ? '${widget.sessionLength.inMinutes}-minute premium session'
                      : '${widget.sessionLength.inMinutes}-minute session',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 32),
                if (_loadFailed) ...[
                  Text(
                    'This session could not start.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => unawaited(_initAudio()),
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(29),
                      ),
                      child: const Text(
                        'Try again',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _leaveAfterLoadFailure,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(29),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Text(
                        'End Session',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else if (_loading) ...[
                  Text(
                    'Preparing session…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(29),
                    ),
                    child: Text(
                      'Start Session',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.35),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
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
                        _playing ? 'Pause Session' : 'Start Session',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Remaining bed time after a pause interval. Does not go negative.
@visibleForTesting
Duration sessionRemainingAfterElapsed({
  required Duration remaining,
  required Duration elapsed,
}) {
  final next = remaining - elapsed;
  return next.isNegative ? Duration.zero : next;
}
