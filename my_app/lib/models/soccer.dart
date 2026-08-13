/// Soccer-specific constants and labels for FairPlay Lab.
class SoccerConstants {
  static const appName = 'FairPlay Lab';
  static const appTagline = 'Soccer decision-support for middle & high school teams';
  static const matchLengthMinutes = 80;
  static const halfLengthMinutes = 40;
}

class SoccerPositions {
  static const labels = <String, String>{
    'GK': 'Goalkeeper',
    'CB': 'Center Back',
    'LB': 'Left Back',
    'RB': 'Right Back',
    'CM': 'Central Midfielder',
    'CAM': 'Attacking Midfielder',
    'CDM': 'Defensive Midfielder',
    'LW': 'Left Winger',
    'RW': 'Right Winger',
    'ST': 'Striker',
  };

  static String label(String code) => labels[code] ?? code;

  static String display(String code) {
    final full = label(code);
    return full == code ? code : '$code · $full';
  }
}

class SoccerEventLabels {
  static const labels = {
    'pass': 'Pass',
    'shot': 'Shot',
    'dribble': 'Take-on',
    'clearance': 'Clearance',
  };

  static String label(String type) => labels[type] ?? type;
}
