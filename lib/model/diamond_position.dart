import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lag_byte/model/player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiamondPosition {
  String pos;
  final Player player;
  final List<PlayEvent> history = [];
  bool nextUp = false;

  DiamondPosition({required this.pos, required this.player});

  Map<String, dynamic> toMap() {
    return {'pos': pos, 'person': player.id, 'nextUp': nextUp};
  }

  @override
  String toString() {
    return 'Position{pos: $pos, player: $player}';
  }

  String timePlayed() {
    int tot = 0;
    DateTime? start;
    for (var element in history) {
      if (element.type == 'start') {
        start = element.ts;
      }
      if (element.type == 'stop' && start != null) {
        tot += element.ts.difference(start).inSeconds;
        start = null;
      }
    }
    if (start != null) {
      tot += DateTime.now().difference(start).inSeconds;
    }

    final nf = NumberFormat("00");
    return "${nf.format(tot ~/ 60)}:${nf.format(tot % 60)}";
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

  Map<String, dynamic> toMap() {
    return {'type': type, 'ts': ts.millisecondsSinceEpoch};
  }

  static PlayEvent fromMap(Map<String, dynamic> map) {
    return PlayEvent(
      type: map['type'],
      ts: DateTime.fromMillisecondsSinceEpoch(map['ts']),
    );
  }
}

void persistActivePositions(List positions) {
  SharedPreferences.getInstance().then((SharedPreferences sp) {
    sp.setStringList(
      'positions-active',
      positions.map((position) => jsonEncode(position.toMap())).toList(),
    );

    for (var position in positions) {
      if (position is DiamondPosition) {
        sp.setStringList(
          'history-${position.player.id}',
          position.history
              .map((PlayEvent hist) => jsonEncode(hist.toMap()))
              .toList(),
        );
      }
    }
  });
}

void persistPositions(List<DiamondPosition> positions) {
  SharedPreferences.getInstance().then((SharedPreferences sp) {
    sp.setStringList(
      'positions',
      positions.map((position) => jsonEncode(position.toMap())).toList(),
    );

    for (var position in positions) {
      sp.setStringList(
        'history-${position.player.id}',
        position.history.map((hist) => jsonEncode(hist.toMap())).toList(),
      );
    }
  });
}

Future<List<DiamondPosition?>> loadActivePositions() async {
  SharedPreferences sp = await SharedPreferences.getInstance();

  final players = sp
          .getStringList("players")
          ?.map((stringPlayer) => Player.fromJson(stringPlayer)) ??
      [];

  final positionsMaps =
      sp.getStringList('positions-active')?.map((p) => jsonDecode(p)) ?? [];

  var result = players.map((player) {
    final poss =
        positionsMaps.where((element) => element['person'] == player.id);

    if (poss.isEmpty) {
      return null;
    }

    final pos = poss.isEmpty ? 'top' : poss.first['pos'];
    final bool nextUp = poss.isEmpty ? false : poss.first['nextUp'];

    final List<PlayEvent> history = sp
            .getStringList('history-${player.id}')
            ?.map((playEventStr) => jsonDecode(playEventStr))
            .map((playEventMap) => PlayEvent.fromMap(playEventMap))
            .toList() ??
        [];

    var position = DiamondPosition(pos: pos, player: player);
    position.history.addAll(history);
    position.nextUp = nextUp;
    return position;
  }).toList();
  return result;
}

Future<List<DiamondPosition?>> loadPositions() async {
  SharedPreferences sp = await SharedPreferences.getInstance();

  final players = sp
          .getStringList("players")
          ?.map((stringPlayer) => Player.fromJson(stringPlayer)) ??
      [];

  final positionsMaps =
      sp.getStringList('positions')?.map((p) => jsonDecode(p)) ?? [];

  var result = players.map((player) {
    final poss =
        positionsMaps.where((element) => element['person'] == player.id);

    if (poss.isEmpty) {
      return null;
    }

    final pos = poss.isEmpty ? 'top' : poss.first['pos'];
    final bool nextUp = poss.isEmpty ? false : poss.first['nextUp'];

    final List<PlayEvent> history = sp
            .getStringList('history-${player.id}')
            ?.map((playEventStr) => jsonDecode(playEventStr))
            .map((playEventMap) => PlayEvent.fromMap(playEventMap))
            .toList() ??
        [];

    var position = DiamondPosition(pos: pos, player: player);
    position.history.addAll(history);
    position.nextUp = nextUp;
    return position;
  }).toList();
  return result;
}
