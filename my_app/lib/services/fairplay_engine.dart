import '../models/analytics.dart';
import '../models/inputs.dart';
import 'cohesion_calculator.dart';
import 'fairness_calculator.dart';

class FairPlayEngine {
  FairPlayEngine({
    FairnessCalculator? fairnessCalculator,
    CohesionCalculator? cohesionCalculator,
  })  : _fairnessCalculator = fairnessCalculator ?? FairnessCalculator(),
        _cohesionCalculator = cohesionCalculator ?? CohesionCalculator();

  final FairnessCalculator _fairnessCalculator;
  final CohesionCalculator _cohesionCalculator;

  FairPlaySnapshot analyze(TeamInput team) {
    final rotations = _fairnessCalculator.computeRotations(team);
    final fairnessMetrics = _fairnessCalculator.computeTeamMetrics(team);
    final cohesion = _cohesionCalculator.compute(team);

    final rpeValues = team.rpe.map((record) => record.average).toList();
    final averageRpe = rpeValues.isEmpty
        ? 0.0
        : rpeValues.reduce((a, b) => a + b) / rpeValues.length;

    return FairPlaySnapshot(
      rotations: rotations,
      fairnessMetrics: fairnessMetrics,
      cohesion: cohesion,
      averageRpe: averageRpe,
    );
  }
}
