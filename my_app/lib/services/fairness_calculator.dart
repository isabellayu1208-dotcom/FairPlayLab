import 'dart:math' as math;

import '../models/analytics.dart';
import '../models/inputs.dart';

class FairnessCalculator {
  static const _meaningfulBenchMinutes = 10;
  static const _targetFieldMinutes = 34;
  static const _highRpeThreshold = 7.5;
  static const _lowAttendanceThreshold = 0.85;

  TeamFairnessMetrics computeTeamMetrics(TeamInput team) {
    final fieldPlayers = team.players.where((p) => !p.isGoalkeeper).toList();
    final minutesByPlayer = _averageMinutes(fieldPlayers, team.games);

    final minutesEquity = _minutesEquity(minutesByPlayer.values.toList());
    final starterRotationBalance = _starterRotationBalance(fieldPlayers, team.games);
    final benchOpportunityRate = _benchOpportunityRate(fieldPlayers, team.games);

    final fairnessIndex = _clamp01(
      0.45 * minutesEquity +
          0.30 * starterRotationBalance +
          0.25 * benchOpportunityRate,
    );

    return TeamFairnessMetrics(
      minutesEquity: minutesEquity,
      starterRotationBalance: starterRotationBalance,
      benchOpportunityRate: benchOpportunityRate,
      fairnessIndex: fairnessIndex,
    );
  }

  List<PlayerRotation> computeRotations(TeamInput team) {
    if (team.players.isEmpty || !_hasRotationInputs(team)) {
      return [];
    }

    final fieldPlayers = team.players.where((p) => !p.isGoalkeeper).toList();
    final minutesByPlayer = _averageMinutes(fieldPlayers, team.games);
    final teamAvgMinutes = _mean(minutesByPlayer.values.toList());

    return team.players.map((player) {
      if (player.isGoalkeeper) {
        return _goalkeeperRotation(player, team);
      }

      final attendance = team.attendanceFor(player.id)?.rate ?? 0;
      final rpe = team.rpeFor(player.id)?.average ?? 0;
      final avgMinutes = minutesByPlayer[player.id] ?? 0;
      final minuteDelta = teamAvgMinutes - avgMinutes;

      final minutesEquity = _playerMinutesEquity(minuteDelta);
      final loadFit = _loadFit(rpe);
      final fairnessScore = _clamp01(
        0.45 * minutesEquity + 0.30 * attendance + 0.25 * loadFit,
      );

      final range = _recommendedMinutes(
        fairnessScore: fairnessScore,
        rpe: rpe,
        attendance: attendance,
        matchLength: team.matchLengthMinutes,
      );

      final whyFactors = _buildWhyFactors(
        player: player,
        attendance: attendance,
        rpe: rpe,
        minuteDelta: minuteDelta,
        avgMinutes: avgMinutes,
        minMinutes: range.$1,
        maxMinutes: range.$2,
        team: team,
      );

      return PlayerRotation(
        playerId: player.id,
        name: player.name,
        position: player.position,
        minMinutes: range.$1,
        maxMinutes: range.$2,
        attendance: attendance,
        rpe: rpe,
        fairnessScore: fairnessScore,
        status: _status(fairnessScore, rpe, attendance),
        whyFactors: whyFactors,
      );
    }).toList()
      ..sort((a, b) => b.fairnessScore.compareTo(a.fairnessScore));
  }

  PlayerRotation _goalkeeperRotation(PlayerInput player, TeamInput team) {
    final attendance = team.attendanceFor(player.id)?.rate ?? 0;
    final rpe = team.rpeFor(player.id)?.average ?? 0;

    return PlayerRotation(
      playerId: player.id,
      name: player.name,
      position: player.position,
      minMinutes: team.matchLengthMinutes,
      maxMinutes: team.matchLengthMinutes,
      attendance: attendance,
      rpe: rpe,
      fairnessScore: 0.85,
      status: 'Starter',
      whyFactors: [
        WhyFactor(
          label: 'Role lock',
          detail: 'Primary goalkeeper — no substitution planned',
          impact: 'Full ${team.matchLengthMinutes} min',
        ),
      ],
    );
  }

  (int, int) _recommendedMinutes({
    required double fairnessScore,
    required double rpe,
    required double attendance,
    required int matchLength,
  }) {
    var target = _targetFieldMinutes + ((fairnessScore - 0.5) * 12).round();

    if (rpe >= _highRpeThreshold) {
      target -= 4;
    } else if (rpe <= 5.5) {
      target += 2;
    }

    if (attendance < _lowAttendanceThreshold) {
      target -= 3;
    }

    target = target.clamp(8, matchLength - 10);
    final spread = rpe >= _highRpeThreshold ? 2 : 4;
    final minMinutes = (target - spread ~/ 2).clamp(8, matchLength);
    final maxMinutes = (target + spread ~/ 2).clamp(minMinutes, matchLength - 5);

    return (minMinutes, maxMinutes);
  }

  List<WhyFactor> _buildWhyFactors({
    required PlayerInput player,
    required double attendance,
    required double rpe,
    required double minuteDelta,
    required double avgMinutes,
    required int minMinutes,
    required int maxMinutes,
    required TeamInput team,
  }) {
    final factors = <WhyFactor>[];
    final attendanceRecord = team.attendanceFor(player.id);

    if (attendanceRecord != null && attendanceRecord.sessionsTotal > 0) {
      factors.add(
        WhyFactor(
          label: 'Attendance',
          detail:
              'Present at ${attendanceRecord.sessionsAttended} of last ${attendanceRecord.sessionsTotal} sessions',
          impact: attendance >= 0.9
              ? 'Strong reliability'
              : 'Reduced rotation priority',
        ),
      );
    }

    factors.add(
      WhyFactor(
        label: 'RPE recovery',
        detail: rpe == 0
            ? 'No RPE logged yet — add on the Data tab'
            : rpe >= _highRpeThreshold
                ? '7-day avg RPE ${rpe.toStringAsFixed(1)} — elevated load'
                : '7-day avg RPE ${rpe.toStringAsFixed(1)} — within safe range',
        impact: rpe == 0
            ? 'Log RPE to refine minutes'
            : rpe >= _highRpeThreshold
                ? 'Cap at $maxMinutes min'
                : 'Full rotation eligible',
      ),
    );

    if (minuteDelta.abs() >= 3) {
      final direction = minuteDelta > 0 ? 'below' : 'above';
      factors.add(
        WhyFactor(
          label: 'Fairness balance',
          detail:
              'Played ${minuteDelta.abs().round()} min $direction squad avg over recent matches',
          impact: minuteDelta > 0 ? 'Priority for minutes' : 'Reduce starter load',
        ),
      );
    } else if (avgMinutes > 0) {
      factors.add(
        WhyFactor(
          label: 'Match minutes',
          detail: 'Averaged ${avgMinutes.round()} min over recent matches',
          impact: 'Factored into rotation balance',
        ),
      );
    }

    factors.add(
      WhyFactor(
        label: 'Recommendation',
        detail: 'Composite fairness score drives the minute range',
        impact: '$minMinutes–$maxMinutes min recommended',
      ),
    );

    return factors;
  }

  String _status(double fairnessScore, double rpe, double attendance) {
    if (rpe >= _highRpeThreshold || attendance < _lowAttendanceThreshold) {
      return 'Monitor';
    }
    if (fairnessScore >= 0.8) return 'Recommended';
    return 'Monitor';
  }

  Map<String, double> _averageMinutes(
    List<PlayerInput> fieldPlayers,
    List<GameLog> games,
  ) {
    final totals = <String, double>{};
    final counts = <String, int>{};

    for (final game in games) {
      for (final appearance in game.appearances) {
        totals.update(
          appearance.playerId,
          (value) => value + appearance.minutesPlayed,
          ifAbsent: () => appearance.minutesPlayed.toDouble(),
        );
        counts.update(
          appearance.playerId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    return {
      for (final player in fieldPlayers)
        player.id: (totals[player.id] ?? 0) / (counts[player.id] ?? 1),
    };
  }

  double _minutesEquity(List<double> averageMinutes) {
    if (averageMinutes.isEmpty) return 0;
    if (averageMinutes.length < 2) {
      return averageMinutes.first > 0 ? 1 : 0;
    }
    final meanValue = _mean(averageMinutes);
    if (meanValue == 0) return 0;

    final variance = averageMinutes
            .map((value) => (value - meanValue) * (value - meanValue))
            .reduce((a, b) => a + b) /
        averageMinutes.length;
    final coefficientOfVariation = math.sqrt(variance) / meanValue;
    return _clamp01(1 - coefficientOfVariation);
  }

  double _starterRotationBalance(
    List<PlayerInput> fieldPlayers,
    List<GameLog> games,
  ) {
    if (games.isEmpty) return 0;

    final starts = <String, int>{for (final player in fieldPlayers) player.id: 0};
    for (final game in games) {
      for (final appearance in game.appearances) {
        if (appearance.started && starts.containsKey(appearance.playerId)) {
          starts[appearance.playerId] = starts[appearance.playerId]! + 1;
        }
      }
    }

    final maxStarts = starts.values.fold<int>(0, (max, value) => value > max ? value : max);
    return _clamp01(1 - (maxStarts / games.length));
  }

  double _benchOpportunityRate(
    List<PlayerInput> fieldPlayers,
    List<GameLog> games,
  ) {
    if (games.isEmpty) return 0;

    final benchPlayers = <String>{};
    final benchWithMinutes = <String>{};

    for (final game in games) {
      for (final appearance in game.appearances) {
        if (!appearance.started && fieldPlayers.any((p) => p.id == appearance.playerId)) {
          benchPlayers.add(appearance.playerId);
          if (appearance.minutesPlayed >= _meaningfulBenchMinutes) {
            benchWithMinutes.add(appearance.playerId);
          }
        }
      }
    }

    if (benchPlayers.isEmpty) return 0;
    return benchWithMinutes.length / benchPlayers.length;
  }

  double _playerMinutesEquity(double minuteDelta) {
    return _clamp01(0.5 + (minuteDelta / 24));
  }

  double _loadFit(double rpe) {
    if (rpe == 0) return 0;
    if (rpe <= 6) return 1;
    if (rpe >= 8.5) return 0.35;
    return _clamp01(1 - ((rpe - 6) / 2.5));
  }

  double _mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _clamp01(double value) => value.clamp(0.0, 1.0);

  bool _hasRotationInputs(TeamInput team) {
    final hasAttendance = team.attendance.any((record) => record.sessionsTotal > 0);
    final hasRpe = team.rpe.any((record) => record.dailyValues.isNotEmpty);
    return hasAttendance && hasRpe;
  }
}
