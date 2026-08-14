import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inputs.dart';
import '../models/team_serializers.dart';
import 'empty_team.dart';
import 'team_repository.dart';

/// Stores one squad per Firestore document so a coach can pick up the same
/// season data on any device.
class FirebaseTeamRepository implements TeamRepository {
  FirebaseTeamRepository({
    FirebaseFirestore? firestore,
    this.teamId = defaultTeamId,
    TeamInput? seed,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _seed = seed ?? emptyTeam;

  final FirebaseFirestore _firestore;
  final String teamId;
  final TeamInput _seed;

  static const defaultTeamId = 'default';
  static const _collection = 'teams';
  static const _teamField = 'team';
  static const _activeMatchField = 'activeMatchId';
  static const _updatedAtField = 'updatedAt';

  DocumentReference<Map<String, dynamic>> get _document =>
      _firestore.collection(_collection).doc(teamId);

  @override
  Future<TeamInput> loadTeam() async {
    final snapshot = await _document.get();
    final stored = snapshot.data()?[_teamField];

    if (stored is! Map) {
      await saveTeam(_seed);
      return _seed;
    }

    return teamInputFromJson(Map<String, dynamic>.from(stored));
  }

  @override
  Future<void> saveTeam(TeamInput team) async {
    await _document.set(
      {
        _teamField: teamInputToJson(team),
        _updatedAtField: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<String?> getActiveMatchId() async {
    final snapshot = await _document.get();
    final id = snapshot.data()?[_activeMatchField] as String?;
    if (id == null || id.isEmpty) return null;
    return id;
  }

  @override
  Future<void> setActiveMatchId(String matchId) async {
    await _document.set(
      {_activeMatchField: matchId},
      SetOptions(merge: true),
    );
  }
}
