import 'dart:async';

import 'package:flutter/material.dart';

import '../models/inputs.dart';
import '../models/mock_data.dart';
import '../services/wellness_risk_calculator.dart';
import '../state/team_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class StudySupportScreen extends StatelessWidget {
  const StudySupportScreen({super.key, required this.controller});

  final TeamController controller;

  @override
  Widget build(BuildContext context) {
    final team = controller.team;
    final players = team?.players ?? const [];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(
          title: 'Study support',
          subtitle: 'Training load, sleep & homework outside school',
        ),
        const SizedBox(height: 12),
        const InfoBanner(
          icon: Icons.schedule_outlined,
          message:
              'Log weekly training intensity, sleep, and homework/study time outside of school (not in-class hours). Changes save automatically. Crash risk is calculated from load, sleep, and after-school study.',
        ),
        const SizedBox(height: 20),
        if (players.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.school_outlined, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text(
                    'No players yet',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add players on the Data tab first, then return here to log study support data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ...players.map((player) {
            final wellness = controller.wellnessFor(player.id) ?? WellnessInput(playerId: player.id);
            return _WellnessCard(
              key: ValueKey('wellness-${player.id}'),
              playerName: player.name,
              wellness: wellness,
              onSave: (load, sleep, study) => controller.updateWellness(
                playerId: player.id,
                trainingLoad: load,
                sleepHours: sleep,
                studyHours: study,
              ),
            );
          }),
        const SizedBox(height: 8),
        const SectionHeader(
          title: 'Suggested schedule',
          subtitle: 'Personalized weekly balance (preview)',
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ScheduleRow(day: 'Mon', activity: 'Study block 4–5pm · Practice 5:30'),
                _ScheduleRow(day: 'Tue', activity: 'Light recovery · Study 7–8pm'),
                _ScheduleRow(day: 'Wed', activity: 'Match day · No extra study'),
                _ScheduleRow(day: 'Thu', activity: 'Reduced intensity practice · Early sleep'),
                _ScheduleRow(day: 'Fri', activity: 'Rest · Catch-up study 3–4pm'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(
          title: 'Communication templates',
          subtitle: 'Ready-to-send parent & athlete messages',
        ),
        const SizedBox(height: 8),
        ...mockTemplates.asMap().entries.map(
          (entry) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ExpansionTile(
              title: Text('Template ${entry.key + 1}'),
              subtitle: const Text('Tap to preview'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    entry.value,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WellnessCard extends StatefulWidget {
  const _WellnessCard({
    super.key,
    required this.playerName,
    required this.wellness,
    required this.onSave,
  });

  final String playerName;
  final WellnessInput wellness;
  final Future<void> Function(
    int trainingLoad,
    double sleepHours,
    double studyHours,
  ) onSave;

  @override
  State<_WellnessCard> createState() => _WellnessCardState();
}

class _WellnessCardState extends State<_WellnessCard> {
  late int _trainingLoad;
  late double _sleepHours;
  late double _studyHours;
  late final TextEditingController _sleepController;
  late final TextEditingController _studyController;
  Timer? _saveDebounce;

  CrashRisk get _previewRisk => WellnessRiskCalculator.calculate(
        trainingLoad: _trainingLoad,
        sleepHours: _sleepHours,
        studyHours: _studyHours,
      );

  bool get _hasLocalData => _trainingLoad > 0 || _sleepHours > 0 || _studyHours > 0;

  Color _riskColor(CrashRisk risk) {
    switch (risk) {
      case CrashRisk.high:
        return AppColors.danger;
      case CrashRisk.moderate:
        return AppColors.warning;
      case CrashRisk.low:
        return AppColors.accent;
    }
  }

  @override
  void initState() {
    super.initState();
    _applyWellness(widget.wellness);
    _sleepController = TextEditingController(text: _sleepHours.toStringAsFixed(1));
    _studyController = TextEditingController(text: _studyHours.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant _WellnessCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wellness != widget.wellness) {
      _applyWellness(widget.wellness);
      _sleepController.text = _sleepHours.toStringAsFixed(1);
      _studyController.text = _studyHours.toStringAsFixed(1);
    }
  }

  void _applyWellness(WellnessInput wellness) {
    _trainingLoad = wellness.trainingLoad;
    _sleepHours = wellness.sleepHours;
    _studyHours = wellness.studyHours;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    if (_hasUnsavedChanges) {
      _persist();
    }
    _sleepController.dispose();
    _studyController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final sleep = _currentSleep;
    final study = _currentStudy;
    return _trainingLoad != widget.wellness.trainingLoad ||
        sleep != widget.wellness.sleepHours ||
        study != widget.wellness.studyHours;
  }

  double get _currentSleep =>
      (double.tryParse(_sleepController.text) ?? _sleepHours).clamp(0, 24);

  double get _currentStudy =>
      (double.tryParse(_studyController.text) ?? _studyHours).clamp(0, 24);

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), _persist);
  }

  void _persist() {
    widget.onSave(_trainingLoad, _currentSleep, _currentStudy);
  }

  void _updateTrainingLoad(int value) {
    setState(() => _trainingLoad = value);
    _scheduleSave();
  }

  void _updateSleep(double value) {
    setState(() => _sleepHours = value.clamp(0, 24));
    _scheduleSave();
  }

  void _updateStudy(double value) {
    setState(() => _studyHours = value.clamp(0, 24));
    _scheduleSave();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.playerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                StatusChip(
                  label: '${_previewRisk.label} risk',
                  color: _riskColor(_previewRisk),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Training load (weekly intensity): $_trainingLoad / 10',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _trainingLoad.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$_trainingLoad',
              onChanged: (value) => _updateTrainingLoad(value.round()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sleepController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Sleep hours (avg/night)',
                      border: OutlineInputBorder(),
                      suffixText: 'h',
                    ),
                    onChanged: (text) {
                      final parsed = double.tryParse(text);
                      if (parsed != null) {
                        _updateSleep(parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _studyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Homework & study outside school (avg/day)',
                      helperText: 'Home study, tutoring, projects — not class time',
                      border: OutlineInputBorder(),
                      suffixText: 'h',
                    ),
                    onChanged: (text) {
                      final parsed = double.tryParse(text);
                      if (parsed != null) {
                        _updateStudy(parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Crash risk updates automatically from load, sleep, and after-school study. '
              'Low sleep plus heavy homework load increases risk quickly.',
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9)),
            ),
            if (_hasLocalData) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _WellnessPill(
                    icon: Icons.fitness_center,
                    label: 'Load',
                    value: '$_trainingLoad',
                  ),
                  const SizedBox(width: 8),
                  _WellnessPill(
                    icon: Icons.bedtime_outlined,
                    label: 'Sleep',
                    value: '${_currentSleep}h',
                  ),
                  const SizedBox(width: 8),
                  _WellnessPill(
                    icon: Icons.menu_book,
                    label: 'After-school',
                    value: '${_currentStudy}h',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.tips_and_updates_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _wellnessSuggestedAction(
                          widget.playerName,
                          _trainingLoad,
                          _currentSleep,
                          _currentStudy,
                          _previewRisk,
                        ),
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _wellnessSuggestedAction(
  String playerName,
  int trainingLoad,
  double sleepHours,
  double studyHours,
  CrashRisk risk,
) {
  switch (risk) {
    case CrashRisk.high:
      return '$playerName is flagged high risk — reduce training load, protect sleep, and schedule a parent check-in.';
    case CrashRisk.moderate:
      return '$playerName shows moderate strain — watch weekly load ($trainingLoad/10) and aim for ${sleepHours < 7 ? '7+ hours sleep' : 'lighter homework blocks outside school'}.';
    case CrashRisk.low:
      if (trainingLoad > 0 || sleepHours > 0 || studyHours > 0) {
        return '$playerName looks sustainable this week — keep balancing pitch time, recovery, and after-school study.';
      }
      return 'Log training load, sleep, and homework hours outside school to generate guidance.';
  }
}

class _WellnessPill extends StatelessWidget {
  const _WellnessPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.day, required this.activity});

  final String day;
  final String activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              day,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(child: Text(activity)),
        ],
      ),
    );
  }
}
