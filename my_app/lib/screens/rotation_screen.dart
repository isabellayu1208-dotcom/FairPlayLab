import 'package:flutter/material.dart';

import '../models/analytics.dart';
import '../models/soccer.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/why_explain_sheet.dart';

class RotationScreen extends StatelessWidget {
  const RotationScreen({
    super.key,
    required this.snapshot,
    required this.onAddData,
  });

  final FairPlaySnapshot snapshot;
  final VoidCallback onAddData;

  Color _statusColor(String status) {
    switch (status) {
      case 'Recommended':
        return AppColors.accent;
      case 'Monitor':
        return AppColors.warning;
      case 'Starter':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fairness = snapshot.fairnessMetrics;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(
          title: 'Sub & rotation guidance',
          subtitle:
              'Recommended minutes from attendance, RPE & squad fairness (${SoccerConstants.matchLengthMinutes}-min match)',
        ),
        const SizedBox(height: 12),
        const InfoBanner(
          icon: Icons.visibility_outlined,
          message:
              'Tap any player to open the Why-Explain card — every sub decision is auditable.',
        ),
        const SizedBox(height: 20),
        if (snapshot.rotations.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.people_outline, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text(
                    'No rotation data yet',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add players, then log training attendance and RPE on the Data tab. Pitch time recommendations appear only after that info is in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onAddData,
                    child: const Text('Enter squad data'),
                  ),
                ],
              ),
            ),
          )
        else
          ...snapshot.rotations.map(
          (player) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showWhyExplain(context, player),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            player.position,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${SoccerPositions.label(player.position)} · '
                                'Training ${(player.attendance * 100).round()}% · RPE ${player.rpe.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusChip(
                          label: player.status,
                          color: _statusColor(player.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: 'Pitch time',
                            value: player.minMinutes == player.maxMinutes
                                ? '${player.minMinutes} min'
                                : '${player.minMinutes}–${player.maxMinutes} min',
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: 'Minute priority',
                            value: '${(player.fairnessScore * 100).round()}%',
                          ),
                        ),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showWhyExplain(context, player),
                            icon: const Icon(Icons.help_outline, size: 16),
                            label: const Text('Why'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Squad fairness metrics',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'From recent match minutes, starting XI patterns & sub opportunities',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SimpleBarChart(
                  label: 'Minutes equity',
                  value: fairness.minutesEquity,
                  color: AppColors.accent,
                ),
                SimpleBarChart(
                  label: 'Starting XI rotation',
                  value: fairness.starterRotationBalance,
                  color: AppColors.primaryLight,
                ),
                SimpleBarChart(
                  label: 'Bench sub opportunity',
                  value: fairness.benchOpportunityRate,
                  color: AppColors.teamBall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
