import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/game_model.dart';
import '../models/genre_model.dart';
import '../services/game_service.dart';
import 'detail_page.dart';
import 'widgets/mature_overlay.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GameService _service = GameService();
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  List<Game>  _featured = [];
  List<Game>  _topRated = [];
  List<Genre> _genres   = [];
  bool   _isLoading = true;
  String? _error;
  int    _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_featured.isEmpty) return;
      final next = (_bannerIndex + 1) % _featured.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pickRandomGame() {
    if (_topRated.isEmpty) return;
    final game = (_topRated..shuffle()).first;
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => DetailPage(game: game)));
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getGames(pageSize: 6,  ordering: '-added'),
        _service.getGames(pageSize: 20, ordering: '-rating'),
        _service.getGenres(),
      ]);
      setState(() {
        _featured = results[0] as List<Game>;
        _topRated = results[1] as List<Game>;
        _genres   = results[2] as List<Genre>;
        _isLoading = false;
      });
      _startBannerTimer();
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF05000A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFB200FF)),
              const SizedBox(height: 16),
              Text('Cargando PlayRift...',
                style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 16)),
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
      backgroundColor: const Color(0xFF05000A),
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──
          SliverAppBar(
            floating: true,
            backgroundColor: const Color(0xFF05000A),
            title: Text('PlayRift',
              style: GoogleFonts.orbitron(
                color: const Color(0xFFB200FF),
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 2,
              )),
            actions: [
              IconButton(
                icon: const Icon(Icons.casino, color: Color(0xFF00E5FF)),
                tooltip: 'Juego aleatorio',
                onPressed: _pickRandomGame,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white38),
                onPressed: _loadAll,
              ),
            ],
          ),

          SliverList(
            delegate: SliverChildListDelegate([

              // ── Hero Banner ──
              _buildHeroBanner(),

              const SizedBox(height: 28),

              // ── Géneros ──
              _sectionTitle('Géneros'),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _genres.length,
                  itemBuilder: (_, i) => _genreChip(_genres[i]),
                ),
              ),

              const SizedBox(height: 28),

              // ── Mejor valorados ──
              _sectionTitle('Mejor valorados'),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _topRated.length,
                itemBuilder: (_, i) => _gameListTile(_topRated[i], i + 1),
              ),

              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Hero Banner con PageView y auto-scroll ──
  Widget _buildHeroBanner() {
    if (_featured.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        // PageView de portadas
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _featured.length,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemBuilder: (_, i) {
              final game = _featured[i];
              return GestureDetector(
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => DetailPage(game: game))),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagen de fondo
                    Hero(
                      tag: 'game-${game.id}',
                      child: game.backgroundImage.isNotEmpty
                        ? Image.network(game.backgroundImage,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFF1A0030)))
                        : Container(color: const Color(0xFF1A0030)),
                    ),

                    // Gradiente inferior
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF05000A).withOpacity(0.6),
                            const Color(0xFF05000A).withOpacity(0.98),
                          ],
                          stops: const [0.3, 0.7, 1.0],
                        ),
                      ),
                    ),

                    // Texto sobre la imagen
                    Positioned(
                      bottom: 20, left: 20, right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(game.name,
                            style: GoogleFonts.rajdhani(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.star,
                              color: Color(0xFF00E5FF), size: 15),
                            const SizedBox(width: 4),
                            Text('${game.rating}',
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            if (game.genres.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFB200FF)
                                      .withOpacity(0.6)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(game.genres.first.name,
                                  style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                              ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Indicadores de página
        Positioned(
          bottom: 20, right: 20,
          child: Row(
            children: List.generate(_featured.length, (i) {
              final isActive = i == _bannerIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(left: 4),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                    ? const Color(0xFFB200FF)
                    : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Widgets de apoyo ──

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        )),
    );
  }

  Widget _genreChip(Genre genre) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFB200FF).withOpacity(0.1),
          border: Border.all(
            color: const Color(0xFFB200FF).withOpacity(0.5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(genre.name,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ),
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
          color: const Color(0xFF0D0018),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: const Color(0xFFB200FF).withOpacity(0.6), width: 3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text('$rank',
                style: const TextStyle(
                  color: Colors.white24, fontSize: 18,
                  fontWeight: FontWeight.bold)),
            ),
            game.esrbRating?.isMature == true
                ? MatureOverlay(
                    width: 64, height: 48,
                    borderRadius: BorderRadius.circular(4))
                : Hero(
                    tag: 'game-${game.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: game.backgroundImage.isNotEmpty
                        ? Image.network(game.backgroundImage,
                            width: 64, height: 48, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 64, height: 48, color: Colors.grey[900],
                              child: const Icon(Icons.videogame_asset,
                                color: Colors.white24)))
                        : Container(width: 64, height: 48,
                            color: Colors.grey[900]),
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star,
                      color: Color(0xFF00E5FF), size: 12),
                    const SizedBox(width: 4),
                    Text('${game.rating}',
                      style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 12),
                    Text(
                      game.genres.isNotEmpty
                        ? game.genres.first.name : '',
                      style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}