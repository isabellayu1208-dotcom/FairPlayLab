import 'package:flutter/material.dart';

import '../models/inputs.dart';
import '../models/soccer.dart';
import '../state/team_controller.dart';
import '../theme/app_theme.dart';

Future<void> showLogMatchEventSheet(
  BuildContext context,
  TeamController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LogMatchEventSheet(controller: controller),
  );
}

class LogMatchEventSheet extends StatefulWidget {
  const LogMatchEventSheet({super.key, required this.controller});

  final TeamController controller;

  @override
  State<LogMatchEventSheet> createState() => _LogMatchEventSheetState();
}

class _LogMatchEventSheetState extends State<LogMatchEventSheet> {
  String? _playerId;
  GameEventType _eventType = GameEventType.pass;
  int _passChainLength = 1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    final players = widget.controller.team?.players ?? [];
    if (players.isNotEmpty) {
      _playerId = players.first.id;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final playerId = _playerId;
    if (playerId == null || _saving) return;

    setState(() => _saving = true);

    await widget.controller.logMatchEvent(
      GameEventInput(
        playerId: playerId,
        type: _eventType,
        passChainLength: _eventType == GameEventType.shot ? _passChainLength : 0,
      ),
    );

    if (!mounted) return;

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event logged — keep adding or tap Done'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.controller.team;
    final activeMatch = widget.controller.activeMatch;
    final fieldPlayers =
        team?.players.where((player) => !player.isGoalkeeper).toList() ?? [];

    if (fieldPlayers.isEmpty) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.3,
        minChildSize: 0.25,
        maxChildSize: 0.4,
        builder: (context, scrollController) => Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Add players on the Data tab before logging match events.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ),
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Log match event',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                activeMatch == null
                    ? 'Events will start a new live match log'
                    : 'Logging to ${activeMatch.id} · ${activeMatch.events.length} events',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        await widget.controller.startNewMatch();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('New live match started')),
                        );
                      },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Start new live match'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Player',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _playerId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: fieldPlayers
                    .map(
                      (player) => DropdownMenuItem(
                        value: player.id,
                        child: Text(
                          '${player.name} (${SoccerPositions.display(player.position)})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _saving ? null : (value) => setState(() => _playerId = value),
              ),
              const SizedBox(height: 20),
              const Text(
                'Event type',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GameEventType.values.map((type) {
                  final selected = _eventType == type;
                  return ChoiceChip(
                    label: Text(_eventLabel(type)),
                    selected: selected,
                    onSelected: _saving
                        ? null
                        : (_) => setState(() => _eventType = type),
                    selectedColor: AppColors.accent.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              if (_eventType == GameEventType.shot) ...[
                const SizedBox(height: 20),
                Text(
                  'Passes before shot: $_passChainLength',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: _passChainLength.toDouble(),
                  min: 1,
                  max: 6,
                  divisions: 5,
                  label: '$_passChainLength',
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _passChainLength = value.round()),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Log event'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _eventLabel(GameEventType type) {
    return switch (type) {
      GameEventType.pass => 'Pass',
      GameEventType.shot => 'Shot',
      GameEventType.dribble => 'Take-on',
      GameEventType.clearance => 'Clearance',
    };
  }
}
