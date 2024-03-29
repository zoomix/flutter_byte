import 'package:flutter/material.dart';
import 'package:lag_byte/model/diamond_position.dart';
import 'package:lag_byte/services/positions_messagebus.dart';
import 'package:lag_byte/utils.dart';
import 'package:timer_builder/timer_builder.dart';

class PositionWidget extends StatefulWidget {
  PositionWidget(
      {super.key, required this.positions, required this.prettyPos, this.pos});

  final List<DiamondPosition> positions;
  final String prettyPos;
  DiamondPosition? pos;

  @override
  State<PositionWidget> createState() => _PositionWidgetState();
}

class _PositionWidgetState extends State<PositionWidget> {
  final initalsFont = const TextStyle(
      fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black);
  final nameFont = const TextStyle(
      fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white);
  final timeFont = const TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3.0),
      child: TimerBuilder.periodic(
        const Duration(seconds: 1),
        builder: (context) {
          var nameAndTime = [
            Text(widget.pos?.player.prettyName ?? '', style: nameFont),
          ];
          if (widget.prettyPos != 'M') {
            nameAndTime.add(
                Text(widget.pos?.timePlayed() ?? '--:--', style: timeFont));
          }
          return Column(
            children: [
              badge(context),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: nameAndTime,
              ),
            ],
          );
        },
      ),
    );
  }

  Container badge(BuildContext context) {
    final selected = widget.pos == null
        ? false
        : widget.positions
            .where((position) => position.nextUp)
            .where((position) => position.pos == widget.pos?.pos)
            .isNotEmpty;
    final border =
        selected ? const Border.fromBorderSide(BorderSide(width: 2)) : null;
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle, border: border),
      alignment: Alignment.center,
      child: TextButton(
        onPressed: (() {
          directPlayerChange(context, widget.positions, widget.pos);
        }),
        child: Text(
          widget.prettyPos,
          style: initalsFont,
          softWrap: false,
        ),
      ),
    );
  }
}

Future<void> directPlayerChange(BuildContext context,
    List<DiamondPosition> positions, DiamondPosition? oldPosition) {
  final PositionsMessagebus positionsMB = locator<PositionsMessagebus>();
  final prettyName = oldPosition?.player.prettyName ?? "Målvakt";

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Change $prettyName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: positions.map((position) {
            return ListTile(
              title: Text(position.player.prettyName),
              trailing: Text(position.timePlayed()),
              onTap: () {
                if (oldPosition != null) {
                  positionsMB.doByte(position, oldPosition);
                } else {
                  positionsMB.doAssignGoalie(position);
                }
                Navigator.of(context).pop();
              },
            );
          }).toList(),
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
