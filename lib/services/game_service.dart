import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/game_model.dart';
import '../models/genre_model.dart';

class GameService {
  final String _base = AppConfig.baseUrl;
  final String _key  = AppConfig.apiKey;

  /// Lista de juegos con soporte de búsqueda, filtro y paginación
  Future<List<Game>> getGames({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? genreId,
    String ordering = '-rating',
  }) async {
    final params = {
      'key':       _key,
      'page':      page.toString(),
      'page_size': pageSize.toString(),
      'ordering':  ordering,
      if (search  != null && search.isNotEmpty) 'search':  search,
      if (genreId != null)                      'genres':  genreId.toString(),
    };

    final uri = Uri.parse('$_base/games').replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'] ?? [];
      return results.map((j) => Game.fromJson(j)).toList();
    } else {
      throw Exception('Error al cargar juegos: ${response.statusCode}');
    }
  }

  /// Detalle completo de un juego (incluye description_raw)
  Future<Game> getGameDetail(int gameId) async {
    final uri = Uri.parse('$_base/games/$gameId').replace(
      queryParameters: {'key': _key},
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Game.fromJson(data);
    } else {
      throw Exception('Error al cargar detalle: ${response.statusCode}');
    }
  }

  /// Screenshots de un juego específico
  Future<List<String>> getScreenshots(int gameId) async {
    final uri = Uri.parse('$_base/games/$gameId/screenshots').replace(
      queryParameters: {'key': _key},
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'] ?? [];
      return results.map((s) => s['image'] as String? ?? '').where((url) => url.isNotEmpty).toList();
    } else {
      throw Exception('Error al cargar screenshots: ${response.statusCode}');
    }
  }

  /// Juegos de la misma saga
  Future<List<Game>> getGameSeries(int gameId) async {
    final uri = Uri.parse('$_base/games/$gameId/game-series').replace(
      queryParameters: {'key': _key, 'page_size': '10'},
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'] ?? [];
      return results.map((j) => Game.fromJson(j)).toList();
    } else {
      throw Exception('Error al cargar saga: ${response.statusCode}');
    }
  }

  /// Lista de géneros disponibles
  Future<List<Genre>> getGenres() async {
    final uri = Uri.parse('$_base/genres').replace(
      queryParameters: {'key': _key, 'page_size': '20'},
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'] ?? [];
      return results.map((j) => Genre.fromJson(j)).toList();
    } else {
      throw Exception('Error al cargar géneros: ${response.statusCode}');
    }
  }
}