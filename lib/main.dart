import 'package:flutter/material.dart';
import 'package:lag_byte/model/position.dart';

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
      home: const MyHomePage(title: 'Byte!'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

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
          children: <Widget>[const DiamondWidget()],
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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PositionWidget(),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [PositionWidget(), PositionWidget()],
          ),
        ),
        PositionWidget(),
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
            child: const Text(
              'SJ',
              style: TextStyle(fontSize: 32),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Anna Panna', style: TextStyle(fontSize: 16)),
              Text('08:12', style: TextStyle(fontSize: 24)),
            ],
          )
        ],
      ),
    );
  }
}
