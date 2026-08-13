import 'dart:math' as math;

import '../models/analytics.dart';
import '../models/inputs.dart';

class CohesionCalculator {
  static const _shortChainThreshold = 3;

  CohesionReport compute(TeamInput team) {
    final events = team.games.expand((game) => game.events).toList();
    final fieldPlayers = team.players.where((player) => !player.isGoalkeeper);

    final passes = events.where((event) => event.type == GameEventType.pass).toList();
    final shots = events.where((event) => event.type == GameEventType.shot).toList();
    final dribbles =
        events.where((event) => event.type == GameEventType.dribble).length;

    final shotConcentration = _shotConcentration(shots);
    final shortChainRate = _shortChainRate(shots);
    final soloRate = _soloRate(dribbles, events.length);
    final involvementBalance = _involvementBalance(passes, fieldPlayers.map((p) => p.id));
    final linkedShotRate = _linkedShotRate(shots);

    final heroSignal = _clamp01(
      0.35 * shotConcentration +
          0.25 * shortChainRate +
          0.25 * soloRate +
          0.15 * (1 - involvementBalance),
    );
    final teamSignal = _clamp01(
      0.40 * involvementBalance +
          0.35 * linkedShotRate +
          0.25 * (1 - shotConcentration),
    );

    final heroBallPercent = heroSignal + teamSignal == 0
        ? 50.0
        : (heroSignal / (heroSignal + teamSignal)) * 100;
    final teamBallPercent = 100 - heroBallPercent;
    final cohesionScore = teamBallPercent;

    final passingLeaders = _passingLeaders(team, passes);
    final topShooter = _topShooter(team, shots);

    return CohesionReport(
      heroBallPercent: heroBallPercent,
      teamBallPercent: teamBallPercent,
      cohesionScore: cohesionScore,
      trendLabel: _trendLabel(heroBallPercent),
      weeklySummary: _weeklySummary(
        topShooter: topShooter,
        shotConcentration: shotConcentration,
        shortChainRate: shortChainRate,
        linkedShotRate: linkedShotRate,
        hasShots: shots.isNotEmpty,
      ),
      passingLeaders: passingLeaders,
      practiceNudges: _practiceNudges(
        heroBallPercent: heroBallPercent,
        shortChainRate: shortChainRate,
        topShooter: topShooter,
        passingLeaders: passingLeaders,
      ),
    );
  }

  double _shotConcentration(List<GameEventInput> shots) {
    if (shots.isEmpty) return 0;

    final counts = <String, int>{};
    for (final shot in shots) {
      counts.update(shot.playerId, (value) => value + 1, ifAbsent: () => 1);
    }

    final maxShots = counts.values.fold<int>(0, math.max);
    return maxShots / shots.length;
  }

  double _shortChainRate(List<GameEventInput> shots) {
    if (shots.isEmpty) return 0;

    final shortChains =
        shots.where((shot) => shot.passChainLength < _shortChainThreshold).length;
    return shortChains / shots.length;
  }

  double _soloRate(int dribbles, int totalEvents) {
    if (totalEvents == 0) return 0;
    return dribbles / totalEvents;
  }

  double _involvementBalance(Iterable<GameEventInput> passes, Iterable<String> playerIds) {
    final ids = playerIds.toList();
    if (passes.isEmpty || ids.isEmpty) return 1;

    final counts = {for (final id in ids) id: 0};
    for (final pass in passes) {
      counts.update(pass.playerId, (value) => value + 1, ifAbsent: () => 1);
    }

    return 1 - _gini(counts.values.map((value) => value.toDouble()).toList());
  }

  double _linkedShotRate(List<GameEventInput> shots) {
    if (shots.isEmpty) return 0;

    final linked =
        shots.where((shot) => shot.passChainLength >= _shortChainThreshold).length;
    return linked / shots.length;
  }

  List<PassingStat> _passingLeaders(TeamInput team, List<GameEventInput> passes) {
    final counts = <String, int>{};
    for (final pass in passes) {
      counts.update(pass.playerId, (value) => value + 1, ifAbsent: () => 1);
    }

    final total = passes.isEmpty ? 1 : passes.length;
    final stats = counts.entries.map((entry) {
      final player = team.playerById(entry.key);
      return PassingStat(
        name: player?.name ?? entry.key,
        involvement: entry.value / total,
      );
    }).toList()
      ..sort((a, b) => b.involvement.compareTo(a.involvement));

    return stats.take(4).toList();
  }

  ({String name, double share}) _topShooter(TeamInput team, List<GameEventInput> shots) {
    if (shots.isEmpty) {
      return (name: 'No shooter', share: 0);
    }

    final counts = <String, int>{};
    for (final shot in shots) {
      counts.update(shot.playerId, (value) => value + 1, ifAbsent: () => 1);
    }

    final topEntry = counts.entries.reduce(
      (best, entry) => entry.value > best.value ? entry : best,
    );
    final player = team.playerById(topEntry.key);

    return (
      name: player?.name ?? topEntry.key,
      share: topEntry.value / shots.length,
    );
  }

  String _trendLabel(double heroBallPercent) {
    if (heroBallPercent >= 60) {
      return 'Hero-ball trending ↑ — play is concentrating on individual actions';
    }
    if (heroBallPercent <= 40) {
      return 'Team-ball trending ↑ — passing and shared chances are strong';
    }
    return 'Balanced tendencies — monitor shot and pass distribution';
  }

  String _weeklySummary({
    required ({String name, double share}) topShooter,
    required double shotConcentration,
    required double shortChainRate,
    required double linkedShotRate,
    required bool hasShots,
  }) {
    if (!hasShots) {
      return 'Log match events to generate your weekly cohesion report.';
    }

    final topShare = (topShooter.share * 100).round();
    final shortChain = (shortChainRate * 100).round();
    final linked = (linkedShotRate * 100).round();

    return '${topShooter.name} took $topShare% of team shots. '
        '$shortChain% of chances came from direct play (<3 passes), '
        'while $linked% followed linked build-up through midfield.';
  }

  List<String> _practiceNudges({
    required double heroBallPercent,
    required double shortChainRate,
    required ({String name, double share}) topShooter,
    required List<PassingStat> passingLeaders,
  }) {
    final nudges = <String>[];

    if (heroBallPercent >= 55 || shortChainRate >= 0.5) {
      nudges.add(
        'Run 4v4+2 rondos — reward 3-pass build-up before shooting on goal',
      );
    }

    if (topShooter.share >= 0.35) {
      nudges.add(
        'Limit ${topShooter.name.split(' ').first}\'s isolation in the final third; emphasize combination play',
      );
    }

    if (passingLeaders.length >= 2) {
      final secondary = passingLeaders[1].name.split(' ').first;
      nudges.add(
        'Pair ${topShooter.name.split(' ').first} with $secondary in link-up and overlap drills',
      );
    }

    if (nudges.isEmpty) {
      nudges.add('Add players and log match events to get training nudges');
    }

    return nudges;
  }

  double _gini(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final n = sorted.length;
    var numerator = 0.0;
    for (var i = 0; i < n; i++) {
      numerator += (2 * (i + 1) - n - 1) * sorted[i];
    }
    final denominator = n * sorted.reduce((a, b) => a + b);
    if (denominator == 0) return 0;
    return numerator / denominator;
  }

  double _clamp01(double value) => value.clamp(0.0, 1.0);
}
