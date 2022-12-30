import 'package:flutter/material.dart';
import 'package:lag_byte/model/diamond_position.dart';

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
    return Container(
      height: 38,
      width: 38,
      decoration:
          const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: TextButton(
        onPressed: (() {
          setState(() {
            position.togglePosition();
          });
        }),
        child: Text(
          position.prettyName,
          style: const TextStyle(color: Colors.white),
          softWrap: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final positionCounts = widget.positions
        .where((position) => position.nextUp)
        .map((position) => position.pos)
        .fold(<String, int>{}, (var total, pos) {
      total[pos] = (total[pos] ?? 0) + 1;
      return total;
    });

    return Expanded(
      child: ListView(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        children: widget.positions.map((position) {
          final personName = position.player.name;
          final timePlayed = position.timePlayed();
          final doubleBooked = (positionCounts[position.pos] ?? 0) > 1;
          return ListTile(
            leading: _leading(position),
            subtitle: Text(timePlayed, style: const TextStyle(fontSize: 18)),
            title: Row(
              children: [
                doubleBooked ? const Icon(Icons.warning) : Container(),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    0,
                    position.player.jerseyNr.isEmpty ? 0 : 8,
                    0,
                  ),
                  child: Text(
                    position.player.jerseyNr,
                    style: TextStyle(
                        color: doubleBooked ? Colors.red : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    personName,
                    style: TextStyle(
                        fontSize: 18,
                        color: doubleBooked ? Colors.red : Colors.black),
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
            trailing: _trailing(position),
          );
        }).toList(),
      ),
    );
  }
}
