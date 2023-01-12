import 'package:flutter/material.dart';
import 'package:lag_byte/model/diamond_position.dart';
import 'package:lag_byte/services/notifications.dart';
import 'package:lag_byte/services/positions_messagebus.dart';
import 'package:lag_byte/utils.dart';
import 'package:lag_byte/widgets/position_widget.dart';

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
  late final PositionWidget goalie;

  final PositionsMessagebus _positionsMB = locator<PositionsMessagebus>();
  final NotificationsMessagebus _notificationMB =
      locator<NotificationsMessagebus>();

  var diamondShape = {};

  @override
  void initState() {
    super.initState();
    top = PositionWidget(positions: widget.positions, prettyPos: 'F');
    left = PositionWidget(positions: widget.positions, prettyPos: 'V');
    right = PositionWidget(positions: widget.positions, prettyPos: 'H');
    defender = PositionWidget(positions: widget.positions, prettyPos: 'B');
    goalie = PositionWidget(positions: widget.positions, prettyPos: 'M');
    diamondShape = {
      'top': top,
      'left': left,
      'right': right,
      'defender': defender,
      'goalie': goalie
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

        _persistAllActivePositions();
        persistPositions(widget.positions);
      });
    });
    _positionsMB.assignGoalieStream.listen((DiamondPosition newGoalie) {
      setState(() {
        newGoalie.pos = 'goalie';
        widget.handleByte(newGoalie, null);
        goalie.pos = newGoalie;
        _persistAllActivePositions();
        persistPositions(widget.positions);
        diamondSuggestPositions(widget.positions);
      });
    });
    _positionsMB.clearAllStream.listen((ts) => _clearAll());
    _positionsMB.pauseAllStream.listen((ts) => _pauseAll());
    awaitedLoadActievPositions();
  }

  void awaitedLoadActievPositions() async {
    var loadedPositions = await loadActivePositions();
    setState(() {
      for (var position in loadedPositions) {
        if (position?.prettyName == 'M') {
          goalie.pos = position;
        } else if (position != null) {
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
    _persistAllActivePositions();
    persistPositions(widget.positions);
    _notificationMB.reset();
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
    _removeAllActivePositions();
    persistPositions(widget.positions);
  }

  void _persistAllActivePositions() {
    final activePositions = diamondShape.values.map((pw) => pw.pos).toList();
    persistActivePositions(activePositions);
  }

  void _removeAllActivePositions() {
    persistActivePositions([]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("images/bgr_football.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              top,
              Row(
                children: [
                  Expanded(flex: 1, child: left),
                  Expanded(flex: 1, child: right),
                ],
              ),
              defender,
              goalie,
            ],
          ),
        ),
        ElevatedButton(
          onPressed: doByte,
          child: const Text('BYTE!'),
        ),
      ],
    );
  }
}
