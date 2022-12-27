import 'dart:convert';

class Player {
  final int id;
  final String name;
  final String initials;
  final String jerseyNr;
  bool inMatch;

  Player(
      {required this.id,
      required this.name,
      required this.initials,
      required this.jerseyNr,
      this.inMatch = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initials': initials,
      'inMatch': inMatch,
      'jerseyNr': jerseyNr
    };
  }

  static fromJson(String stringPlayer) {
    final jsonPlayer = jsonDecode(stringPlayer);
    return Player(
      id: jsonPlayer['id'],
      name: jsonPlayer['name'],
      initials: jsonPlayer['initials'],
      inMatch: jsonPlayer['inMatch'],
      jerseyNr: jsonPlayer['jerseyNr'] ?? '',
    );
  }

  String get prettyName => "$jerseyNr $name";

  @override
  String toString() {
    return 'Person{id: $id, name: $name, initials: $initials, inMatch: $inMatch, jerseyNr: $jerseyNr}';
  }

  @override
  bool operator ==(Object other) {
    return other is Player && id == other.id;
  }

  @override
  int get hashCode => id;
}
