import 'dart:convert';

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

  String get prettyName {
    switch (pos) {
      case 'top':
        return "F";
      case 'left':
        return "V";
      case 'right':
        return "H";
      case 'defender':
        return "B";
      default:
        return "F";
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
      positions
          .where((position) => position != null)
          .map((position) => jsonEncode(position.toMap()))
          .toList(),
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

void persistLastByte(DateTime? lastByte, int secondsPerByte) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  if (lastByte != null) {
    sp.setInt('lastByte', lastByte.millisecondsSinceEpoch);
  } else {
    sp.remove('lastByte');
  }
  sp.setInt('secondsPerByte', secondsPerByte);
}

Future<Map<String, dynamic>> loadLastByte() async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  final lastByteStr = sp.containsKey('lastByte') ? sp.getInt('lastByte') : null;
  final secondsPerByte =
      sp.containsKey('secondsPerByte') ? sp.getInt('secondsPerByte') : 180;

  return {
    'lastByte': lastByteStr != null
        ? DateTime.fromMillisecondsSinceEpoch(lastByteStr)
        : null,
    'secondsPerByte': secondsPerByte
  };
}
