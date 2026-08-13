class WhyFactor {
  const WhyFactor({
    required this.label,
    required this.detail,
    required this.impact,
  });

  final String label;
  final String detail;
  final String impact;
}

class PlayerRotation {
  const PlayerRotation({
    required this.playerId,
    required this.name,
    required this.position,
    required this.minMinutes,
    required this.maxMinutes,
    required this.attendance,
    required this.rpe,
    required this.fairnessScore,
    required this.status,
    required this.whyFactors,
  });

  final String playerId;
  final String name;
  final String position;
  final int minMinutes;
  final int maxMinutes;
  final double attendance;
  final double rpe;
  final double fairnessScore;
  final String status;
  final List<WhyFactor> whyFactors;
}

class TeamFairnessMetrics {
  const TeamFairnessMetrics({
    required this.minutesEquity,
    required this.starterRotationBalance,
    required this.benchOpportunityRate,
    required this.fairnessIndex,
  });

  final double minutesEquity;
  final double starterRotationBalance;
  final double benchOpportunityRate;
  final double fairnessIndex;
}

class PassingStat {
  const PassingStat({required this.name, required this.involvement});

  final String name;
  final double involvement;
}

class CohesionReport {
  const CohesionReport({
    required this.heroBallPercent,
    required this.teamBallPercent,
    required this.cohesionScore,
    required this.trendLabel,
    required this.weeklySummary,
    required this.passingLeaders,
    required this.practiceNudges,
  });

  final double heroBallPercent;
  final double teamBallPercent;
  final double cohesionScore;
  final String trendLabel;
  final String weeklySummary;
  final List<PassingStat> passingLeaders;
  final List<String> practiceNudges;
}

class FairPlaySnapshot {
  const FairPlaySnapshot({
    required this.rotations,
    required this.fairnessMetrics,
    required this.cohesion,
    required this.averageRpe,
  });

  final List<PlayerRotation> rotations;
  final TeamFairnessMetrics fairnessMetrics;
  final CohesionReport cohesion;
  final double averageRpe;
}
