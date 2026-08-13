import 'inputs.dart';
import 'soccer.dart';

Map<String, dynamic> teamInputToJson(TeamInput team) => {
      'name': team.name,
      'matchLengthMinutes': team.matchLengthMinutes,
      'players': team.players.map(_playerToJson).toList(),
      'attendance': team.attendance.map(_attendanceToJson).toList(),
      'rpe': team.rpe.map(_rpeToJson).toList(),
      'wellness': team.wellness.map(_wellnessToJson).toList(),
      'games': team.games.map(_gameLogToJson).toList(),
    };

TeamInput teamInputFromJson(Map<String, dynamic> json) {
  final team = TeamInput(
      name: json['name'] as String,
      matchLengthMinutes: json['matchLengthMinutes'] as int? ??
          SoccerConstants.matchLengthMinutes,
      players: (json['players'] as List)
          .map((item) => _playerFromJson(item as Map<String, dynamic>))
          .toList(),
      attendance: (json['attendance'] as List)
          .map((item) => _attendanceFromJson(item as Map<String, dynamic>))
          .toList(),
      rpe: (json['rpe'] as List)
          .map((item) => _rpeFromJson(item as Map<String, dynamic>))
          .toList(),
      wellness: (json['wellness'] as List?)
              ?.map((item) => _wellnessFromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      games: (json['games'] as List)
          .map((item) => _gameLogFromJson(item as Map<String, dynamic>))
          .toList(),
    );
  return team.withSyncedWellness();
}

Map<String, dynamic> _playerToJson(PlayerInput player) => {
      'id': player.id,
      'name': player.name,
      'position': player.position,
      'role': player.role.name,
    };

PlayerInput _playerFromJson(Map<String, dynamic> json) => PlayerInput(
      id: json['id'] as String,
      name: json['name'] as String,
      position: json['position'] as String,
      role: PlayerRole.values.byName(json['role'] as String),
    );

Map<String, dynamic> _attendanceToJson(AttendanceInput record) => {
      'playerId': record.playerId,
      'sessionsAttended': record.sessionsAttended,
      'sessionsTotal': record.sessionsTotal,
    };

AttendanceInput _attendanceFromJson(Map<String, dynamic> json) =>
    AttendanceInput(
      playerId: json['playerId'] as String,
      sessionsAttended: json['sessionsAttended'] as int,
      sessionsTotal: json['sessionsTotal'] as int,
    );

Map<String, dynamic> _rpeToJson(RpeInput record) => {
      'playerId': record.playerId,
      'dailyValues': record.dailyValues,
    };

RpeInput _rpeFromJson(Map<String, dynamic> json) => RpeInput(
      playerId: json['playerId'] as String,
      dailyValues: (json['dailyValues'] as List)
          .map((value) => (value as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _wellnessToJson(WellnessInput record) => {
      'playerId': record.playerId,
      'trainingLoad': record.trainingLoad,
      'sleepHours': record.sleepHours,
      'studyHours': record.studyHours,
      'crashRisk': record.crashRisk.name,
    };

WellnessInput _wellnessFromJson(Map<String, dynamic> json) => WellnessInput(
      playerId: json['playerId'] as String,
      trainingLoad: json['trainingLoad'] as int? ?? 0,
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0,
      studyHours: (json['studyHours'] as num?)?.toDouble() ?? 0,
      crashRisk: CrashRisk.values.byName(json['crashRisk'] as String? ?? 'low'),
    );

Map<String, dynamic> _gameLogToJson(GameLog game) => {
      'id': game.id,
      'appearances': game.appearances.map(_appearanceToJson).toList(),
      'events': game.events.map(_eventToJson).toList(),
    };

GameLog _gameLogFromJson(Map<String, dynamic> json) => GameLog(
      id: json['id'] as String,
      appearances: (json['appearances'] as List)
          .map((item) => _appearanceFromJson(item as Map<String, dynamic>))
          .toList(),
      events: (json['events'] as List)
          .map((item) => _eventFromJson(item as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _appearanceToJson(GameAppearance appearance) => {
      'playerId': appearance.playerId,
      'minutesPlayed': appearance.minutesPlayed,
      'started': appearance.started,
    };

GameAppearance _appearanceFromJson(Map<String, dynamic> json) =>
    GameAppearance(
      playerId: json['playerId'] as String,
      minutesPlayed: json['minutesPlayed'] as int,
      started: json['started'] as bool,
    );

Map<String, dynamic> _eventToJson(GameEventInput event) => {
      'playerId': event.playerId,
      'type': event.type.name,
      'passChainLength': event.passChainLength,
    };

GameEventInput _eventFromJson(Map<String, dynamic> json) => GameEventInput(
      playerId: json['playerId'] as String,
      type: GameEventType.values.byName(json['type'] as String),
      passChainLength: json['passChainLength'] as int? ?? 0,
    );

Map<String, dynamic> gameEventToJson(GameEventInput event) => _eventToJson(event);

GameEventInput gameEventFromJson(Map<String, dynamic> json) =>
    _eventFromJson(json);
