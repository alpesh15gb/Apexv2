import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final _storage = const FlutterSecureStorage();

  FavoritesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    try {
      final jsonStr = await _storage.read(key: 'favorite_routes');
      if (jsonStr != null) {
        final list = json.decode(jsonStr) as List;
        state = list.map((e) => e.toString()).toSet();
      }
    } catch (_) {}
  }

  Future<void> toggleFavorite(String route) async {
    final updated = Set<String>.from(state);
    if (updated.contains(route)) {
      updated.remove(route);
    } else {
      updated.add(route);
    }
    state = updated;
    try {
      await _storage.write(key: 'favorite_routes', value: json.encode(updated.toList()));
    } catch (_) {}
  }

  bool isFavorite(String route) {
    return state.contains(route);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});
