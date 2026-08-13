import 'dart:async';

import 'package:flutter/material.dart';

import '../models/inputs.dart';
import '../models/soccer.dart';
import '../state/team_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/log_match_event_sheet.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.controller});

  final TeamController controller;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final TextEditingController _teamNameController;

  @override
  void initState() {
    super.initState();
    _teamNameController = TextEditingController(text: widget.controller.team?.name ?? '');
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _addPlayer() async {
    final result = await showDialog<({String name, String position, PlayerRole role})>(
      context: context,
      builder: (context) => const _AddPlayerDialog(),
    );

    if (result == null || result.name.isEmpty || !mounted) return;

    // Let the dialog route finish disposing before rebuilding the page.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    await widget.controller.addPlayer(
      name: result.name,
      position: result.position,
      role: result.role,
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all squad data?'),
        content: const Text(
          'This clears your squad name, players, training logs, and match events. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.controller.resetSquad();
      _teamNameController.text = widget.controller.team?.name ?? '';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Squad data cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final team = controller.team;

    if (team == null) {
      return const Center(child: Text('Loading…'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(
          title: 'Enter your data',
          subtitle: 'Complete each step — insights update as you go',
        ),
        const SizedBox(height: 12),
        _ProgressCard(controller: controller),
        const SizedBox(height: 20),
        _StepCard(
          key: const ValueKey('step-1'),
          step: 1,
          title: 'Squad name',
          done: team.name.trim().isNotEmpty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _teamNameController,
                decoration: const InputDecoration(
                  labelText: 'Team name',
                  hintText: 'e.g. Riverside Hawks · Varsity Girls Soccer',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: controller.updateTeamName,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => controller.updateTeamName(_teamNameController.text),
                child: const Text('Save squad name'),
              ),
            ],
          ),
        ),
        _StepCard(
          key: const ValueKey('step-2'),
          step: 2,
          title: 'Players',
          done: controller.hasPlayers,
          child: Column(
            children: [
              if (team.players.isEmpty)
                const Text(
                  'No players yet. Add your full roster before logging training or match data.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ...team.players.map(
                (player) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(player.name),
                    subtitle: Text(SoccerPositions.display(player.position)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                      onPressed: () => controller.removePlayer(player.id),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addPlayer,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add player'),
              ),
            ],
          ),
        ),
        _StepCard(
          key: const ValueKey('step-3'),
          step: 3,
          title: 'Training attendance',
          done: controller.hasAttendanceData,
          child: team.players.isEmpty
              ? const Text(
                  'Add players first.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              : Column(
                  children: team.players.map((player) {
                    final record = controller.attendanceFor(player.id);
                    return _AttendanceEditor(
                      key: ValueKey(player.id),
                      playerName: player.name,
                      attended: record?.sessionsAttended ?? 0,
                      total: record?.sessionsTotal ?? 0,
                      onSave: (attended, total) => controller.updateAttendance(
                        playerId: player.id,
                        sessionsAttended: attended,
                        sessionsTotal: total,
                      ),
                    );
                  }).toList(),
                ),
        ),
        _StepCard(
          key: const ValueKey('step-4'),
          step: 4,
          title: 'RPE (perceived effort)',
          done: controller.hasRpeData,
          child: team.players.isEmpty
              ? const Text(
                  'Add players first.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const InfoBanner(
                      icon: Icons.favorite_border,
                      message:
                          'After each training session, ask: “How hard was practice today?” Log the player’s answer from 1 (very easy) to 10 (max effort). FairPlay keeps the last 7 daily ratings to track recovery and guide subs.',
                    ),
                    const SizedBox(height: 12),
                    const _RpeScaleGuide(),
                    const SizedBox(height: 16),
                    ...team.players.map((player) {
                      final record = controller.rpeFor(player.id);
                      return _RpeEditor(
                        key: ValueKey('rpe-${player.id}'),
                        playerName: player.name,
                        recentValues: record?.dailyValues ?? [],
                        onLog: (value) => controller.logRpe(
                          playerId: player.id,
                          value: value,
                        ),
                      );
                    }),
                  ],
                ),
        ),
        _StepCard(
          key: const ValueKey('step-5'),
          step: 5,
          title: 'Match minutes & lineup',
          done: controller.hasMatchAppearances,
          child: team.players.isEmpty
              ? const Text(
                  'Add players first.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      controller.activeMatch == null
                          ? 'Start a match below, then log who started and how many minutes each player had.'
                          : 'Logging to ${controller.activeMatch!.id}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await controller.startNewMatch();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('New match started')),
                        );
                      },
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Start new match'),
                    ),
                    const SizedBox(height: 12),
                    ...team.players.map((player) {
                      final appearance = controller.appearanceFor(player.id);
                      return _MatchAppearanceEditor(
                        key: ValueKey('lineup-${player.id}'),
                        playerName: player.name,
                        position: player.position,
                        isGoalkeeper: player.isGoalkeeper,
                        matchLength: team.matchLengthMinutes,
                        started: appearance?.started ?? player.isGoalkeeper,
                        minutes: appearance?.minutesPlayed ?? (player.isGoalkeeper ? team.matchLengthMinutes : 0),
                        onSave: (started, minutes) => controller.logMatchAppearance(
                          playerId: player.id,
                          minutesPlayed: minutes,
                          started: started,
                        ),
                      );
                    }),
                  ],
                ),
        ),
        _StepCard(
          key: const ValueKey('step-6'),
          step: 6,
          title: 'Match events',
          done: controller.hasMatchEvents,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                controller.activeMatch == null
                    ? 'Start a match above, then log passes, shots, and take-ons.'
                    : 'Live match: ${controller.activeMatch!.id} · ${controller.activeMatch!.events.length} events logged',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: team.players.isEmpty
                    ? null
                    : () => showLogMatchEventSheet(context, controller),
                icon: const Icon(Icons.sports_soccer),
                label: const Text('Log match event'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _confirmReset,
          icon: const Icon(Icons.refresh, color: AppColors.danger),
          label: const Text(
            'Reset all data',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.controller});

  final TeamController controller;

  @override
  Widget build(BuildContext context) {
    final done = controller.setupStepsComplete;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${done} of 6 steps complete',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: done / 6,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.accent,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatefulWidget {
  const _StepCard({
    super.key,
    required this.step,
    required this.title,
    required this.done,
    required this.child,
  });

  final int step;
  final String title;
  final bool done;
  final Widget child;

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  late final bool _initiallyExpanded;

  @override
  void initState() {
    super.initState();
    _initiallyExpanded = !widget.done;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: _initiallyExpanded,
        leading: CircleAvatar(
          backgroundColor: widget.done
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.primary.withValues(alpha: 0.1),
          child: widget.done
              ? const Icon(Icons.check, color: AppColors.accent, size: 18)
              : Text('${widget.step}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _AddPlayerDialog extends StatefulWidget {
  const _AddPlayerDialog();

  @override
  State<_AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<_AddPlayerDialog> {
  final _nameController = TextEditingController();
  String _position = SoccerPositions.labels.keys.first;
  PlayerRole _role = PlayerRole.field;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, (name: name, position: _position, role: _role));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add player'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _position,
            decoration: const InputDecoration(
              labelText: 'Position',
              border: OutlineInputBorder(),
            ),
            items: SoccerPositions.labels.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text('${entry.key} · ${entry.value}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _position = value);
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<PlayerRole>(
            segments: const [
              ButtonSegment(
                value: PlayerRole.field,
                label: Text('Outfield'),
              ),
              ButtonSegment(
                value: PlayerRole.goalkeeper,
                label: Text('GK'),
              ),
            ],
            selected: {_role},
            onSelectionChanged: (selection) {
              setState(() => _role = selection.first);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _AttendanceEditor extends StatefulWidget {
  const _AttendanceEditor({
    super.key,
    required this.playerName,
    required this.attended,
    required this.total,
    required this.onSave,
  });

  final String playerName;
  final int attended;
  final int total;
  final Future<void> Function(int attended, int total) onSave;

  @override
  State<_AttendanceEditor> createState() => _AttendanceEditorState();
}

class _AttendanceEditorState extends State<_AttendanceEditor> {
  late int _attended;
  late int _total;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _attended = widget.attended;
    _total = widget.total;
  }

  @override
  void didUpdateWidget(covariant _AttendanceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _attended = widget.attended;
    _total = widget.total;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    if (_attended != widget.attended || _total != widget.total) {
      widget.onSave(_attended, _total);
    }
    super.dispose();
  }

  void _updateAttended(int value) {
    setState(() {
      _attended = value;
      if (_attended > _total) _total = _attended;
    });
    _scheduleSave();
  }

  void _updateTotal(int value) {
    setState(() {
      _total = value;
      if (_attended > _total) _attended = _total;
    });
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () {
      widget.onSave(_attended, _total);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.playerName, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    label: 'Attended',
                    value: _attended,
                    onChanged: _updateAttended,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    label: 'Total sessions',
                    value: _total,
                    onChanged: _updateTotal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RpeScaleGuide extends StatelessWidget {
  const _RpeScaleGuide();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RPE scale (1–10)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'One number per training day — not match minutes, not heart rate.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            _RpeScaleRow(range: '1–2', label: 'Very easy', color: AppColors.accent),
            _RpeScaleRow(range: '3–4', label: 'Light', color: const Color(0xFF457B9D)),
            _RpeScaleRow(range: '5–6', label: 'Moderate', color: AppColors.primary),
            _RpeScaleRow(range: '7–8', label: 'Hard', color: AppColors.warning),
            _RpeScaleRow(range: '9–10', label: 'Max effort', color: AppColors.danger),
          ],
        ),
      ),
    );
  }
}

class _RpeScaleRow extends StatelessWidget {
  const _RpeScaleRow({
    required this.range,
    required this.label,
    required this.color,
  });

  final String range;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              range,
              style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13),
            ),
          ),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

String _rpeEffortLabel(double value) {
  final rating = value.round().clamp(1, 10);
  return switch (rating) {
    1 || 2 => 'Very easy — recovery or rest day',
    3 || 4 => 'Light — could train much harder',
    5 || 6 => 'Moderate — solid session, still fresh',
    7 || 8 => 'Hard — legs heavy, needs monitoring',
    9 || 10 => 'Max effort — very demanding day',
    _ => 'Select today’s effort',
  };
}

class _RpeEditor extends StatefulWidget {
  const _RpeEditor({
    super.key,
    required this.playerName,
    required this.recentValues,
    required this.onLog,
  });

  final String playerName;
  final List<double> recentValues;
  final Future<void> Function(double value) onLog;

  @override
  State<_RpeEditor> createState() => _RpeEditorState();
}

class _RpeEditorState extends State<_RpeEditor> {
  double _value = 6;

  @override
  Widget build(BuildContext context) {
    final recent = widget.recentValues;
    final avg = recent.isEmpty
        ? null
        : recent.reduce((a, b) => a + b) / recent.length;
    final latest = recent.isEmpty ? null : recent.last;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.playerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              latest == null
                  ? 'No sessions logged yet'
                  : 'Latest: ${latest.toStringAsFixed(1)} · 7-day avg: ${avg!.toStringAsFixed(1)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log today’s training effort',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _value.round().toString(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 6),
                        child: Text('/ 10', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  Text(
                    _rpeEffortLabel(_value),
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Slider(
              value: _value,
              min: 1,
              max: 10,
              divisions: 9,
              label: _value.round().toString(),
              onChanged: (value) => setState(() => _value = value),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 · easy', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text('10 · max', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            if (recent.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Last 7 training days (oldest → newest)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(recent.length, (index) {
                  final isLatest = index == recent.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLatest
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isLatest ? AppColors.accent : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      'Day ${index + 1}: ${recent[index].toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isLatest ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => widget.onLog(_value),
                icon: const Icon(Icons.add_chart_outlined, size: 18),
                label: Text('Log ${_value.round()} for today'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchAppearanceEditor extends StatefulWidget {
  const _MatchAppearanceEditor({
    super.key,
    required this.playerName,
    required this.position,
    required this.isGoalkeeper,
    required this.matchLength,
    required this.started,
    required this.minutes,
    required this.onSave,
  });

  final String playerName;
  final String position;
  final bool isGoalkeeper;
  final int matchLength;
  final bool started;
  final int minutes;
  final Future<void> Function(bool started, int minutes) onSave;

  @override
  State<_MatchAppearanceEditor> createState() => _MatchAppearanceEditorState();
}

class _MatchAppearanceEditorState extends State<_MatchAppearanceEditor> {
  late bool _started;
  late int _minutes;
  late final TextEditingController _minutesController;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _started = widget.started;
    _minutes = widget.minutes;
    _minutesController = TextEditingController(text: '$_minutes');
  }

  @override
  void didUpdateWidget(covariant _MatchAppearanceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _started = widget.started;
    _minutes = widget.minutes;
    _minutesController.text = '$_minutes';
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    if (_hasUnsavedChanges) {
      _persist();
    }
    _minutesController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final minutes = _currentMinutes;
    final started = widget.isGoalkeeper ? true : _started;
    return minutes != widget.minutes || started != widget.started;
  }

  int get _currentMinutes {
    return (int.tryParse(_minutesController.text) ?? _minutes).clamp(0, widget.matchLength);
  }

  void _updateStarted(bool value) {
    setState(() => _started = value);
    _scheduleSave();
  }

  void _updateMinutes(int value) {
    setState(() => _minutes = value.clamp(0, widget.matchLength));
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), _persist);
  }

  void _persist() {
    widget.onSave(
      widget.isGoalkeeper ? true : _started,
      _currentMinutes,
    );
  }

  String get _roleLabel {
    final minutes = _currentMinutes;
    if (minutes == 0) return 'Did not play';
    if (_started || widget.isGoalkeeper) return 'Starter';
    return 'Sub';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.playerName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${SoccerPositions.display(widget.position)} · $_roleLabel',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.isGoalkeeper)
                  Row(
                    children: [
                      const Text('Started', style: TextStyle(fontSize: 13)),
                      Switch(
                        value: _started,
                        onChanged: _updateStarted,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Minutes played (0–${widget.matchLength})',
                border: const OutlineInputBorder(),
                helperText: widget.isGoalkeeper
                    ? 'Goalkeepers typically play the full match'
                    : '0 = did not play · starter or sub · saves automatically',
              ),
              onChanged: (text) {
                final parsed = int.tryParse(text);
                if (parsed != null) {
                  _updateMinutes(parsed);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != '${widget.value}') {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (text) {
        final parsed = int.tryParse(text);
        if (parsed != null) widget.onChanged(parsed.clamp(0, 999));
      },
    );
  }
}
