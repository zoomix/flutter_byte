import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lag_byte/model/person.dart';

class Position {
  String pos;
  final Person person;
  final List<PlayEvent> history = [];
  bool nextUp = false;

  Position({required this.pos, required this.person});

  Map<String, dynamic> toMap() {
    return {'pos': pos, 'person': person.id};
  }

  @override
  String toString() {
    return 'Position{pos: $pos, person: $person}';
  }

  String timePlayed() {
    int tot = 0;
    DateTime? start;
    for (var element in history) {
      if (element.type == 'start') {
        start = element.ts;
      }
      if (element.type == 'stop') {
        tot += element.ts.second - (start != null ? start.second : 0);
        start = null;
      }
    }
    if (start != null) {
      tot += DateTime.now().second - start.second;
    }

    final rightNow = DateTime.fromMillisecondsSinceEpoch(tot * 1000);
    return DateFormat('mm:ss').format(rightNow);
  }

  void startPlay() {
    history.add(PlayEvent(type: "start", ts: DateTime.now()));
  }

  void stopPlay() {
    history.add(PlayEvent(type: "stop", ts: DateTime.now()));
  }

  void setNextUp(bool value) {
    nextUp = value;
  }

  void togglePosition() {
    if (pos == 'right') {
      pos = 'defender';
    } else if (pos == 'defender') {
      pos = 'left';
    } else if (pos == 'left') {
      pos = 'top';
    } else {
      pos = 'right';
    }
  }

  IconData getIcon() {
    switch (pos) {
      case 'top':
        return Icons.arrow_circle_up_outlined;
      case 'left':
        return Icons.arrow_circle_left_outlined;
      case 'right':
        return Icons.arrow_circle_right_outlined;
      case 'defender':
        return Icons.arrow_circle_down_outlined;
      default:
        return Icons.arrow_circle_up_outlined;
    }
  }
}

class PlayEvent {
  final String type; // Either "start" or "stop"
  final DateTime ts;

  const PlayEvent({required this.type, required this.ts});
}
