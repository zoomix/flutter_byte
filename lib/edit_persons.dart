import 'package:flutter/material.dart';
import 'package:lag_byte/model/player.dart';
import 'package:lag_byte/model/diamond_position.dart';

MaterialPageRoute myEditPersons(
  List<DiamondPosition> positions,
  Function onAdd,
  Function onRemove,
) {
  return MaterialPageRoute<void>(
    builder: (context) {
      return ListWrapper(
        positions: positions,
        onAdd: onAdd,
        onRemove: onRemove,
      );
    },
  );
}

class ListWrapper extends StatefulWidget {
  const ListWrapper(
      {super.key,
      required this.positions,
      required this.onAdd,
      required this.onRemove});

  final List<DiamondPosition> positions;
  final Function onRemove;
  final Function onAdd;

  @override
  State<ListWrapper> createState() => _ListWrapperState();
}

class _ListWrapperState extends State<ListWrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit persons'),
      ),
      body: EditPersonsWidget(
          positions: widget.positions, onRemove: widget.onRemove),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _dialogBuilder(context, (String newName) {
            final initials = newName
                .split(" ")
                .map((namePart) => namePart[0].toUpperCase())
                .join('');
            final newPerson = DiamondPosition(
                pos: 'top',
                player: Player(id: 123, name: newName, initials: initials));
            setState(() {
              widget.onAdd(newPerson);
            });
          });
        },
      ),
    );
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
      {super.key, required this.positions, required this.onRemove});

  final List<DiamondPosition> positions;
  final Function onRemove;

  @override
  State<EditPersonsWidget> createState() => _EditPersonsWidgetState();
}

class _EditPersonsWidgetState extends State<EditPersonsWidget> {
  void _onRemovePosition(DiamondPosition position) {
    setState(() {
      widget.positions.remove(position);
      widget.onRemove(position);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> positionWidgets = widget.positions
        .map((position) => EditPersonWidget(
              position: position,
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
      {super.key, required this.position, required this.onRemove});

  final DiamondPosition position;
  final Function onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(position.player.name),
      trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: (() {
            onRemove(position);
          })),
    );
  }
}
