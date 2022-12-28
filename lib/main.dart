import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lag_byte/edit_players.dart';
import 'package:lag_byte/model/player.dart';
import 'package:lag_byte/model/diamond_position.dart';
import 'package:lag_byte/services/players_messagebus.dart';
import 'package:lag_byte/services/positions_messagebus.dart';
import 'package:lag_byte/utils.dart';
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

  late StreamSubscription<Player> playerAddStream;
  late StreamSubscription<Player> playerRemoveStream;
  late StreamSubscription<Player> playerUpdatedStream;

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
    awaitedLoadPositions();
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
        widget.positions.remove(incoming);
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
  late final PositionWidget top;
  late final PositionWidget left;
  late final PositionWidget right;
  late final PositionWidget defender;

  final PositionsMessagebus _positionsMB = locator<PositionsMessagebus>();

  var diamondShape = {};

  @override
  void initState() {
    super.initState();
    top = PositionWidget(positions: widget.positions, pos: null);
    left = PositionWidget(positions: widget.positions, pos: null);
    right = PositionWidget(positions: widget.positions, pos: null);
    defender = PositionWidget(positions: widget.positions, pos: null);
    diamondShape = {
      'top': top,
      'left': left,
      'right': right,
      'defender': defender
    };
    diamondSuggestPositions(widget.positions);
    _positionsMB.byteStream
        .listen((Tuple<DiamondPosition, DiamondPosition> positionChange) {
      setState(() {
        positionChange.item2.stopPlay();
        positionChange.item1.pos = positionChange.item2.pos;
        diamondShape[positionChange.item1.pos].pos = positionChange.item1;
        widget.handleByte(positionChange.item1, positionChange.item2);
        positionChange.item1.startPlay();
        positionChange.item2.nextUp = false;
        positionChange.item2.togglePosition();
        diamondSuggestPositions(widget.positions);

        persistActivePositions(
            diamondShape.values.map((pw) => pw.pos).toList());
        persistPositions(widget.positions);
      });
    });
    awaitedLoadActievPositions();
  }

  void awaitedLoadActievPositions() async {
    var loadedPositions = await loadActivePositions();
    setState(() {
      for (var position in loadedPositions) {
        if (position != null) {
          diamondShape[position.pos].pos = position;
        }
      }
    });
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
    persistActivePositions(diamondShape.values.map((pw) => pw.pos).toList());
    persistPositions(widget.positions);
  }

  void _clearAll() {
    _pauseAll();
    setState(() {
      for (var position in widget.positions) {
        position.history.clear();
      }
    });
  }

  void _pauseAll() {
    setState(() {
      for (var position in [top, left, right, defender]) {
        position.pos?.stopPlay();
        widget.handleByte(null, position.pos);
        position.pos = null;
      }
      diamondSuggestPositions(widget.positions);
    });
    persistActivePositions([]);
    persistPositions(widget.positions);
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
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: _clearAll,
              child: const Text('NOLLSTÄLL'),
            ),
            TextButton(
              onPressed: _pauseAll,
              child: const Text('MATCHSLUT'),
            ),
            ElevatedButton(
              onPressed: doByte,
              child: const Text('BYTE!'),
            ),
          ],
        )
      ],
    );
  }
}

class PositionWidget extends StatefulWidget {
  PositionWidget({super.key, required this.positions, this.pos});

  final List<DiamondPosition> positions;
  DiamondPosition? pos;

  @override
  State<PositionWidget> createState() => _PositionWidgetState();
}

class _PositionWidgetState extends State<PositionWidget> {
  final initalsFont = const TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black);
  final nameFont = const TextStyle(fontSize: 16);
  final timeFont = const TextStyle(fontSize: 20);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: TimerBuilder.periodic(
        const Duration(seconds: 1),
        builder: (context) {
          final selected = widget.pos == null
              ? false
              : widget.positions
                  .where((position) => position.nextUp)
                  .where((position) => position.pos == widget.pos?.pos)
                  .isNotEmpty;
          final border = selected
              ? Border.fromBorderSide(
                  BorderSide(width: 2),
                )
              : null;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: border),
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: (() {
                    directPlayerChange(context, widget.positions, widget.pos!);
                  }),
                  child: Text(
                    widget.pos?.player.initials ?? '-',
                    style: initalsFont,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    maxLines: 1,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.pos?.player.prettyName ?? '', style: nameFont),
                  Text(widget.pos?.timePlayed() ?? '--:--', style: timeFont),
                ],
              )
            ],
          );
        },
      ),
    );
  }
}

Future<void> directPlayerChange(BuildContext context,
    List<DiamondPosition> positions, DiamondPosition oldPosition) {
  final PositionsMessagebus positionsMB = locator<PositionsMessagebus>();
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Change ${oldPosition.player.prettyName}'),
        content: Expanded(
          child: Column(
            children: positions.map((position) {
              return ListTile(
                title: Text(position.player.prettyName),
                trailing: Text(position.timePlayed()),
                onTap: () {
                  positionsMB.doByte(position, oldPosition);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
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
        children: widget.positions.map((position) {
          final personName = position.player.prettyName;
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
