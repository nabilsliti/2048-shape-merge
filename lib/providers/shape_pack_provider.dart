import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shape_merge/core/constants/shape_pack.dart';

final shapePackProvider =
    StateNotifierProvider<ShapePackNotifier, ShapePack>(
        (ref) => ShapePackNotifier());

class ShapePackNotifier extends StateNotifier<ShapePack> {
  static const _key = 'shapePack';

  ShapePackNotifier() : super(ShapePack.classic) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (name != null) {
      state = ShapePack.values.firstWhere(
        (p) => p.name == name,
        orElse: () => ShapePack.classic,
      );
    }
  }

  Future<void> select(ShapePack pack) async {
    state = pack;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, pack.name);
  }
}
