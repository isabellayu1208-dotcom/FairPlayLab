import '../models/inputs.dart';

/// Estimates academic crash risk from weekly training load, sleep, and after-school study hours.
class WellnessRiskCalculator {
  static CrashRisk calculate({
    required int trainingLoad,
    required double sleepHours,
    required double studyHours,
  }) {
    if (trainingLoad == 0 && sleepHours == 0 && studyHours == 0) {
      return CrashRisk.low;
    }

    var score = 0.0;

    if (sleepHours > 0) {
      if (sleepHours < 5.5) {
        score += 4;
      } else if (sleepHours < 6.5) {
        score += 3;
      } else if (sleepHours < 7) {
        score += 2;
      } else if (sleepHours < 7.5) {
        score += 1;
      }
    } else if (trainingLoad > 0 || studyHours > 0) {
      score += 0.5;
    }

    if (studyHours >= 9) {
      score += 4;
    } else if (studyHours >= 7) {
      score += 3;
    } else if (studyHours >= 5) {
      score += 2;
    } else if (studyHours >= 3.5) {
      score += 1;
    }

    if (trainingLoad >= 9) {
      score += 2;
    } else if (trainingLoad >= 7) {
      score += 1.5;
    } else if (trainingLoad >= 5) {
      score += 1;
    }

    // Compound strain: poor sleep + heavy study/training stacks quickly.
    if (sleepHours > 0 && sleepHours < 7 && studyHours >= 4) {
      score += 2;
    }
    if (sleepHours > 0 && sleepHours < 6 && studyHours >= 6) {
      score += 2;
    }
    if (sleepHours > 0 && sleepHours < 7 && trainingLoad >= 6) {
      score += 1.5;
    }
    if (studyHours >= 5 && trainingLoad >= 6) {
      score += 1;
    }

    if (score >= 5) return CrashRisk.high;
    if (score >= 2.5) return CrashRisk.moderate;
    return CrashRisk.low;
  }
}
