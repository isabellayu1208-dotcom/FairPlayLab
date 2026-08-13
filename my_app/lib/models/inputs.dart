import 'soccer.dart';

import '../services/wellness_risk_calculator.dart';

enum PlayerRole { field, goalkeeper }

enum GameEventType { pass, shot, dribble, clearance }

enum CrashRisk { low, moderate, high }

extension CrashRiskLabel on CrashRisk {
  String get label {
    switch (this) {
      case CrashRisk.low:
        return 'Low';
      case CrashRisk.moderate:
        return 'Moderate';
      case CrashRisk.high:
        return 'High';
    }
  }

  static CrashRisk fromLabel(String label) {
    switch (label) {
      case 'Moderate':
        return CrashRisk.moderate;
      case 'High':
        return CrashRisk.high;
      default:
        return CrashRisk.low;
    }
  }
}

class PlayerInput {
  const PlayerInput({
    required this.id,
    required this.name,
    required this.position,
    this.role = PlayerRole.field,
  });

  final String id;
  final String name;
  final String position;
  final PlayerRole role;

  bool get isGoalkeeper => role == PlayerRole.goalkeeper;
}

class AttendanceInput {
  const AttendanceInput({
    required this.playerId,
    required this.sessionsAttended,
    required this.sessionsTotal,
  });

  final String playerId;
  final int sessionsAttended;
  final int sessionsTotal;

  double get rate =>
      sessionsTotal == 0 ? 0 : sessionsAttended / sessionsTotal;
}

class RpeInput {
  const RpeInput({required this.playerId, required this.dailyValues});

  final String playerId;
  final List<double> dailyValues;

  double get average =>
      dailyValues.isEmpty ? 0 : dailyValues.reduce((a, b) => a + b) / dailyValues.length;
}

class WellnessInput {
  const WellnessInput({
    required this.playerId,
    this.trainingLoad = 0,
    this.sleepHours = 0,
    this.studyHours = 0,
    this.crashRisk = CrashRisk.low,
  });

  final String playerId;
  final int trainingLoad;
  final double sleepHours;
  final double studyHours;
  final CrashRisk crashRisk;

  bool get hasData => trainingLoad > 0 || sleepHours > 0 || studyHours > 0;

  CrashRisk get effectiveCrashRisk => WellnessRiskCalculator.calculate(
        trainingLoad: trainingLoad,
        sleepHours: sleepHours,
        studyHours: studyHours,
      );

  WellnessInput withCalculatedRisk() {
    return copyWith(crashRisk: effectiveCrashRisk);
  }

  WellnessInput copyWith({
    int? trainingLoad,
    double? sleepHours,
    double? studyHours,
    CrashRisk? crashRisk,
  }) {
    return WellnessInput(
      playerId: playerId,
      trainingLoad: trainingLoad ?? this.trainingLoad,
      sleepHours: sleepHours ?? this.sleepHours,
      studyHours: studyHours ?? this.studyHours,
      crashRisk: crashRisk ?? this.crashRisk,
    );
  }
}

class GameAppearance {
  const GameAppearance({
    required this.playerId,
    required this.minutesPlayed,
    required this.started,
  });

  final String playerId;
  final int minutesPlayed;
  final bool started;
}

class GameLog {
  const GameLog({
    required this.id,
    required this.appearances,
    required this.events,
  });

  final String id;
  final List<GameAppearance> appearances;
  final List<GameEventInput> events;

  GameLog copyWith({
    String? id,
    List<GameAppearance>? appearances,
    List<GameEventInput>? events,
  }) {
    return GameLog(
      id: id ?? this.id,
      appearances: appearances ?? this.appearances,
      events: events ?? this.events,
    );
  }
}

class GameEventInput {
  const GameEventInput({
    required this.playerId,
    required this.type,
    this.passChainLength = 0,
  });

  final String playerId;
  final GameEventType type;
  final int passChainLength;
}

class TeamInput {
  const TeamInput({
    required this.name,
    required this.players,
    required this.attendance,
    required this.rpe,
    required this.wellness,
    required this.games,
    this.matchLengthMinutes = SoccerConstants.matchLengthMinutes,
  });

  final String name;
  final List<PlayerInput> players;
  final List<AttendanceInput> attendance;
  final List<RpeInput> rpe;
  final List<WellnessInput> wellness;
  final List<GameLog> games;
  final int matchLengthMinutes;

  PlayerInput? playerById(String id) {
    for (final player in players) {
      if (player.id == id) return player;
    }
    return null;
  }

  AttendanceInput? attendanceFor(String playerId) {
    for (final record in attendance) {
      if (record.playerId == playerId) return record;
    }
    return null;
  }

  RpeInput? rpeFor(String playerId) {
    for (final record in rpe) {
      if (record.playerId == playerId) return record;
    }
    return null;
  }

  WellnessInput? wellnessFor(String playerId) {
    for (final record in wellness) {
      if (record.playerId == playerId) return record;
    }
    return null;
  }

  TeamInput withSyncedWellness() {
    final existing = {for (final record in wellness) record.playerId: record};
    return copyWith(
      wellness: players
          .map(
            (player) => (existing[player.id] ?? WellnessInput(playerId: player.id))
                .withCalculatedRisk(),
          )
          .toList(),
    );
  }

  TeamInput copyWith({
    String? name,
    List<PlayerInput>? players,
    List<AttendanceInput>? attendance,
    List<RpeInput>? rpe,
    List<WellnessInput>? wellness,
    List<GameLog>? games,
    int? matchLengthMinutes,
  }) {
    return TeamInput(
      name: name ?? this.name,
      players: players ?? this.players,
      attendance: attendance ?? this.attendance,
      rpe: rpe ?? this.rpe,
      wellness: wellness ?? this.wellness,
      games: games ?? this.games,
      matchLengthMinutes: matchLengthMinutes ?? this.matchLengthMinutes,
    );
  }
}
