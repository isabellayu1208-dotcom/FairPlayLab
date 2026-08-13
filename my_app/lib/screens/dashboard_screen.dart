import 'package:flutter/material.dart';

import '../models/analytics.dart';
import '../models/mock_data.dart';
import '../models/soccer.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.snapshot,
    required this.teamName,
    required this.atRiskCount,
    required this.hasWellnessData,
    required this.onNavigate,
  });

  final FairPlaySnapshot snapshot;
  final String teamName;
  final int atRiskCount;
  final bool hasWellnessData;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final metrics = buildDashboardMetrics(
      snapshot,
      atRiskCount: atRiskCount,
      hasWellnessData: hasWellnessData,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: const Icon(Icons.sports_soccer, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SoccerConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                  ),
                  Text(
                    SoccerConstants.appTagline,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          teamName,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        const InfoBanner(
          icon: Icons.insights_outlined,
          message:
              'Turn match attendance, RPE, and simple pitch events into explainable sub decisions, squad cohesion insights, and student-athlete support.',
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Squad snapshot',
          subtitle: 'From training attendance, RPE & logged match events',
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: metrics.map((metric) => MetricCard(metric: metric)).toList(),
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Quick actions',
          subtitle: 'Match-day tools for coaches',
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.edit_note_outlined,
          title: 'Enter squad data',
          subtitle: 'Players, attendance, RPE & match events',
          color: AppColors.primary,
          onTap: () => onNavigate(3),
        ),
        _ActionTile(
          icon: Icons.pie_chart_outline,
          title: 'Squad cohesion',
          subtitle: 'Hero-ball vs Team-ball on the pitch',
          color: AppColors.teamBall,
          onTap: () => onNavigate(2),
        ),
        _ActionTile(
          icon: Icons.menu_book_outlined,
          title: 'Study support',
          subtitle: 'Load, sleep, homework & crash risk',
          color: AppColors.warning,
          onTap: () => onNavigate(4),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly cohesion report',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(snapshot.cohesion.weeklySummary),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => onNavigate(2),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View full report'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
