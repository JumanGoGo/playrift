class Genre {
  final int id;
  final String name;
  final String slug;

  Genre({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id:   json['id']   ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}