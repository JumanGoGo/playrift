import 'genre_model.dart';

class Game {
  final int id;
  final String name;
  final String released;
  final String backgroundImage;
  final double rating;
  final int metacritic;
  final int playtime;
  final List<Genre> genres;
  final List<Platform> platforms;

  Game({
    required this.id,
    required this.name,
    required this.released,
    required this.backgroundImage,
    required this.rating,
    required this.metacritic,
    required this.playtime,
    required this.genres,
    required this.platforms,
  });


  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id:              json['id']               ?? 0,
      name:            json['name']             ?? '',
      released:        json['released']         ?? '',
      backgroundImage: json['background_image'] ?? '',
      rating:          (json['rating'] ?? 0).toDouble(),
      metacritic:      json['metacritic']       ?? 0,
      playtime:        json['playtime']         ?? 0,
      genres: (json['genres'] as List<dynamic>? ?? [])
          .map((g) => Genre.fromJson(g))
          .toList(),
      platforms: (json['platforms'] as List<dynamic>? ?? [])
        .map((p) => Platform.fromJson(p))
        .toList(),
    );
    
  }
}

class Platform {
  final int id;
  final String name;
  final String slug;

  Platform({required this.id, required this.name, required this.slug});

  factory Platform.fromJson(Map<String, dynamic> json) {
    // La API anida la plataforma: { "platform": { "id": 1, "name": "PC" } }
    final p = json['platform'] ?? {};
    return Platform(
      id:   p['id']   ?? 0,
      name: p['name'] ?? '',
      slug: p['slug'] ?? '',
    );
  }
}