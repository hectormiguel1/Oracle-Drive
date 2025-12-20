import 'package:ff13_mod_resource/models/app_game_code.dart';
import 'package:flutter/material.dart';

class GameSelector extends InheritedWidget {
  final AppGameCode selectedGame;
  final ValueChanged<AppGameCode> onGameChanged;

  const GameSelector({
    super.key,
    required this.selectedGame,
    required this.onGameChanged,
    required super.child,
  });

  static GameSelector? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GameSelector>();
  }

  @override
  bool updateShouldNotify(GameSelector oldWidget) {
    return selectedGame != oldWidget.selectedGame;
  }
}
