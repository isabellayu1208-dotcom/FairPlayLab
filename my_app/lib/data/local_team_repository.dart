import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/empty_team.dart';
import '../models/inputs.dart';
import '../models/team_serializers.dart';
import 'team_repository.dart';

class LocalTeamRepository implements TeamRepository {
  LocalTeamRepository({TeamInput? seed}) : _seed = seed ?? emptyTeam;

  final TeamInput _seed;
  TeamInput? _cache;

  static const _teamKey = 'fairplay_team_json_v3';
  static const _activeMatchKey = 'fairplay_active_match_id';

  @override
  Future<TeamInput> loadTeam() async {
    if (_cache != null) return _cache!;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_teamKey);

    if (raw == null) {
      _cache = _seed;
      await saveTeam(_seed);
      return _seed;
    }

    _cache = teamInputFromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cache!;
  }

  @override
  Future<void> saveTeam(TeamInput team) async {
    _cache = team;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_teamKey, jsonEncode(teamInputToJson(team)));
  }

  @override
  Future<String?> getActiveMatchId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_activeMatchKey);
    if (id == null || id.isEmpty) return null;
    return id;
  }

  @override
  Future<void> setActiveMatchId(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    if (matchId.isEmpty) {
      await prefs.remove(_activeMatchKey);
      return;
    }
    await prefs.setString(_activeMatchKey, matchId);
  }
}

/// Firebase-ready stub — implement when connecting Firestore.
class FirebaseTeamRepository implements TeamRepository {
  @override
  Future<TeamInput> loadTeam() {
    throw UnimplementedError('Connect Firebase before using FirebaseTeamRepository.');
  }

  @override
  Future<void> saveTeam(TeamInput team) {
    throw UnimplementedError('Connect Firebase before using FirebaseTeamRepository.');
  }

  @override
  Future<String?> getActiveMatchId() {
    throw UnimplementedError('Connect Firebase before using FirebaseTeamRepository.');
  }

  @override
  Future<void> setActiveMatchId(String matchId) {
    throw UnimplementedError('Connect Firebase before using FirebaseTeamRepository.');
  }
}
