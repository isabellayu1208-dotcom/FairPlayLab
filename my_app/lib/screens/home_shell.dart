import 'package:flutter/material.dart';

import '../data/firebase_team_repository.dart';
import '../data/local_team_repository.dart';
import '../state/team_controller.dart';
import '../widgets/log_match_event_sheet.dart';
import 'cohesion_screen.dart';
import 'dashboard_screen.dart';
import 'rotation_screen.dart';
import 'setup_screen.dart';
import 'study_support_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final TeamController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 3;

  static const _titles = [
    'Squad overview',
    'Subs & rotation',
    'Cohesion',
    'Enter data',
    'Study support',
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _goToTab(int index) {
    setState(() => _index = index);
  }

  void _openLogEventSheet() {
    showLogMatchEventSheet(context, widget.controller);
  }

  Widget _buildBody(TeamController controller) {
    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return Center(child: Text('Failed to load squad data: ${controller.error}'));
    }

    final snapshot = controller.snapshot;
    if (snapshot == null) {
      return const Center(child: Text('No squad data available'));
    }

    return IndexedStack(
      index: _index,
      children: [
        DashboardScreen(
          key: const ValueKey('dashboard-tab'),
          snapshot: snapshot,
          teamName: controller.team?.name ?? 'My Squad',
          atRiskCount: controller.atRiskAthleteCount,
          hasWellnessData: controller.hasWellnessData,
          onNavigate: _goToTab,
        ),
        RotationScreen(
          key: const ValueKey('rotation-tab'),
          snapshot: snapshot,
          onAddData: () => _goToTab(3),
        ),
        CohesionScreen(
          key: const ValueKey('cohesion-tab'),
          snapshot: snapshot,
          onAddData: () => _goToTab(3),
        ),
        SetupScreen(
          key: const ValueKey('setup-tab'),
          controller: controller,
        ),
        StudySupportScreen(
          key: const ValueKey('study-tab'),
          controller: controller,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sports_soccer, size: 22),
            const SizedBox(width: 8),
            Flexible(child: Text(_titles[_index])),
          ],
        ),
        actions: [
          if (!controller.loading &&
              controller.error == null &&
              _index == 1 &&
              controller.activeMatch != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${controller.activeMatch!.events.length} events',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          if (!controller.loading && controller.error == null && _index != 3)
            IconButton(
              onPressed: () => _goToTab(3),
              icon: const Icon(Icons.edit_note_outlined),
              tooltip: 'Enter data',
            ),
        ],
      ),
      body: _buildBody(controller),
      bottomNavigationBar: controller.loading || controller.error != null
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _goToTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Squad',
                ),
                NavigationDestination(
                  icon: Icon(Icons.swap_horiz),
                  selectedIcon: Icon(Icons.swap_horiz),
                  label: 'Subs',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pie_chart_outline),
                  selectedIcon: Icon(Icons.pie_chart),
                  label: 'Cohesion',
                ),
                NavigationDestination(
                  icon: Icon(Icons.edit_note_outlined),
                  selectedIcon: Icon(Icons.edit_note),
                  label: 'Data',
                ),
                NavigationDestination(
                  icon: Icon(Icons.school_outlined),
                  selectedIcon: Icon(Icons.school),
                  label: 'Study',
                ),
              ],
            ),
      floatingActionButton: !controller.loading &&
              controller.error == null &&
              _index == 1
          ? FloatingActionButton.extended(
              onPressed: controller.hasPlayers ? _openLogEventSheet : () => _goToTab(3),
              icon: Icon(controller.hasPlayers ? Icons.sports_soccer : Icons.person_add),
              label: Text(controller.hasPlayers ? 'Log match event' : 'Add players'),
            )
          : null,
    );
  }
}

class FairPlayAppScope extends StatefulWidget {
  const FairPlayAppScope({super.key, this.useFirebase = false});

  final bool useFirebase;

  @override
  State<FairPlayAppScope> createState() => _FairPlayAppScopeState();
}

class _FairPlayAppScopeState extends State<FairPlayAppScope> {
  late final TeamController _controller = TeamController(
    repository: widget.useFirebase
        ? FirebaseTeamRepository()
        : LocalTeamRepository(),
  );

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeShell(controller: _controller);
  }
}
