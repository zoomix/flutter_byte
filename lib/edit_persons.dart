import 'package:flutter/material.dart';
import 'package:lag_byte/model/position.dart';

MaterialPageRoute myEditPersons(
  List<Position> positions,
  Function onAdd,
  Function onRemove,
) {
  return MaterialPageRoute<void>(
    builder: (context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit persons'),
        ),
        body: EditPersonsWidget(positions: positions, onRemove: onRemove),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {},
        ),
      );
    },
  );
}

class EditPersonsWidget extends StatefulWidget {
  const EditPersonsWidget(
      {super.key, required this.positions, required this.onRemove});

  final List<Position> positions;
  final Function onRemove;

  @override
  State<EditPersonsWidget> createState() => _EditPersonsWidgetState();
}

class _EditPersonsWidgetState extends State<EditPersonsWidget> {
  void _onRemovePosition(Position position) {
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

  final Position position;
  final Function onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(position.person.name),
      trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: (() {
            onRemove(position);
          })),
    );
  }
}
