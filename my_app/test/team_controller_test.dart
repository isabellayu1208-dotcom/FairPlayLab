import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/data/sample_team.dart';
import 'package:my_app/data/team_repository.dart';
import 'package:my_app/models/inputs.dart';
import 'package:my_app/state/team_controller.dart';

class MemoryTeamRepository implements TeamRepository {
  MemoryTeamRepository(this._team);

  TeamInput _team;
  String? _activeMatchId;

  @override
  Future<TeamInput> loadTeam() async => _team;

  @override
  Future<void> saveTeam(TeamInput team) async => _team = team;

  @override
  Future<String?> getActiveMatchId() async => _activeMatchId;

  @override
  Future<void> setActiveMatchId(String matchId) async => _activeMatchId = matchId;
}

void main() {
  test('logging match appearance updates fairness index', () async {
    final repository = MemoryTeamRepository(sampleTeam);
    final controller = TeamController(repository: repository);

    await controller.initialize();
    await controller.startNewMatch();
    await controller.logMatchAppearance(
      playerId: 'jordan',
      minutesPlayed: 60,
      started: true,
    );
    await controller.logMatchAppearance(
      playerId: 'alex',
      minutesPlayed: 45,
      started: true,
    );

    expect(controller.hasMatchAppearances, isTrue);
    expect(controller.snapshot!.fairnessMetrics.fairnessIndex, greaterThan(0));
  });

  test('updateWellness auto-calculates high crash risk', () async {
    final repository = MemoryTeamRepository(sampleTeam);
    final controller = TeamController(repository: repository);

    await controller.initialize();
    await controller.updateWellness(
      playerId: 'alex',
      trainingLoad: 0,
      sleepHours: 5,
      studyHours: 10,
    );

    expect(controller.hasWellnessData, isTrue);
    expect(controller.atRiskAthleteCount, 1);
    expect(controller.wellnessFor('alex')?.effectiveCrashRisk, CrashRisk.high);
  });
}
