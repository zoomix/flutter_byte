import 'dart:async';
import 'dart:convert';
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
      SharedPreferences.getInstance().then((SharedPreferences sp) {
        sp.setStringList(
            'players',
            widget.players
                .map((player) => jsonEncode(player.toMap()))
                .toList());
      });
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
          _dialogBuilder(context, (String newName) {
            final initials = newName
                .split(" ")
                .map((namePart) =>
                    namePart.isEmpty ? '' : namePart.trim()[0].toUpperCase())
                .join('');
            _addPlayer(newName, initials);
          });
        },
      ),
    );
  }

  void _addPlayer(String newName, String initials) {
    SharedPreferences.getInstance().then((SharedPreferences sp) {
      int maxId = widget.players.isEmpty
          ? 0
          : widget.players.map((p) => p.id).reduce(max);
      final newPlayer =
          Player(id: maxId + 1, name: newName, initials: initials);

      setState(() {
        widget.players.add(newPlayer);
        sp.setStringList(
            'players',
            widget.players
                .map((player) => jsonEncode(player.toMap()))
                .toList());

        _playersMB.addPlayer(newPlayer);
      });
    });
  }
}

Future<void> _dialogBuilder(BuildContext context, onSave) {
  String textInput = "";

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Enter player name'),
        content: TextField(
          autofocus: true,
          maxLength: 50,
          onChanged: ((value) {
            textInput = value;
          }),
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
              onSave(textInput);
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
    SharedPreferences.getInstance().then((SharedPreferences sp) {
      sp.setStringList('players',
          widget.players.map((player) => jsonEncode(player.toMap())).toList());
      setState(() {
        _playersMB.updatePlayer(player);
      });
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
      title: Text(player.name),
      trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: (() {
            onRemove(player);
          })),
    );
  }
}
