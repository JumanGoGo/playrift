import 'genre_model.dart';

class Game {
  final int id;
  final String name;
  final String description;
  final String released;
  final String backgroundImage;
  final double rating;
  final int metacritic;
  final int playtime;
  final List<Genre> genres;
  final List<Platform> platforms;
  final EsrbRating? esrbRating;
  final List<String> tags;

  Game({
    required this.id,
    required this.name,
    this.description = '',
    required this.released,
    required this.backgroundImage,
    required this.rating,
    required this.metacritic,
    required this.playtime,
    required this.genres,
    required this.platforms,
    required this.esrbRating,
    this.tags = const [],
  });

  /// Detecta contenido adulto por palabras clave en nombre
  static final _matureKeywords = RegExp(
    r'(porn|porno|hentai|xxx|erotic|nsfw|sex\s?game|adults?only|mom got stuck|ntr?|netorare|nejicomisimulator|18\+)',
    caseSensitive: false,
  );

  bool get isMatureContent =>
    _matureKeywords.hasMatch(name) ||
    _matureKeywords.hasMatch(description) ||
    tags.any((tag) => _matureKeywords.hasMatch(tag));

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id:              json['id']               ?? 0,
      name:            json['name']             ?? '',
      description:     json['description_raw']  ?? json['description'] ?? '',
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
      esrbRating: json['esrb_rating'] != null
    ? EsrbRating.fromJson(json['esrb_rating'])
    : null,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((t) => (t['name'] ?? '').toString())
          .toList(),
    );
  }

  /// Crea una copia del juego con una descripción actualizada
  Game copyWithDescription(String newDescription) {
    return Game(
      id: id,
      name: name,
      description: newDescription,
      released: released,
      backgroundImage: backgroundImage,
      rating: rating,
      metacritic: metacritic,
      playtime: playtime,
      genres: genres,
      platforms: platforms,
      esrbRating: esrbRating,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description_raw': description,
      'released': released,
      'background_image': backgroundImage,
      'rating': rating,
      'metacritic': metacritic,
      'playtime': playtime,
      'genres': genres.map((g) => g.toJson()).toList(),
      'platforms': platforms.map((p) => p.toJson()).toList(),
      'esrb_rating': esrbRating?.toJson(),
      'tags': tags.map((t) => {'name': t}).toList(),
    };
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

  Map<String, dynamic> toJson() {
    return {'platform': {'id': id, 'name': name, 'slug': slug}};
  }
}

class EsrbRating {
  final int id;
  final String name;
  final String slug;

  EsrbRating({required this.id, required this.name, required this.slug});

  factory EsrbRating.fromJson(Map<String, dynamic> json) {
    return EsrbRating(
      id:   json['id']   ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  // true si el contenido es para mayores de edad
  bool get isMature =>
    slug == 'mature' || slug == 'adults-only';

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug};
  }
}