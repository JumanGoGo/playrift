import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';

class FavoritesService {
  static const String _key = 'favorites';

  /// Obtiene la lista completa de favoritos
  static Future<List<Game>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((j) => Game.fromJson(j)).toList();
  }

  /// Verifica si un juego está en favoritos
  static Future<bool> isFavorite(int gameId) async {
    final favorites = await getFavorites();
    return favorites.any((g) => g.id == gameId);
  }

  /// Agrega o quita un juego de favoritos. Retorna true si quedó como favorito.
  static Future<bool> toggle(Game game) async {
    final favorites = await getFavorites();
    final exists = favorites.any((g) => g.id == game.id);

    if (exists) {
      favorites.removeWhere((g) => g.id == game.id);
    } else {
      favorites.insert(0, game);
    }

    await _save(favorites);
    return !exists;
  }

  /// Elimina un juego de favoritos
  static Future<void> remove(int gameId) async {
    final favorites = await getFavorites();
    favorites.removeWhere((g) => g.id == gameId);
    await _save(favorites);
  }

  /// Guarda la lista en SharedPreferences
  static Future<void> _save(List<Game> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(favorites.map((g) => g.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}
