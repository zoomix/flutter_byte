import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lag_byte/model/player.dart';
import 'package:shared_preferences/shared_preferences.dart';

MaterialPageRoute myEditPlayers(
  Function onAdd,
  Function onRemove,
) {
  return MaterialPageRoute<void>(
    builder: (context) {
      return ListWrapper(
        onAdd: onAdd,
        onRemove: onRemove,
      );
    },
  );
}

class ListWrapper extends StatefulWidget {
  ListWrapper({super.key, required this.onAdd, required this.onRemove});

  final Function onRemove;
  final Function onAdd;
  final List<Player> players = [];

  @override
  State<ListWrapper> createState() => _ListWrapperState();
}

class _ListWrapperState extends State<ListWrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit players'),
      ),
      body:
          EditPersonsWidget(players: widget.players, onRemove: widget.onRemove),
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
      widget.players.add(newPlayer);
      sp.setStringList('players',
          widget.players.map((player) => jsonEncode(player.toMap())).toList());

      setState(() {
        widget.onAdd(newPlayer);
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
  const EditPersonsWidget(
      {super.key, required this.players, required this.onRemove});

  final List<Player> players;
  final Function onRemove;

  @override
  State<EditPersonsWidget> createState() => _EditPersonsWidgetState();
}

class _EditPersonsWidgetState extends State<EditPersonsWidget> {
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((SharedPreferences sp) {
      final players = sp.getStringList("players") ?? [];
      for (var stringPlayer in players) {
        final jsonPlayer = jsonDecode(stringPlayer);
        widget.players.add(
          Player(
            id: jsonPlayer['id'],
            name: jsonPlayer['name'],
            initials: jsonPlayer['initials'],
          ),
        );
      }
      setState(() {});
    });
  }

  void _onRemovePosition(Player player) {
    setState(() {
      widget.players.remove(player);
      widget.onRemove(player);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> positionWidgets = widget.players
        .map((player) => EditPersonWidget(
              player: player,
              onRemove: _onRemovePosition,
            ))
        .toList();

    return Column(
      children: positionWidgets,
    );
  }
}

class EditPersonWidget extends StatelessWidget {
  const EditPersonWidget(
      {super.key, required this.player, required this.onRemove});

  final Player player;
  final Function onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(player.name),
      trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: (() {
            onRemove(player);
          })),
    );
  }
}
