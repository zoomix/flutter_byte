class Player {
  final int id;
  final String name;
  final String initials;

  const Player({required this.id, required this.name, required this.initials});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'initials': initials};
  }

  @override
  String toString() {
    return 'Person{id: $id, name: $name, initials: $initials}';
  }
}
