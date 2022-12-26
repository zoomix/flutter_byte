class Player {
  final int id;
  final String name;
  final String initials;
  bool inMatch;

  Player(
      {required this.id,
      required this.name,
      required this.initials,
      this.inMatch = false});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'initials': initials, 'inMatch': inMatch};
  }

  @override
  String toString() {
    return 'Person{id: $id, name: $name, initials: $initials, inMatch: $inMatch}';
  }
}
