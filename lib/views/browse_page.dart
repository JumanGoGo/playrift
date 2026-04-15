import 'package:flutter/material.dart';
import 'dart:async';
import '../models/game_model.dart';
import '../models/genre_model.dart';
import '../services/game_service.dart';
import 'detail_page.dart';
import 'widgets/mature_overlay.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final GameService _service = GameService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Game>  _games  = [];
  List<Genre> _genres = [];
  bool   _isLoading = true;
  String? _error;
  int?   _selectedGenreId;
  int    _currentPage = 1;
  bool   _hasMore = true;
  bool   _isLoadingMore = false;
  Timer? _debounce;

  // Ordenamiento
  String _ordering = '-rating';
  final List<_SortOption> _sortOptions = const [
    _SortOption(label: 'Mejor valorados', value: '-rating'),
    _SortOption(label: 'Más recientes',   value: '-released'),
    _SortOption(label: 'Más añadidos',    value: '-added'),
    _SortOption(label: 'Metacritic',      value: '-metacritic'),
  ];

  @override
  void initState() {
    super.initState();
    _loadGenres();
    _loadGames(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Auto cargar más al llegar al final del scroll
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
        _isLoading = true; _error = null;
        _currentPage = 1; _hasMore = true;
      });
    }
    try {
      final results = await _service.getGames(
        page:     reset ? 1 : _currentPage,
        pageSize: 20,
        search:   _searchController.text,
        genreId:  _selectedGenreId,
        ordering: _ordering,
      );
      setState(() {
        if (reset) {
          _games = results;
        } else {
          _games.addAll(results);
        }
        _hasMore     = results.length == 20;
        _currentPage = (reset ? 1 : _currentPage) + 1;
        _isLoading       = false;
        _isLoadingMore   = false;
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
      backgroundColor: const Color(0xFF05000A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05000A),
        title: const Text('Explorar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20)),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ── Barra de búsqueda ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar juego...',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.search, color: Colors.white30),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white30),
                      onPressed: () {
                        _searchController.clear();
                        _loadGames(reset: true);
                      })
                  : null,
                filled: true,
                fillColor: const Color(0xFFB200FF).withOpacity(0.06),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFFB200FF).withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFB200FF), width: 1),
                ),
              ),
            ),
          ),

          // ── Chips de género ──
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _genres.length + 1,
              itemBuilder: (_, i) {
                final isAll    = i == 0;
                final genre    = isAll ? null : _genres[i - 1];
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
                        ? const Color(0xFFB200FF).withOpacity(0.2)
                        : Colors.transparent,
                      border: Border.all(
                        color: selected
                          ? const Color(0xFFB200FF)
                          : Colors.white12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAll ? 'Todos' : genre!.name,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white38,
                        fontSize: 12,
                        fontWeight: selected
                          ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Chips de ordenamiento ──
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sortOptions.length,
              itemBuilder: (_, i) {
                final opt      = _sortOptions[i];
                final selected = _ordering == opt.value;
                return GestureDetector(
                  onTap: () => _selectOrdering(opt.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected
                        ? const Color(0xFF00E5FF).withOpacity(0.1)
                        : Colors.transparent,
                      border: Border.all(
                        color: selected
                          ? const Color(0xFF00E5FF).withOpacity(0.6)
                          : Colors.white12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(opt.label,
                      style: TextStyle(
                        color: selected
                          ? const Color(0xFF00E5FF) : Colors.white30,
                        fontSize: 11,
                        fontWeight: selected
                          ? FontWeight.bold : FontWeight.normal,
                      )),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ── Grid de juegos ──
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB200FF)));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.white54),
            textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadGames(reset: true),
            child: const Text('Reintentar')),
        ]));
    }
    if (_games.isEmpty) {
      return const Center(
        child: Text('No se encontraron juegos',
          style: TextStyle(color: Colors.white38, fontSize: 16)));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,   // tarjetas ligeramente altas
      ),
      itemCount: _games.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (_, i) {
        // Skeleton loader al final
        if (i >= _games.length) return _skeletonCard();

        final game = _games[i];
        return GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => DetailPage(game: game))),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0018),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFB200FF).withOpacity(0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Portada
                // Portada con protección de contenido maduro
                      Expanded(
                        flex: 3,
                        child: game.esrbRating?.isMature == true
                          // ── Juego maduro: muestra advertencia ──
                          ? MatureOverlay(
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            )
                          // ── Juego normal: muestra portada ──
                          : Hero(
                              tag: 'game-${game.id}',
                              child: game.backgroundImage.isNotEmpty
                                ? Image.network(
                                    game.backgroundImage,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFF1A0030),
                                      child: const Icon(Icons.videogame_asset,
                                        color: Colors.white12, size: 40)))
                                : Container(color: const Color(0xFF1A0030)),
                            ),
                      ),

                // Info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(game.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                        Row(children: [
                          const Icon(Icons.star,
                            color: Color(0xFF00E5FF), size: 11),
                          const SizedBox(width: 3),
                          Text('${game.rating}',
                            style: const TextStyle(
                              color: Color(0xFF00E5FF), fontSize: 11)),
                          const Spacer(),
                          if (game.genres.isNotEmpty)
                            Text(game.genres.first.name,
                              style: const TextStyle(
                                color: Colors.white24, fontSize: 10)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Tarjeta placeholder mientras carga más
  Widget _skeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0018),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB200FF).withOpacity(0.1)),
      ),
    );
  }
}

// Clase auxiliar para las opciones de ordenamiento
class _SortOption {
  final String label;
  final String value;
  const _SortOption({required this.label, required this.value});
}