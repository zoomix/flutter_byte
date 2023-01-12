import 'dart:async';

import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:intl/intl.dart';
import 'package:lag_byte/edit_players.dart';
import 'package:lag_byte/model/player.dart';
import 'package:lag_byte/model/diamond_position.dart';
import 'package:lag_byte/services/notifications.dart';
import 'package:lag_byte/services/players_messagebus.dart';
import 'package:lag_byte/services/positions_messagebus.dart';
import 'package:lag_byte/utils.dart';
import 'package:lag_byte/widgets/diamond.dart';
import 'package:lag_byte/widgets/player_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_builder/timer_builder.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Byte',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: MyHomePage(title: 'Byte!'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;
  final positions = <DiamondPosition>[];

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PlayersMessagebus _playersMB = locator<PlayersMessagebus>();
  final PositionsMessagebus _positionsMB = locator<PositionsMessagebus>();
  // final Notifications _notifications = locator<Notifications>();
  final NotificationsMessagebus _notificationMB =
      locator<NotificationsMessagebus>();

  late StreamSubscription<Player> playerAddStream;
  late StreamSubscription<Player> playerRemoveStream;
  late StreamSubscription<Player> playerUpdatedStream;
  late StreamSubscription<int> positionPauseStream;

  DateTime? lastByte;
  int secondsPerByte = 180;
  bool byteAlarmTriggered = false;

  @override
  void initState() {
    super.initState();
    playerAddStream = _playersMB.playerAddStream.listen((player) {
      _onAddPlayer(player);
    });
    playerRemoveStream = _playersMB.playerRemoveStream.listen(((player) {
      _onRemovePlayer(player);
    }));
    playerUpdatedStream = _playersMB.playerUpdateStream.listen((player) {
      _onUpdatePlayer(player);
    });
    _positionsMB.pauseAllStream.listen((ts) {
      lastByte = null;
      persistLastByte(lastByte, secondsPerByte);
      _notificationMB.cancel();
    });
    _positionsMB.clearAllStream.listen((ts) {
      lastByte = null;
      persistLastByte(lastByte, secondsPerByte);
      _notificationMB.cancel();
    });
    _positionsMB.triggerAlarmStream.listen((event) {
      byteAlarmTriggered = true;
      final Iterable<Duration> pauses = [
        const Duration(milliseconds: 500),
        const Duration(milliseconds: 500),
      ];
// vibrate - sleep 0.5s - vibrate - sleep 1s - vibrate - sleep 0.5s - vibrate
      Vibrate.vibrateWithPauses(pauses);
    });
    _notificationMB.resetStream.listen((_) {
      if (lastByte != null) {
        _notificationMB.notifyByte(Duration(seconds: secondsLeft()));
      }
    });
    awaitedLoadPositions();
    awaitedLoadLastByte();
  }

  void awaitedLoadLastByte() async {
    var lastByteMap = await loadLastByte();
    setState(() {
      lastByte = lastByteMap['lastByte'];
      secondsPerByte = lastByteMap['secondsPerByte'];
    });
  }

  void awaitedLoadPositions() async {
    var loadedPositions = await loadPositions();
    for (var position in loadedPositions) {
      if (position != null) {
        widget.positions.add(position);
      }
    }
    setState(() {
      diamondSuggestPositions(widget.positions);
    });
  }

  void loadPlayers() {
    SharedPreferences.getInstance().then((SharedPreferences sp) {
      final players = sp.getStringList("players") ?? [];
      for (var stringPlayer in players) {
        final player = Player.fromJson(stringPlayer);
        if (player.inMatch) {
          widget.positions.add(DiamondPosition(pos: 'top', player: player));
        }
      }
      setState(() {
        diamondSuggestPositions(widget.positions);
      });
    });
  }

  void _handleByte(DiamondPosition? incoming, DiamondPosition? outgoing) {
    setState(() {
      if (incoming != null) {
        byteAlarmTriggered = false;
        lastByte = DateTime.now();
        persistLastByte(lastByte, secondsPerByte);
        widget.positions.remove(incoming);
        _notificationMB.notifyByte(Duration(seconds: secondsPerByte));
      }
      if (outgoing != null) {
        widget.positions.add(outgoing);
      }
    });
  }

  void _onUpdatePlayer(Player player) {
    setState(() {
      if (player.inMatch) {
        final position = DiamondPosition(pos: 'top', player: player);
        widget.positions.add(position);
      } else {
        widget.positions
            .removeWhere((position) => position.player.id == player.id);
      }
      diamondSuggestPositions(widget.positions);
    });
    persistPositions(widget.positions);
  }

  void _onAddPlayer(Player player) {
    setState(() {
      if (player.inMatch) {
        final position = DiamondPosition(pos: 'top', player: player);
        widget.positions.add(position);
      }
    });
    persistPositions(widget.positions);
  }

  void _onRemovePlayer(Player player) {
    setState(() {
      widget.positions
          .removeWhere((position) => position.player.id == player.id);
    });
    persistPositions(widget.positions);
  }

  void _pushEditPlayers() {
    final materialPageRoute = myEditPlayers();
    Navigator.of(context).push(materialPageRoute);
    persistPositions(widget.positions);
  }

  int secondsLeft() {
    return secondsPerByte -
        (lastByte != null ? DateTime.now().difference(lastByte!).inSeconds : 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton.icon(
            onPressed: () async {
              var resultingDuration = await showDurationPicker(
                context: context,
                initialTime: Duration(minutes: secondsPerByte ~/ 60),
              );
              setState(() {
                secondsPerByte = resultingDuration?.inSeconds ?? 180;
                if (lastByte != null) {
                  _notificationMB.notifyByte(Duration(seconds: secondsLeft()));
                }
                persistLastByte(lastByte, secondsPerByte);
              });
            },
            icon: const Icon(Icons.timer_sharp, color: Colors.black),
            label: TimerBuilder.periodic(const Duration(seconds: 1),
                builder: (context) {
              int secsLeft = secondsLeft();
              if (secsLeft <= 0 && !byteAlarmTriggered) {
                _positionsMB.triggerAlarm();
              }
              final nf = NumberFormat("00");
              return Text(
                "${secsLeft < 0 ? '-' : ''}${nf.format(secsLeft.abs() ~/ 60)}:${nf.format((secsLeft < 0 ? 60 - secsLeft : secsLeft) % 60)}",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              );
            }),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _positionsMB.clearAllPosition(0),
            tooltip: 'Nollställ',
          ),
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => _positionsMB.pauseAllPosition(0),
            tooltip: 'Matchslut',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _pushEditPlayers,
            tooltip: 'Edit Players',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            DiamondWidget(positions: widget.positions, handleByte: _handleByte),
            PlayerList(positions: widget.positions),
          ],
        ),
      ),
    );
  }
}
