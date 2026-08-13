import '../models/inputs.dart';

/// Data access for squad and match logs.
/// Swap [LocalTeamRepository] for a Firebase implementation later.
abstract class TeamRepository {
  Future<TeamInput> loadTeam();

  Future<void> saveTeam(TeamInput team);

  Future<String?> getActiveMatchId();

  Future<void> setActiveMatchId(String matchId);
}
