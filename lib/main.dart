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
            )
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
        ElevatedButton(onPressed: widget.top?.stopPlay, child: Text('BYTE!'))
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
            decoration:
                BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              widget.pos != null ? widget.pos!.person!.initials : 'As',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anna Panna', style: TextStyle(fontSize: 16)),
              TimerBuilder.periodic(Duration(seconds: 1), builder: (context) {
                return Text('${widget.pos?.timePlayed()}',
                    style: TextStyle(fontSize: 24));
              }),
            ],
          )
        ],
      ),
    );
  }
}
