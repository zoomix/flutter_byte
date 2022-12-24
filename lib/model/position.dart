import 'package:lag_byte/model/person.dart';

class Position {
  final String pos;
  final Person? person;

  const Position({required this.pos, this.person});

  Map<String, dynamic> toMap() {
    return {'pos': pos, 'person': person?.id};
  }

  @override
  String toString() {
    return 'Position{pos: $pos, person: $person}';
  }
}
