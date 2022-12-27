import 'package:lag_byte/model/player.dart';
import 'package:rxdart/rxdart.dart';

class PlayersMessagebus {
  final _playerSubject = BehaviorSubject<List<Player>>.seeded([]);
  Stream<List<Player>> get playersStream => _playerSubject.stream;
  void putList(List<Player> players) {
    _playerSubject.add(players);
  }

  final _playerAddSubject = BehaviorSubject<Player>();
  Stream<Player> get playerAddStream => _playerAddSubject.stream;
  void addPlayer(Player player) => _playerAddSubject.add(player);

  final _playerRemoveSubject = BehaviorSubject<Player>();
  Stream<Player> get playerRemoveStream => _playerRemoveSubject.stream;
  void removePlayer(Player player) => _playerRemoveSubject.add(player);

  final _playerUpdateSubject = BehaviorSubject<Player>();
  Stream<Player> get playerUpdateStream => _playerUpdateSubject.stream;
  void updatePlayer(Player player) => _playerUpdateSubject.add(player);
}
