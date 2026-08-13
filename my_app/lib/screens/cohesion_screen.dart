import 'package:flutter/material.dart';

import '../models/analytics.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class CohesionScreen extends StatelessWidget {
  const CohesionScreen({
    super.key,
    required this.snapshot,
    required this.onAddData,
  });

  final FairPlaySnapshot snapshot;
  final VoidCallback onAddData;

  @override
  Widget build(BuildContext context) {
    final report = snapshot.cohesion;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(
          title: 'Squad cohesion',
          subtitle: 'Build-up play, passing involvement & chance creation',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hero-ball vs Team-ball',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'From shot share, pass chains, take-ons & midfield involvement',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TendencyGauge(
                        label: 'Hero-ball',
                        percent: report.heroBallPercent,
                        color: AppColors.heroBall,
                        icon: Icons.sports_soccer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TendencyGauge(
                        label: 'Team-ball',
                        percent: report.teamBallPercent,
                        color: AppColors.teamBall,
                        icon: Icons.groups_2_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InfoBanner(
                  icon: Icons.trending_up,
                  message: report.trendLabel,
                  color: AppColors.heroBall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (report.passingLeaders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.sports_soccer, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text(
                    'No match data yet',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'On the Data tab, start a match and log passes, shots, and take-ons to see cohesion insights here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onAddData,
                    child: const Text('Enter match data'),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Passing involvement',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...report.passingLeaders.map(
                    (stat) => SimpleBarChart(
                      label: stat.name,
                      value: stat.involvement,
                      color: AppColors.teamBall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly match report',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(report.weeklySummary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(
          title: 'Training nudges',
          subtitle: 'Soccer drills based on cohesion diagnosis',
        ),
        const SizedBox(height: 8),
        ...report.practiceNudges.map(
          (nudge) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                child: const Icon(Icons.sports_soccer, color: AppColors.accent),
              ),
              title: Text(nudge),
            ),
          ),
        ),
      ],
    );
  }
}

class _TendencyGauge extends StatelessWidget {
  const _TendencyGauge({
    required this.label,
    required this.percent,
    required this.color,
    required this.icon,
  });

  final String label;
  final double percent;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            '${percent.round()}%',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
