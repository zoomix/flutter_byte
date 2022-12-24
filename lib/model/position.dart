import 'package:intl/intl.dart';
import 'package:lag_byte/model/person.dart';

class Position {
  final String pos;
  final Person? person;
  final List<PlayEvent> history = [];

  Position({required this.pos, this.person});

  Map<String, dynamic> toMap() {
    return {'pos': pos, 'person': person?.id};
  }

  @override
  String toString() {
    return 'Position{pos: $pos, person: $person}';
  }

  String timePlayed() {
    int tot = 0;
    DateTime? start = null;
    history.forEach((element) {
      if (element.type == 'start') {
        start = element.ts;
      }
      if (element.type == 'stop') {
        tot += element.ts.second - (start != null ? start!.second : 0);
        start = null;
      }
    });
    if (start != null) {
      tot += DateTime.now().second - (start != null ? start!.second : 0);
    }

    return "$tot";
    // final rightNow = DateTime.now();
    // return DateFormat('mm:ss').format(rightNow);
  }

  void startPlay() {
    history.add(PlayEvent(type: "start", ts: DateTime.now()));
  }

  void stopPlay() {
    history.add(PlayEvent(type: "stop", ts: DateTime.now()));
  }
}

class PlayEvent {
  final String type; // Either "start" or "stop"
  final DateTime ts;

  const PlayEvent({required this.type, required this.ts});
}
