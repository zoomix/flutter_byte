import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:lag_byte/model/player.dart';
import 'package:lag_byte/services/players_messagebus.dart';
import 'package:lag_byte/services/positions_messagebus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void persistPlayers(List<Player> players) {
  SharedPreferences.getInstance().then((SharedPreferences sp) {
    sp.setStringList('players',
        players.map((player) => jsonEncode(player.toMap())).toList());
  });
}
