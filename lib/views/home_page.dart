import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../models/genre_model.dart';
import '../services/game_service.dart';
import 'browse_page.dart';
import 'detail_page.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GameService _service = GameService();

  List<Game> _featured = [];
  List<Game> _topRated = [];
  List<Genre> _genres  = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _pickRandomGame() {
    if (_topRated.isEmpty) return;
    final random = (_topRated..shuffle()).first;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailPage(game: random)),
    );
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getGames(pageSize: 5,  ordering: '-added'),
        _service.getGames(pageSize: 20, ordering: '-rating'),
        _service.getGenres(),
      ]);
      setState(() {
        _featured = results[0] as List<Game>;
        _topRated = results[1] as List<Game>;
        _genres   = results[2] as List<Genre>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF107C10)),
              SizedBox(height: 16),
              Text('Cargando PlayRift...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _loadAll, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 60,
            floating: true,
            backgroundColor: const Color(0xFF0A0A0A),
            title: const Text(
              'PlayRift',
              style: TextStyle(
                color: Color(0xFF107C10),
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 2,
              ),
            ),
           actions: [
              IconButton(
                icon: const Icon(Icons.casino, color: Color(0xFF107C10)),
                tooltip: 'Juego aleatorio',
                onPressed: _pickRandomGame,
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white70),
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => BrowsePage())),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _loadAll,
              ),
            ],
          ),

          
          // Contenido en scroll
          SliverList(
            delegate: SliverChildListDelegate([

              // ── Sección: Destacados ──
              _sectionTitle('Destacados'),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _featured.length,
                  itemBuilder: (context, i) => _featuredCard(_featured[i]),
                ),
              ),

              const SizedBox(height: 24),

              // ── Sección: Géneros ──
              _sectionTitle('Géneros'),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _genres.length,
                  itemBuilder: (context, i) => _genreChip(_genres[i]),
                ),
              ),

              const SizedBox(height: 24),

              // ── Sección: Mejor valorados ──
              _sectionTitle('Mejor valorados'),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _topRated.length,
                itemBuilder: (context, i) => _gameListTile(_topRated[i], i + 1),
              ),

              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Widgets de apoyo ──

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
  

  
  
  
 Widget _featuredCard(Game game) {
  return GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailPage(game: game)),
    ),
    child: Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[900],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de portada
            Hero(
              tag: 'game-${game.id}',       // tag único por juego
              child:
              game.backgroundImage.isNotEmpty
              ? Image.network(
                  game.backgroundImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.videogame_asset,
                    color: Colors.white24,
                    size: 48,
                  ),
                )
              : const Icon(
                  Icons.videogame_asset,
                  color: Colors.white24,
                  size: 48,
                ),
            ),

          // Gradiente inferior
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // Nombre y rating
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFF107C10),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${game.rating}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _genreChip(Genre genre) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF107C10)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(genre.name,
        style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _gameListTile(Game game, int rank) {
    return GestureDetector(
  onTap: () => Navigator.push(context,
    MaterialPageRoute(builder: (_) => DetailPage(game: game))),
  child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Número de ranking
          SizedBox(
            width: 32,
            child: Text('$rank',
              style: const TextStyle(color: Colors.white24, fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          // Miniatura
          Hero(
            tag: 'game-${game.id}',
            child:
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: game.backgroundImage.isNotEmpty
                ? Image.network(game.backgroundImage, width: 64, height: 48, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(width: 64, height: 48, color: Colors.grey[800],
                            child: const Icon(Icons.videogame_asset, color: Colors.white24)))
                : Container(width: 64, height: 48, color: Colors.grey[800]),
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star, color: Color(0xFF107C10), size: 12),
                  const SizedBox(width: 4),
                  Text('${game.rating}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 12),
                  Text(game.genres.isNotEmpty ? game.genres.first.name : '',
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ]),
              ],
            ),
          ),
        ],
      ),
    )
    );
  }
}

