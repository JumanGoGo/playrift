import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/game_model.dart';
import '../models/genre_model.dart';
import '../services/game_service.dart';
import '../services/favorites_service.dart';
import 'detail_page.dart';
import 'widgets/mature_overlay.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => BrowsePageState();
}

class BrowsePageState extends State<BrowsePage> {
  final GameService _service = GameService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Game> _games = [];
  List<Genre> _genres = [];
  Set<int> _favoriteIds = {};
  bool _isLoading = true;
  String? _error;
  int? _selectedGenreId;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  Timer? _debounce;

  String _ordering = '-rating';
  final List<_SortOption> _sortOptions = const [
    _SortOption(
        label: 'Top Rating', value: '-rating', icon: Icons.star_rounded),
    _SortOption(
        label: 'Recientes', value: '-released', icon: Icons.schedule_rounded),
    _SortOption(
        label: 'Populares', value: '-added', icon: Icons.trending_up_rounded),
    _SortOption(
        label: 'Metacritic',
        value: '-metacritic',
        icon: Icons.bar_chart_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadGenres();
    _loadGames(reset: true);
    _loadFavoriteIds();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadFavoriteIds() async {
    final favs = await FavoritesService.getFavorites();
    setState(() => _favoriteIds = favs.map((g) => g.id).toSet());
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
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _service.getGenres();
      setState(() => _genres = genres);
    } catch (_) {}
  }

  Future<void> _loadGames({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _hasMore = true;
      });
    }
    try {
      final results = await _service.getGames(
        page: reset ? 1 : _currentPage,
        pageSize: 20,
        search: _searchController.text,
        genreId: _selectedGenreId,
        ordering: _ordering,
      );
      setState(() {
        if (reset) {
          _games = results;
        } else {
          _games.addAll(results);
        }
        _hasMore = results.length == 20;
        _currentPage = (reset ? 1 : _currentPage) + 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    await _loadGames(reset: false);
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadGames(reset: true);
    });
  }

  void filterByGenre(int genreId) {
    setState(() => _selectedGenreId = genreId);
    _loadGames(reset: true);
  }

  void _selectGenre(Genre? genre) {
    setState(() => _selectedGenreId = genre?.id);
    _loadGames(reset: true);
  }

  void _selectOrdering(String value) {
    if (_ordering == value) return;
    setState(() => _ordering = value);
    _loadGames(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Explorar',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  )),
            ),

            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: GoogleFonts.inter(
                    color: const Color(0xFFF1F5F9), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar juegos...',
                  hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF475569), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF475569), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF64748B), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadGames(reset: true);
                          })
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF141829),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E2340)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Genre chips
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _genres.length + 1,
                itemBuilder: (_, i) {
                  final isAll = i == 0;
                  final genre = isAll ? null : _genres[i - 1];
                  final selected = isAll
                      ? _selectedGenreId == null
                      : _selectedGenreId == genre!.id;

                  return GestureDetector(
                    onTap: () => _selectGenre(genre),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF141829),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF1E2340),
                        ),
                      ),
                      child: Text(
                        isAll ? 'Todos' : genre!.name,
                        style: GoogleFonts.inter(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Sort chips
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _sortOptions.length,
                itemBuilder: (_, i) {
                  final opt = _sortOptions[i];
                  final selected = _ordering == opt.value;
                  return GestureDetector(
                    onTap: () => _selectOrdering(opt.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF06B6D4).withAlpha(25)
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF06B6D4).withAlpha(100)
                              : const Color(0xFF1E2340),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(opt.icon,
                              size: 12,
                              color: selected
                                  ? const Color(0xFF06B6D4)
                                  : const Color(0xFF475569)),
                          const SizedBox(width: 4),
                          Text(opt.label,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF06B6D4)
                                    : const Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Grid
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFEF4444), size: 32),
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFF64748B), fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _loadGames(reset: true),
                child: const Text('Reintentar',
                    style: TextStyle(color: Color(0xFF8B5CF6))),
              ),
            ],
          ),
        ),
      );
    }
    if (_games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                color: Color(0xFF334155), size: 48),
            const SizedBox(height: 12),
            Text('No se encontraron juegos',
                style: GoogleFonts.inter(
                    color: const Color(0xFF64748B), fontSize: 15)),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _games.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (_, i) {
        if (i >= _games.length) return _skeletonCard();
        return _gameCard(_games[i]);
      },
    );
  }

  Widget _gameCard(Game game) {
    final isFav = _favoriteIds.contains(game.id);
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => DetailPage(game: game)));
        _loadFavoriteIds();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141829),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E2340)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Expanded(
              flex: 5,
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
                                  alignment: Alignment.topCenter,
                                  errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFF1E2340),
                                      child: const Icon(
                                          Icons.videogame_asset_rounded,
                                          color: Color(0xFF334155),
                                          size: 28)))
                              : Container(color: const Color(0xFF1E2340)),
                        ),
                  // Bottom gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF141829).withAlpha(230),
                          ],
                          stops: const [0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(game),
                      child: Container(
                        padding: const EdgeInsets.all(6),
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
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0E1A).withAlpha(200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFBBF24), size: 12),
                          const SizedBox(width: 3),
                          Text('${game.rating}',
                              style: const TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.name,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF1F5F9),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (game.genres.isNotEmpty)
                      Text(
                          game.genres.map((g) => g.name).take(2).join(' · '),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    if (game.metacritic > 0)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: _metacriticColor(game.metacritic)
                                  .withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${game.metacritic}',
                                style: TextStyle(
                                    color:
                                        _metacriticColor(game.metacritic),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 4),
                          const Text('Metacritic',
                              style: TextStyle(
                                  color: Color(0xFF475569), fontSize: 9)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _metacriticColor(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _skeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141829),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2340)),
      ),
    );
  }
}

class _SortOption {
  final String label;
  final String value;
  final IconData icon;
  const _SortOption({
    required this.label,
    required this.value,
    required this.icon,
  });
}
