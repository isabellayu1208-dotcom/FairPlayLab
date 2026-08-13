import '../models/inputs.dart';
import '../models/soccer.dart';

/// Blank squad — no players, matches, attendance, or RPE until you add them.
const emptyTeam = TeamInput(
  name: 'My Squad',
  matchLengthMinutes: SoccerConstants.matchLengthMinutes,
  players: [],
  attendance: [],
  rpe: [],
  wellness: [],
  games: [],
);
