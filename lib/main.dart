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
  final Position? top = Position(
      pos: 'top',
      person: const Person(id: 1, name: 'Apa Bepa', initials: 'AB'));
  final Position? left = Position(
      pos: 'top',
      person: const Person(id: 2, name: 'Cepa Depa', initials: 'CD'));
  final Position? right = Position(
      pos: 'top',
      person: const Person(id: 3, name: 'Epa Fepa', initials: 'EF'));
  final Position? defender = Position(
      pos: 'top',
      person: const Person(id: 4, name: 'Gepa Hepa', initials: 'GH'));

  final people = const [
    Person(id: 1, name: 'Apa Bepa', initials: 'AB'),
    Person(id: 2, name: 'Cepa Depa', initials: 'CD'),
    Person(id: 3, name: 'Epa Fepa', initials: 'EF'),
    Person(id: 4, name: 'Gepa Hepa', initials: 'GH'),
  ];

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    widget.top?.startPlay();
    widget.left?.startPlay();
    widget.right?.startPlay();
    widget.defender?.startPlay();
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
            DiamondWidget(
              top: widget.top,
              left: widget.left,
              right: widget.right,
              defender: widget.defender,
            ),
            PersonList(people: widget.people),
          ],
        ),
      ),
    );
  }
}

class DiamondWidget extends StatefulWidget {
  const DiamondWidget(
      {super.key, this.top, this.left, this.right, this.defender});

  final Position? top;
  final Position? left;
  final Position? right;
  final Position? defender;

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
              widget.pos != null ? widget.pos!.person!.initials : 'As',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${widget.pos?.person?.name}",
                  style: const TextStyle(fontSize: 16)),
              TimerBuilder.periodic(const Duration(seconds: 1),
                  builder: (context) {
                return Text('${widget.pos?.timePlayed()}',
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
  const PersonList({super.key, required this.people});

  final List<Person> people;

  @override
  State<PersonList> createState() => _PersonListState();
}

class _PersonListState extends State<PersonList> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(itemBuilder: (context, i) {
        final index = i ~/ 2;

        if (index >= widget.people.length) {
          return const Text(' ');
        }
        if (i % 2 == 1) {
          return const Divider();
        }

        final personName = widget.people[index].name;
        const timePlayed = "00:00";
        return ListTile(
          leading: const Icon(Icons.check_box_outline_blank),
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
