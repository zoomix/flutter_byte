import 'package:lag_byte/model/diamond_position.dart';
import 'package:lag_byte/utils.dart';
import 'package:rxdart/rxdart.dart';

class PositionsMessagebus {
  final _addSubject = BehaviorSubject<DiamondPosition>();
  Stream<DiamondPosition> get addStream => _addSubject.stream;
  void addPosition(DiamondPosition position) => _addSubject.add(position);

  final _removeSubject = BehaviorSubject<DiamondPosition>();
  Stream<DiamondPosition> get removeStream => _removeSubject.stream;
  void removePosition(DiamondPosition position) => _removeSubject.add(position);

  final _byteSubject =
      BehaviorSubject<Tuple<DiamondPosition, DiamondPosition>>();
  Stream<Tuple<DiamondPosition, DiamondPosition>> get byteStream =>
      _byteSubject.stream;
  void doByte(DiamondPosition incoming, DiamondPosition outgoing) =>
      _byteSubject.add(Tuple<DiamondPosition, DiamondPosition>(
          item1: incoming, item2: outgoing));
}
