import 'package:flutter/material.dart';
import 'package:lag_byte/model/person.dart';
import 'package:lag_byte/model/position.dart';
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
        pos: '', person: const Person(id: 1, name: 'Apa Bepa', initials: 'AB')),
    Position(
        pos: '',
        person: const Person(id: 2, name: 'Cepa Depa', initials: 'CD')),
    Position(
        pos: '', person: const Person(id: 3, name: 'Epa Fepa', initials: 'EF')),
    Position(
        pos: '',
        person: const Person(id: 4, name: 'Gepa Hepa', initials: 'GH')),
    Position(
        pos: '', person: const Person(id: 5, name: 'Ipa Jipa', initials: 'IJ')),
    Position(
        pos: '',
        person: const Person(id: 6, name: 'Kipa Lipa', initials: 'KL')),
    Position(
        pos: '',
        person: const Person(id: 7, name: 'Mipa Nipa', initials: 'MN')),
  ];

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
            DiamondWidget(),
            PersonList(positions: widget.positions),
          ],
        ),
      ),
    );
  }
}

class DiamondWidget extends StatefulWidget {
  DiamondWidget({super.key, this.top, this.left, this.right, this.defender});

  Position? top;
  Position? left;
  Position? right;
  Position? defender;

  @override
  State<DiamondWidget> createState() => _DiamondWidgetState();
}

class _DiamondWidgetState extends State<DiamondWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PositionWidget(pos: widget.top),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PositionWidget(pos: widget.left),
              PositionWidget(pos: widget.right)
            ],
          ),
        ),
        PositionWidget(pos: widget.defender),
        ElevatedButton(
          onPressed: widget.top?.stopPlay,
          child: const Text('BYTE!'),
        ),
      ],
    );
  }
}

class PositionWidget extends StatefulWidget {
  const PositionWidget({super.key, this.pos});

  final Position? pos;

  @override
  State<PositionWidget> createState() => _PositionWidgetState();
}

class _PositionWidgetState extends State<PositionWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: const BoxDecoration(
                color: Colors.green, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              widget.pos != null ? widget.pos!.person.initials : '-',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.pos?.person.name ?? '',
                  style: const TextStyle(fontSize: 16)),
              TimerBuilder.periodic(const Duration(seconds: 1),
                  builder: (context) {
                return Text(widget.pos?.timePlayed() ?? '--:--',
                    style: const TextStyle(fontSize: 24));
              }),
            ],
          )
        ],
      ),
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
        const timePlayed = "00:00";
        return ListTile(
          leading: Checkbox(
            value: position.nextUp,
            onChanged: (value) {
              setState(() {
                position.setNextUp(value ?? false);
              });
            },
          ),
          title: Text(
            "$timePlayed $personName",
            style: const TextStyle(fontSize: 18),
          ),
          trailing: const Icon(
            Icons.arrow_upward,
            color: Colors.red,
            semanticLabel: "Position",
          ),
        );
      }),
    );
  }
}
