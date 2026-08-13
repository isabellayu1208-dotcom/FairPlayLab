import 'package:flutter/material.dart';

import '../models/analytics.dart';
import '../theme/app_theme.dart';

class DashboardMetric {
  const DashboardMetric({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

const mockTemplates = [
  'Hi [Parent], we noticed [Athlete] has had elevated training load and reduced sleep this week. We\'re adjusting practice intensity and wanted to share our plan…',
  'Team update: This week\'s sub decisions prioritize squad fairness and recovery. Here\'s how pitch time was allocated and why…',
  'Study-support check-in: [Athlete] flagged for academic sustainability. Suggested schedule attached — please reach out with questions.',
];

List<DashboardMetric> buildDashboardMetrics(
  FairPlaySnapshot snapshot, {
  int atRiskCount = 0,
  bool hasWellnessData = false,
}) {
  final fairness = (snapshot.fairnessMetrics.fairnessIndex * 100).round();
  final cohesion = snapshot.cohesion.cohesionScore.round();

  final avgRpeLabel = snapshot.averageRpe > 0
      ? snapshot.averageRpe.toStringAsFixed(1)
      : '—';

  return [
    DashboardMetric(
      label: 'Fairness index',
      value: '$fairness%',
      subtitle: snapshot.fairnessMetrics.fairnessIndex > 0
          ? 'Computed from match minutes, starts & bench subs'
          : 'Log match minutes on the Data tab',
      icon: Icons.balance,
      color: AppColors.accent,
    ),
    DashboardMetric(
      label: 'Avg RPE',
      value: avgRpeLabel,
      subtitle: snapshot.averageRpe > 0
          ? 'Team recovery signal'
          : 'Log RPE on the Data tab',
      icon: Icons.favorite_border,
      color: const Color(0xFF457B9D),
    ),
    DashboardMetric(
      label: 'Cohesion score',
      value: '$cohesion',
      subtitle: snapshot.cohesion.heroBallPercent >= 55
          ? 'Hero-ball bias detected'
          : 'Team-ball tendencies strong',
      icon: Icons.groups_outlined,
      color: AppColors.heroBall,
    ),
    DashboardMetric(
      label: 'At-risk athletes',
      value: '$atRiskCount',
      subtitle: hasWellnessData
          ? 'Academic crash risk flagged'
          : 'Enter after-school study data on Study tab',
      icon: Icons.school_outlined,
      color: AppColors.danger,
    ),
  ];
}
