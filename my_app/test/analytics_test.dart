import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/data/sample_team.dart';
import 'package:my_app/models/soccer.dart';
import 'package:my_app/services/cohesion_calculator.dart';
import 'package:my_app/services/fairness_calculator.dart';
import 'package:my_app/services/fairplay_engine.dart';

void main() {
  group('FairnessCalculator', () {
    final calculator = FairnessCalculator();

    test('computes team fairness metrics within valid range', () {
      final metrics = calculator.computeTeamMetrics(sampleTeam);

      expect(metrics.minutesEquity, inInclusiveRange(0, 1));
      expect(metrics.starterRotationBalance, inInclusiveRange(0, 1));
      expect(metrics.benchOpportunityRate, inInclusiveRange(0, 1));
      expect(metrics.fairnessIndex, inInclusiveRange(0, 1));
    });

    test('flags Alex as monitor due to high RPE and heavy minutes', () {
      final rotations = calculator.computeRotations(sampleTeam);
      final alex = rotations.firstWhere((player) => player.playerId == 'alex');

      expect(alex.status, 'Monitor');
      expect(alex.maxMinutes, lessThanOrEqualTo(20));
      expect(alex.whyFactors.any((factor) => factor.label == 'RPE recovery'), isTrue);
    });

    test('locks goalkeeper to full match minutes', () {
      final rotations = calculator.computeRotations(sampleTeam);
      final riley = rotations.firstWhere((player) => player.playerId == 'riley');

      expect(riley.minMinutes, SoccerConstants.matchLengthMinutes);
      expect(riley.maxMinutes, SoccerConstants.matchLengthMinutes);
      expect(riley.status, 'Starter');
    });
  });

  group('CohesionCalculator', () {
    final calculator = CohesionCalculator();

    test('hero-ball and team-ball percentages sum to 100', () {
      final report = calculator.compute(sampleTeam);

      expect(report.heroBallPercent + report.teamBallPercent, closeTo(100, 0.01));
      expect(report.heroBallPercent, greaterThan(50));
    });

    test('detects Alex as top shooting concentration', () {
      final report = calculator.compute(sampleTeam);

      expect(report.weeklySummary, contains('Alex'));
      expect(report.practiceNudges, isNotEmpty);
    });

    test('passing involvement is normalized', () {
      final report = calculator.compute(sampleTeam);
      final total = report.passingLeaders
          .map((stat) => stat.involvement)
          .fold<double>(0, (sum, value) => sum + value);

      expect(total, lessThanOrEqualTo(1.01));
      expect(report.passingLeaders.first.name, 'Jordan M.');
    });
  });

  group('FairPlayEngine', () {
    test('returns a complete snapshot', () {
      final snapshot = FairPlayEngine().analyze(sampleTeam);

      expect(snapshot.rotations, isNotEmpty);
      expect(snapshot.fairnessMetrics.fairnessIndex, greaterThan(0));
      expect(snapshot.cohesion.cohesionScore, inInclusiveRange(0, 100));
      expect(snapshot.averageRpe, greaterThan(0));
    });
  });
}
