import 'package:get_it/get_it.dart';
import 'package:lag_byte/services/players_messagebus.dart';
import 'package:lag_byte/services/positions_messagebus.dart';

class Tuple<T1, T2> {
  final T1 item1;
  final T2 item2;

  const Tuple({required this.item1, required this.item2});
}

GetIt locator = GetIt.instance;
void setupLocator() {
  locator.registerSingleton(PlayersMessagebus());
  locator.registerSingleton(PositionsMessagebus());
}
