import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'emotional_pattern.dart';
import 'mental_pattern.dart';
import 'mental_pattern_status.dart';

/// Lightweight cross-night continuity store.
///
/// Persists identity counters, last blocker, and pattern ids only.
/// Does not store dialogue. Does not reopen HCOS mid-turn.
class LivingMindStore {
  static const _sessionsKey = 'nocta_living_mind_total_sessions';
  static const _blockerKey = 'nocta_living_mind_last_blocker';
  static const _mentalKey = 'nocta_living_mind_mental_patterns';
  static const _emotionalKey = 'nocta_living_mind_emotional_patterns';

  const LivingMindStore();

  Future<int> loadTotalSessions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sessionsKey) ?? 0;
  }

  Future<String?> loadLastBlocker() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_blockerKey);
  }

  Future<List<MentalPattern>> loadMentalPatterns() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mentalKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => _mentalFromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<EmotionalPattern>> loadEmotionalPatterns() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_emotionalKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => _emotionalFromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> saveAfterNight({
    required int totalSessions,
    required String blocker,
    List<MentalPattern> mentalPatterns = const [],
    List<EmotionalPattern> emotionalPatterns = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionsKey, totalSessions);
    await prefs.setString(_blockerKey, blocker);
    await prefs.setString(
      _mentalKey,
      jsonEncode(mentalPatterns.map(_mentalToJson).toList()),
    );
    await prefs.setString(
      _emotionalKey,
      jsonEncode(emotionalPatterns.map(_emotionalToJson).toList()),
    );
  }

  Map<String, dynamic> _mentalToJson(MentalPattern p) => {
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'confidence': p.confidence,
        'observations': p.observations,
        'status': p.status.name,
      };

  MentalPattern _mentalFromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'observed';
    final status = MentalPatternStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => MentalPatternStatus.observed,
    );
    return MentalPattern(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      description: json['description'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      observations: json['observations'] as int? ?? 1,
      status: status,
    );
  }

  Map<String, dynamic> _emotionalToJson(EmotionalPattern p) => {
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'confidence': p.confidence,
        'observations': p.observations,
      };

  EmotionalPattern _emotionalFromJson(Map<String, dynamic> json) {
    return EmotionalPattern(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      description: json['description'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      observations: json['observations'] as int? ?? 1,
    );
  }
}
