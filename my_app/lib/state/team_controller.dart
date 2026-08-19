import 'package:flutter/foundation.dart';

import '../data/empty_team.dart';
import '../data/team_repository.dart';
import '../models/analytics.dart';
import '../models/inputs.dart';
import '../services/fairplay_engine.dart';
import '../services/wellness_risk_calculator.dart';

class TeamController extends ChangeNotifier {
  TeamController({
    required TeamRepository repository,
    FairPlayEngine? engine,
  })  : _repository = repository,
        _engine = engine ?? FairPlayEngine();

  final TeamRepository _repository;
  final FairPlayEngine _engine;
  bool _disposed = false;

  TeamInput? _team;
  FairPlaySnapshot? _snapshot;
  String? _activeMatchId;
  bool _loading = true;
  String? _error;
  String? _syncError;

  TeamInput? get team => _team;
  FairPlaySnapshot? get snapshot => _snapshot;
  String? get activeMatchId => _activeMatchId;
  bool get loading => _loading;
  String? get error => _error;

  /// Set when the last save could not reach storage. Edits stay in memory and
  /// on the device, so this is a warning rather than a failure.
  String? get syncError => _syncError;

  bool get hasPlayers => (_team?.players.isNotEmpty ?? false);

  bool get hasAttendanceData =>
      _team?.attendance.any((record) => record.sessionsTotal > 0) ?? false;

  bool get hasRpeData =>
      _team?.rpe.any((record) => record.dailyValues.isNotEmpty) ?? false;

  bool get hasMatchEvents =>
      _team?.games.any((game) => game.events.isNotEmpty) ?? false;

  bool get hasMatchAppearances =>
      _team?.games.any(
            (game) => game.appearances.any((appearance) => appearance.minutesPlayed > 0),
          ) ??
      false;

  bool get hasWellnessData =>
      _team?.wellness.any((record) => record.hasData) ?? false;

  int get atRiskAthleteCount =>
      _team?.wellness.where((record) => record.effectiveCrashRisk == CrashRisk.high).length ?? 0;

  int get setupStepsComplete => [
        _team != null && _team!.name.trim().isNotEmpty,
        hasPlayers,
        hasAttendanceData,
        hasRpeData,
        hasMatchAppearances,
        hasMatchEvents,
      ].where((done) => done).length;

  GameLog? get activeMatch {
    final team = _team;
    final matchId = _activeMatchId;
    if (team == null || matchId == null) return null;
    for (final game in team.games) {
      if (game.id == matchId) return game;
    }
    return null;
  }

  AttendanceInput? attendanceFor(String playerId) {
    return _team?.attendanceFor(playerId);
  }

  RpeInput? rpeFor(String playerId) {
    return _team?.rpeFor(playerId);
  }

  WellnessInput? wellnessFor(String playerId) {
    return _team?.wellnessFor(playerId);
  }

  GameAppearance? appearanceFor(String playerId) {
    final match = activeMatch;
    if (match == null) return null;
    for (final appearance in match.appearances) {
      if (appearance.playerId == playerId) return appearance;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    _loading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _team = await _repository.loadTeam();
      if (_disposed) return;
      _team = _team!.withSyncedWellness();
      _activeMatchId = await _repository.getActiveMatchId();
      if (_disposed) return;

      if (_activeMatchId == null && _team!.games.isNotEmpty) {
        _activeMatchId = _team!.games.last.id;
        await _write(() => _repository.setActiveMatchId(_activeMatchId!));
      }

      _reanalyze();
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> updateTeamName(String name) async {
    final team = _team;
    if (team == null) return;

    _team = team.copyWith(name: name.trim());
    await _persist();
  }

  Future<void> addPlayer({
    required String name,
    required String position,
    PlayerRole role = PlayerRole.field,
  }) async {
    final team = _team;
    if (team == null || name.trim().isEmpty) return;

    final id = _newPlayerId(name.trim());
    final player = PlayerInput(
      id: id,
      name: name.trim(),
      position: position,
      role: role,
    );

    _team = team.copyWith(
      players: [...team.players, player],
      attendance: [
        ...team.attendance,
        AttendanceInput(playerId: id, sessionsAttended: 0, sessionsTotal: 0),
      ],
      rpe: [
        ...team.rpe,
        RpeInput(playerId: id, dailyValues: []),
      ],
      wellness: [
        ...team.wellness,
        WellnessInput(playerId: id),
      ],
    );
    await _persist();
  }

  Future<void> removePlayer(String playerId) async {
    final team = _team;
    if (team == null) return;

    _team = team.copyWith(
      players: team.players.where((player) => player.id != playerId).toList(),
      attendance:
          team.attendance.where((record) => record.playerId != playerId).toList(),
      rpe: team.rpe.where((record) => record.playerId != playerId).toList(),
      wellness: team.wellness.where((record) => record.playerId != playerId).toList(),
      games: team.games.map((game) {
        return game.copyWith(
          appearances: game.appearances
              .where((appearance) => appearance.playerId != playerId)
              .toList(),
          events: game.events
              .where((event) => event.playerId != playerId)
              .toList(),
        );
      }).toList(),
    );
    await _persist();
  }

  Future<void> updateAttendance({
    required String playerId,
    required int sessionsAttended,
    required int sessionsTotal,
  }) async {
    final team = _team;
    if (team == null) return;

    final attended = sessionsAttended.clamp(0, sessionsTotal);
    final total = sessionsTotal.clamp(0, 999);

    _team = team.copyWith(
      attendance: team.attendance.map((record) {
        if (record.playerId != playerId) return record;
        return AttendanceInput(
          playerId: playerId,
          sessionsAttended: attended,
          sessionsTotal: total,
        );
      }).toList(),
    );
    await _persist();
  }

  Future<void> logRpe({required String playerId, required double value}) async {
    final team = _team;
    if (team == null) return;

    _team = team.copyWith(
      rpe: team.rpe.map((record) {
        if (record.playerId != playerId) return record;
        final clamped = value.clamp(1.0, 10.0);
        final values = <double>[...record.dailyValues, clamped];
        while (values.length > 7) {
          values.removeAt(0);
        }
        return RpeInput(playerId: playerId, dailyValues: values);
      }).toList(),
    );
    await _persist();
  }

  Future<void> updateWellness({
    required String playerId,
    required int trainingLoad,
    required double sleepHours,
    required double studyHours,
  }) async {
    final team = _team;
    if (team == null) return;

    final load = trainingLoad.clamp(0, 10);
    final sleep = sleepHours.clamp(0.0, 24.0);
    final study = studyHours.clamp(0.0, 24.0);
    final crashRisk = WellnessRiskCalculator.calculate(
      trainingLoad: load,
      sleepHours: sleep,
      studyHours: study,
    );

    _team = team.copyWith(
      wellness: team.wellness.map((record) {
        if (record.playerId != playerId) return record;
        return WellnessInput(
          playerId: playerId,
          trainingLoad: load,
          sleepHours: sleep,
          studyHours: study,
          crashRisk: crashRisk,
        );
      }).toList(),
    );
    await _persist();
  }

  Future<void> logMatchAppearance({
    required String playerId,
    required int minutesPlayed,
    required bool started,
  }) async {
    final team = _team;
    if (team == null) return;

    var matchId = _activeMatchId;
    var games = List<GameLog>.from(team.games);

    if (matchId == null || !games.any((game) => game.id == matchId)) {
      matchId = _newMatchId();
      games.add(GameLog(id: matchId, appearances: const [], events: const []));
      _activeMatchId = matchId;
      await _write(() => _repository.setActiveMatchId(matchId!));
    }

    final maxMinutes = team.matchLengthMinutes;
    final minutes = minutesPlayed.clamp(0, maxMinutes);
    final appearance = GameAppearance(
      playerId: playerId,
      minutesPlayed: minutes,
      started: started && minutes > 0,
    );

    games = games.map((game) {
      if (game.id != matchId) return game;

      final appearances = List<GameAppearance>.from(game.appearances)
        ..removeWhere((record) => record.playerId == playerId);

      if (minutes > 0) {
        appearances.add(appearance);
      }

      return game.copyWith(appearances: appearances);
    }).toList();

    _team = team.copyWith(games: games);
    await _persist();
  }

  Future<void> logMatchEvent(GameEventInput event) async {
    final team = _team;
    if (team == null) return;

    var matchId = _activeMatchId;
    var games = List<GameLog>.from(team.games);

    if (matchId == null || !games.any((game) => game.id == matchId)) {
      matchId = _newMatchId();
      games.add(GameLog(id: matchId, appearances: const [], events: const []));
      _activeMatchId = matchId;
      await _write(() => _repository.setActiveMatchId(matchId!));
    }

    games = games.map((game) {
      if (game.id != matchId) return game;
      return game.copyWith(events: [...game.events, event]);
    }).toList();

    _team = team.copyWith(games: games);
    await _persist();
  }

  Future<void> startNewMatch() async {
    final team = _team;
    if (team == null) return;

    final matchId = _newMatchId();
    final games = [
      ...team.games,
      GameLog(id: matchId, appearances: const [], events: const []),
    ];

    _team = team.copyWith(games: games);
    _activeMatchId = matchId;

    await _write(() => _repository.setActiveMatchId(matchId));
    await _persist();
  }

  Future<void> resetSquad() async {
    _team = emptyTeam;
    _activeMatchId = null;
    await _write(() => _repository.saveTeam(emptyTeam));
    await _write(() => _repository.setActiveMatchId(''));
    _reanalyze();
    _safeNotifyListeners();
  }

  Future<void> _persist() async {
    if (_team == null) return;
    await _write(() => _repository.saveTeam(_team!));
    if (_disposed) return;
    _reanalyze();
    _safeNotifyListeners();
  }

  /// Saves never throw at the caller: a coach mid-match should keep entering
  /// data even if the network is gone.
  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
      _syncError = null;
    } catch (error) {
      _syncError =
          'Your latest changes are on this device but have not synced yet.';
      debugPrint('FairPlay Lab save failed: $error');
    }
  }

  void _reanalyze() {
    if (_team != null) {
      _snapshot = _engine.analyze(_team!);
    }
  }

  String _newPlayerId(String name) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch % 100000;
    return '${slug.isEmpty ? 'player' : slug}-$suffix';
  }

  String _newMatchId() {
    final now = DateTime.now();
    return 'match-${now.year}${_pad(now.month)}${_pad(now.day)}-${_pad(now.hour)}${_pad(now.minute)}';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}
