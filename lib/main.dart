import 'package:flutter/material.dart';
import 'package:lag_byte/model/person.dart';
import 'package:lag_byte/model/position.dart';
import 'package:lag_byte/utils.dart';
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
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: 'Byte!'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  final positions = [
    Position(
        pos: 'top',
        person: const Person(id: 1, name: 'Apa Bepa', initials: 'AB')),
    Position(
        pos: 'top',
        person: const Person(id: 2, name: 'Cepa Depa', initials: 'CD')),
    Position(
        pos: 'top',
        person: const Person(id: 3, name: 'Epa Fepa', initials: 'EF')),
    Position(
        pos: 'top',
        person: const Person(id: 4, name: 'Gepa Hepa', initials: 'GH')),
    Position(
        pos: 'top',
        person: const Person(id: 5, name: 'Ipa Jipa', initials: 'IJ')),
    Position(
        pos: 'top',
        person: const Person(id: 6, name: 'Kipa Lipa', initials: 'KL')),
    Position(
        pos: 'top',
        person: const Person(id: 7, name: 'Mipa Nipa', initials: 'MN')),
  ];

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _handleByte(Position incoming, Position? outgoing) {
    setState(() {
      widget.positions.remove(incoming);
      if (outgoing != null) {
        widget.positions.add(outgoing);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            DiamondWidget(positions: widget.positions, handleByte: _handleByte),
            PersonList(positions: widget.positions),
          ],
        ),
      ),
    );
  }
}

class DiamondWidget extends StatefulWidget {
  const DiamondWidget(
      {super.key, required this.positions, required this.handleByte});

  final List<Position> positions;
  final Function handleByte;

  @override
  State<DiamondWidget> createState() => _DiamondWidgetState();
}

class _DiamondWidgetState extends State<DiamondWidget> {
  final top = PositionWidget(pos: null);
  final left = PositionWidget(pos: null);
  final right = PositionWidget(pos: null);
  final defender = PositionWidget(pos: null);

  var diamondShape = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    diamondShape = {
      'top': top,
      'left': left,
      'right': right,
      'defender': defender
    };
  }

  void doByte() {
    final positionChanges = <Tuple<Position, Position?>>[];

    for (var position in widget.positions) {
      if (position.nextUp) {
        var positionWidget = diamondShape[position.pos];
        diamondShape[position.pos].pos = position;
        positionChanges.add(Tuple(item1: position, item2: positionWidget.pos));
      }
    }

    for (var positionChange in positionChanges) {
      setState(() {
        positionChange.item2?.stopPlay();
        widget.handleByte(positionChange.item1, positionChange.item2);
        positionChange.item1.startPlay();
        positionChange.item2?.nextUp = false;
      });
    }
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

  Position? pos;

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
                  Text(widget.pos?.person.initials ?? '-', style: initalsFont),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.pos?.person.name ?? '', style: nameFont),
                Text(widget.pos?.timePlayed() ?? '--:--', style: timeFont),
              ],
            )
          ],
        );
      }),
    );
  }
}

class PersonList extends StatefulWidget {
  const PersonList({super.key, required this.positions});

  final List<Position> positions;

  @override
  State<PersonList> createState() => _PersonListState();
}

class _PersonListState extends State<PersonList> {
  Widget _leading(Position position) {
    return Checkbox(
        value: position.nextUp,
        onChanged: (value) {
          setState(() {
            position.setNextUp(value ?? false);
          });
        });
  }

  Widget _trailing(Position position) {
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
      child: ListView.builder(itemBuilder: (context, i) {
        final index = i ~/ 2;

        if (index >= widget.positions.length) {
          return const Text(' ');
        }
        if (i % 2 == 1) {
          return const Divider();
        }

        final position = widget.positions[index];
        final personName = position.person.name;
        final timePlayed = position.timePlayed();
        return ListTile(
          leading: _leading(position),
          title: Text(
            "$timePlayed $personName",
            style: const TextStyle(fontSize: 18),
          ),
          trailing: _trailing(position),
        );
      }),
    );
  }
}
