import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lag_byte/model/player.dart';
import 'package:lag_byte/services/players_messagebus.dart';
import 'package:lag_byte/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

MaterialPageRoute myEditPlayers() {
  return MaterialPageRoute<void>(
    builder: (context) {
      return ListWrapper();
    },
  );
}

class ListWrapper extends StatefulWidget {
  ListWrapper({super.key});

  final List<Player> players = [];

  @override
  State<ListWrapper> createState() => _ListWrapperState();
}

class _ListWrapperState extends State<ListWrapper> {
  final PlayersMessagebus _playersMB = locator<PlayersMessagebus>();
  late StreamSubscription<Player> playerAddStream;
  late StreamSubscription<Player> playerRemoveStream;

  @override
  void initState() {
    super.initState();
    playerAddStream = _playersMB.playerAddStream.listen((player) {
      if (!widget.players.contains(player)) {
        setState(() {
          widget.players.add(player);
        });
      }
    });
    playerRemoveStream = _playersMB.playerRemoveStream.listen((player) {
      setState(() {
        widget.players.remove(player);
      });
      persistPlayers(widget.players);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit players'),
      ),
      body: EditPersonsWidget(players: widget.players),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _dialogBuilder(context, (String newName, String jerseyNr) {
            if (newName == '.') {
              print('Bootstrapping with default users');
              _addPlayer("Thomas Ravelli", "TR", "1");
              _addPlayer("Roland Nilsson", "RN", "2");
              _addPlayer("Patrik Andersson", "PA", "3");
              _addPlayer("Joachim Björklund", "JB", "4");
              _addPlayer("Roger Ljung", "RJ", "5");
              _addPlayer("Stefan Schwarz", "SS", "6");
              _addPlayer("Henrik Larsson", "HL", "7");
              _addPlayer("Klas Ingesson", "KI", "8");
              _addPlayer("Jonas Thern", "JT", "9");
              _addPlayer("Martin Dahlin", "MD", "10");
              _addPlayer("Tomas Brolin", "TB", "11");
            } else {
              final initials = newName
                  .split(" ")
                  .map((namePart) =>
                      namePart.isEmpty ? '' : namePart.trim()[0].toUpperCase())
                  .join('');
              _addPlayer(newName, initials, jerseyNr);
            }
          });
        },
      ),
    );
  }

  void _addPlayer(String newName, String initials, String jerseyNr) {
    SharedPreferences.getInstance().then((SharedPreferences sp) {
      int maxId = widget.players.isEmpty
          ? 0
          : widget.players.map((p) => p.id).reduce(max);
      final newPlayer = Player(
          id: maxId + 1, name: newName, initials: initials, jerseyNr: jerseyNr);

      setState(() {
        widget.players.add(newPlayer);
        _playersMB.addPlayer(newPlayer);
      });
    });
    persistPlayers(widget.players);
  }
}

Future<void> _dialogBuilder(BuildContext context, onSave) {
  String textInput = "";
  String jerseyNr = "";

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('New player'),
        content: Column(
          children: [
            const Text('Player name'),
            TextField(
              autofocus: true,
              maxLength: 50,
              onChanged: ((value) {
                textInput = value;
              }),
            ),
            const Text('Jersey number'),
            TextField(
              maxLength: 3,
              onChanged: ((value) {
                jerseyNr = value;
              }),
            ),
          ],
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
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Save'),
            onPressed: () {
              onSave(textInput, jerseyNr);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class EditPersonsWidget extends StatefulWidget {
  const EditPersonsWidget({
    super.key,
    required this.players,
  });

  final List<Player> players;

  @override
  State<EditPersonsWidget> createState() => _EditPersonsWidgetState();
}

class _EditPersonsWidgetState extends State<EditPersonsWidget> {
  final PlayersMessagebus _playersMB = locator<PlayersMessagebus>();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((SharedPreferences sp) {
      final players = sp.getStringList("players") ?? [];
      widget.players.clear();
      for (var stringPlayer in players) {
        widget.players.add(Player.fromJson(stringPlayer));
      }
      setState(() {});
    });
  }

  void _onRemovePosition(Player player) {
    _playersMB.removePlayer(player);
  }

  void _onInMatch(Player player) {
    setState(() {
      _playersMB.updatePlayer(player);
      persistPlayers(widget.players);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> positionWidgets = widget.players
        .map((player) => EditPersonWidget(
              player: player,
              onRemove: _onRemovePosition,
              onInMatch: _onInMatch,
            ))
        .toList();

    return ListView(
      children: positionWidgets,
    );
  }
}

class EditPersonWidget extends StatelessWidget {
  const EditPersonWidget(
      {super.key,
      required this.player,
      required this.onRemove,
      required this.onInMatch});

  final Player player;
  final Function onRemove;
  final Function onInMatch;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: player.inMatch,
        onChanged: (value) {
          player.inMatch = !player.inMatch;
          onInMatch(player);
        },
      ),
      title: Text(player.prettyName),
      trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: (() {
            onRemove(player);
          })),
    );
  }
}
