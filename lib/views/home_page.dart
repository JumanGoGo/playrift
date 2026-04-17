import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/game_model.dart';
import '../models/genre_model.dart';
import '../services/game_service.dart';
import '../services/favorites_service.dart';
import 'detail_page.dart';
import 'widgets/mature_overlay.dart';

class HomePage extends StatefulWidget {
  final void Function(int genreId)? onGenreTap;
  const HomePage({super.key, this.onGenreTap});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GameService _service = GameService();
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  List<Game> _featured = [];
  List<Game> _topRated = [];
  List<Genre> _genres = [];
  Set<int> _favoriteIds = {};
  bool _isLoading = true;
  String? _error;
  int _bannerIndex = 0;

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
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_featured.isEmpty || !_bannerController.hasClients) return;
      final next = (_bannerIndex + 1) % _featured.length;
      if (next == 0) {
        _bannerController.jumpToPage(0);
      } else {
        _bannerController.animateToPage(next,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    });
  }

  void _pickRandomGame() {
    if (_topRated.isEmpty) return;
    final game = (_topRated..shuffle()).first;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => DetailPage(game: game)));
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getGames(pageSize: 6, ordering: '-added'),
        _service.getGames(pageSize: 20, ordering: '-rating'),
        _service.getGenres(),
        FavoritesService.getFavorites(),
      ]);
      setState(() {
        _featured = results[0] as List<Game>;
        _topRated = results[1] as List<Game>;
        _genres = results[2] as List<Genre>;
        _favoriteIds = (results[3] as List<Game>).map((g) => g.id).toSet();
        _isLoading = false;
      });
      _startBannerTimer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(Game game) async {
    final nowFav = await FavoritesService.toggle(game);
    setState(() {
      if (nowFav) {
        _favoriteIds.add(game.id);
      } else {
        _favoriteIds.remove(game.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: const Color(0xFF8B5CF6),
        backgroundColor: const Color(0xFF141829),
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              floating: true,
              backgroundColor: const Color(0xFF0A0E1A),
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('PR',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        )),
                  ),
                  const SizedBox(width: 10),
                  Text('PlayRift',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: 1,
                      )),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.casino_rounded,
                      color: Color(0xFF06B6D4), size: 22),
                  tooltip: 'Juego aleatorio',
                  onPressed: _pickRandomGame,
                ),
                const SizedBox(width: 4),
              ],
            ),

            SliverList(
              delegate: SliverChildListDelegate([
                // Hero Banner
                _buildHeroBanner(),
                const SizedBox(height: 28),

                // Géneros
                _sectionHeader('Géneros'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _genres.length,
                    itemBuilder: (_, i) => _genreChip(_genres[i]),
                  ),
                ),

                const SizedBox(height: 28),

                // Top Rated — horizontal cards
                _sectionHeader('Mejor valorados'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _topRated.length,
                    itemBuilder: (_, i) => _topRatedCard(_topRated[i], i + 1),
                  ),
                ),

                const SizedBox(height: 100),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading ──
  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                color: Color(0xFF8B5CF6),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text('PLAYRIFT',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF8B5CF6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                )),
            const SizedBox(height: 8),
            Text('Cargando catálogo...',
                style: GoogleFonts.inter(
                    color: const Color(0xFF64748B), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Error ──
  Widget _buildError() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEF4444).withAlpha(20),
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    color: Color(0xFFEF4444), size: 36),
              ),
              const SizedBox(height: 24),
              Text('Error de conexión',
                  style: GoogleFonts.inter(
                      color: const Color(0xFFF1F5F9),
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFF64748B), fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Banner ──
  Widget _buildHeroBanner() {
    if (_featured.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
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
                    Hero(
                      tag: 'game-${game.id}',
                      child: game.backgroundImage.isNotEmpty
                          ? Image.network(game.backgroundImage,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: const Color(0xFF141829)))
                          : Container(color: const Color(0xFF141829)),
                    ),
                    // Gradient overlay
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x400A0E1A),
                            Color(0xCC0A0E1A),
                            Color(0xFF0A0E1A),
                          ],
                          stops: [0.15, 0.45, 0.7, 1.0],
                        ),
                      ),
                    ),
                    // Game info
                    Positioned(
                      bottom: 40,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('DESTACADO',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                )),
                          ),
                          const SizedBox(height: 10),
                          Text(game.name,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFBBF24), size: 16),
                              const SizedBox(width: 4),
                              Text('${game.rating}',
                                  style: const TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              if (game.genres.isNotEmpty) ...[
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF475569),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Text(game.genres.first.name,
                                    style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 13)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Page indicators
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_featured.length, (i) {
                final isActive = i == _bannerIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ──
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(title,
              style: GoogleFonts.inter(
                color: const Color(0xFFF1F5F9),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              )),
          const Spacer(),
        ],
      ),
    );
  }

  // ── Genre Chip ──
  Widget _genreChip(Genre genre) {
    return GestureDetector(
      onTap: () => widget.onGenreTap?.call(genre.id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2340),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2D3258)),
        ),
        child: Text(genre.name,
            style: GoogleFonts.inter(
              color: const Color(0xFFA5B4FC),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            )),
      ),
    );
  }

  // ── Top Rated Card (horizontal scroll) ──
  Widget _topRatedCard(Game game, int rank) {
    final isFav = _favoriteIds.contains(game.id);
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailPage(game: game))),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141829),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E2340)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  game.isMatureContent
                      ? const MatureOverlay(
                          width: double.infinity, height: double.infinity)
                      : Hero(
                          tag: 'game-${game.id}',
                          child: game.backgroundImage.isNotEmpty
                              ? Image.network(game.backgroundImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFF1E2340)))
                              : Container(color: const Color(0xFF1E2340)),
                        ),
                  // Gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF141829).withAlpha(200),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Rank badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rank <= 3
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF1E2340).withAlpha(200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$rank',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(game),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0E1A).withAlpha(180),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav
                              ? const Color(0xFFEC4899)
                              : const Color(0xFF94A3B8),
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.name,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFF1F5F9),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFBBF24), size: 12),
                      const SizedBox(width: 3),
                      Text('${game.rating}',
                          style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (game.genres.isNotEmpty)
                        Flexible(
                          child: Text(game.genres.first.name,
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 10),
                              overflow: TextOverflow.ellipsis),
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
}
