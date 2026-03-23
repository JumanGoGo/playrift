import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../models/genre_model.dart';
import '../services/game_service.dart';
import 'detail_page.dart';
import 'dart:async';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final GameService _service = GameService();
  final TextEditingController _searchController = TextEditingController();

  List<Game>  _games  = [];
  List<Genre> _genres = [];
  bool   _isLoading = true;
  String? _error;
  int?   _selectedGenreId;
  String _selectedGenreName = 'Todos';
  int    _currentPage = 1;
  bool   _hasMore = true;
  bool   _isLoadingMore = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadGenres();
    _loadGames(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _service.getGenres();
      setState(() => _genres = genres);
    } catch (_) {}
  }

  Future<void> _loadGames({bool reset = false}) async {
    if (reset) {
      setState(() { _isLoading = true; _error = null; _currentPage = 1; _hasMore = true; });
    }

    try {
      final results = await _service.getGames(
        page:     reset ? 1 : _currentPage,
        pageSize: 20,
        search:   _searchController.text,
        genreId:  _selectedGenreId,
      );

      setState(() {
        if (reset) {
          _games = results;
        } else {
          _games.addAll(results);
        }
        _hasMore    = results.length == 20;
        _currentPage = (reset ? 1 : _currentPage) + 1;
        _isLoading      = false;
        _isLoadingMore  = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; _isLoadingMore = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
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
    setState(() {
      _selectedGenreId   = genre?.id;
      _selectedGenreName = genre?.name ?? 'Todos';
    });
    _loadGames(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('Explorar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Barra de búsqueda ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar juego...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white38),
                        onPressed: () {
                          _searchController.clear();
                          _loadGames(reset: true);
                        })
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Chips de género ──
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _genres.length + 1,
              itemBuilder: (context, i) {
                final isAll      = i == 0;
                final genre      = isAll ? null : _genres[i - 1];
                final isSelected = isAll
                    ? _selectedGenreId == null
                    : _selectedGenreId == genre!.id;

                return GestureDetector(
                  onTap: () => _selectGenre(genre),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF107C10)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAll ? 'Todos' : genre!.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Resultados ──
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF107C10)));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadGames(reset: true),
            child: const Text('Reintentar')),
        ]));
    }
    if (_games.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron juegos\npara "$_selectedGenreName"',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 16)));
    }

    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _games.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        // Botón cargar más al final
        if (i == _games.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isLoadingMore
                  ? const CircularProgressIndicator(color: Color(0xFF107C10))
                  : ElevatedButton.icon(
                      onPressed: _loadMore,
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Cargar más'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF107C10),
                        foregroundColor: Colors.white,
                      )),
            ),
          );
        }

                final game = _games[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailPage(game: game)),
            ),
            child: Container(        // Container baja un nivel, se vuelve hijo
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
              // Miniatura
              Hero(
                tag: 'game-${game.id}',
                child:
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10)),
                  child: game.backgroundImage.isNotEmpty
                      ? Image.network(game.backgroundImage,
                          width: 110, height: 72, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 110, height: 72, color: Colors.grey[900],
                            child: const Icon(Icons.videogame_asset,
                                color: Colors.white24)))
                      : Container(width: 110, height: 72, color: Colors.grey[900]),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
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
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.star, color: Color(0xFF107C10), size: 13),
                        const SizedBox(width: 4),
                        Text('${game.rating}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(width: 12),
                        if (game.genres.isNotEmpty)
                          Text(game.genres.first.name,
                            style: const TextStyle(color: Colors.white30, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      );
      },
    );
  }
}