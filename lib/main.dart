import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lag_byte/edit_players.dart';
import 'package:lag_byte/model/player.dart';
import 'package:lag_byte/model/diamond_position.dart';
import 'package:lag_byte/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_builder/timer_builder.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((SharedPreferences sp) {
      final players = sp.getStringList("players") ?? [];
      for (var stringPlayer in players) {
        final jsonPlayer = jsonDecode(stringPlayer);
        final player = Player(
          id: jsonPlayer['id'],
          name: jsonPlayer['name'],
          initials: jsonPlayer['initials'],
          inMatch: jsonPlayer['inMatch'],
        );
        widget.positions.add(DiamondPosition(pos: 'top', player: player));
      }
      setState(() {
        diamondSuggestPositions(widget.positions);
      });
    });
  }

  void _handleByte(DiamondPosition incoming, DiamondPosition? outgoing) {
    setState(() {
      widget.positions.remove(incoming);
      if (outgoing != null) {
        widget.positions.add(outgoing);
      }
    });
  }

  void _onAddPlayer(Player player) {
    setState(() {
      final position = DiamondPosition(pos: 'top', player: player);
      widget.positions.add(position);
    });
  }

  void _onRemovePlayer(Player player) {
    setState(() {
      widget.positions.removeWhere((position) => position.player == player);
    });
  }

  void _onUpdatePlayerMatch(Player player) {
    setState(() {
      try {
        var position = widget.positions
            .firstWhere((position) => position.player.id == player.id);
        position.player.inMatch = player.inMatch;
      } on StateError {
        // I guess this player didn't exist in the list of positions for some reason?
      }
    });
  }

  void _pushEditPlayers() {
    final materialPageRoute = myEditPlayers(
      _onAddPlayer,
      _onRemovePlayer,
      _onUpdatePlayerMatch,
    );
    Navigator.of(context).push(materialPageRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
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

class DiamondWidget extends StatefulWidget {
  const DiamondWidget(
      {super.key, required this.positions, required this.handleByte});

  final List<DiamondPosition> positions;
  final Function handleByte;

  @override
  State<DiamondWidget> createState() => _DiamondWidgetState();
}

void diamondSuggestPositions(List<DiamondPosition> positions) {
  DiamondPosition? lastPosition;
  int nofNextUps = 0;
  positions.sort(((a, b) => a.timePlayed().compareTo(b.timePlayed())));
  for (var position in positions) {
    if (lastPosition != null) {
      position.pos = lastPosition.pos;
      position.togglePosition();
    }
    lastPosition = position;
    position.nextUp = (4 > nofNextUps++);
  }
}

class _DiamondWidgetState extends State<DiamondWidget> {
  final top = PositionWidget(pos: null);
  final left = PositionWidget(pos: null);
  final right = PositionWidget(pos: null);
  final defender = PositionWidget(pos: null);

  var diamondShape = {};

  @override
  void initState() {
    super.initState();
    diamondShape = {
      'top': top,
      'left': left,
      'right': right,
      'defender': defender
    };
    diamondSuggestPositions(widget.positions);
  }

  void doByte() {
    final positionChanges = <Tuple<DiamondPosition, DiamondPosition?>>[];

    for (var position in widget.positions) {
      if (position.nextUp) {
        var positionWidget = diamondShape[position.pos];
        var outgoing = positionWidget.pos;
        diamondShape[position.pos].pos = position;
        positionChanges.add(Tuple(item1: position, item2: outgoing));
      }
    }

    for (var positionChange in positionChanges) {
      setState(() {
        positionChange.item2?.stopPlay();
        widget.handleByte(positionChange.item1, positionChange.item2);
        positionChange.item1.startPlay();
        positionChange.item2?.nextUp = false;
        positionChange.item2?.togglePosition();
      });
    }

    setState(() {
      diamondSuggestPositions(widget.positions);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        top,
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [left, right],
          ),
        ),
        defender,
        ElevatedButton(
          onPressed: doByte,
          child: const Text('BYTE!'),
        ),
      ],
    );
  }
}

class PositionWidget extends StatefulWidget {
  PositionWidget({super.key, this.pos});

  DiamondPosition? pos;

  @override
  State<PositionWidget> createState() => _PositionWidgetState();
}

class _PositionWidgetState extends State<PositionWidget> {
  final initalsFont =
      const TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
  final nameFont = const TextStyle(fontSize: 16);
  final timeFont = const TextStyle(fontSize: 24);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child:
          TimerBuilder.periodic(const Duration(seconds: 1), builder: (context) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: const BoxDecoration(
                  color: Colors.green, shape: BoxShape.circle),
              alignment: Alignment.center,
              child:
                  Text(widget.pos?.player.initials ?? '-', style: initalsFont),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.pos?.player.name ?? '', style: nameFont),
                Text(widget.pos?.timePlayed() ?? '--:--', style: timeFont),
              ],
            )
          ],
        );
      }),
    );
  }
}

class PlayerList extends StatefulWidget {
  const PlayerList({super.key, required this.positions});

  final List<DiamondPosition> positions;

  @override
  State<PlayerList> createState() => _PlayerListState();
}

class _PlayerListState extends State<PlayerList> {
  Widget _leading(DiamondPosition position) {
    return Checkbox(
        value: position.nextUp,
        onChanged: (value) {
          setState(() {
            position.setNextUp(value ?? false);
          });
        });
  }

  Widget _trailing(DiamondPosition position) {
    return IconButton(
      onPressed: () {
        setState(() {
          position.togglePosition();
        });
      },
      icon: Icon(
        position.getIcon(),
        color: Colors.red,
        semanticLabel: "Position",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        children: widget.positions
            .where((position) => position.player.inMatch)
            .map((position) {
          final personName = position.player.name;
          final timePlayed = position.timePlayed();
          return ListTile(
            leading: _leading(position),
            title: Text(
              "$timePlayed $personName",
              style: const TextStyle(fontSize: 18),
            ),
            trailing: _trailing(position),
          );
        }).toList(),
      ),
    );
  }
}
