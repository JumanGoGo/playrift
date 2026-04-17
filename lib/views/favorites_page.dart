import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_model.dart';
import '../services/favorites_service.dart';
import 'detail_page.dart';
import 'widgets/mature_overlay.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => FavoritesPageState();
}

class FavoritesPageState extends State<FavoritesPage> {
  void refresh() => _loadFavorites();

  List<Game> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final favorites = await FavoritesService.getFavorites();
    setState(() {
      _favorites = favorites;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(int gameId) async {
    await FavoritesService.remove(gameId);
    _loadFavorites();
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
              child: Row(
                children: [
                  Text('Favoritos',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFF1F5F9),
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      )),
                  const Spacer(),
                  if (_favorites.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF8B5CF6).withAlpha(50)),
                      ),
                      child: Text(
                          '${_favorites.length} juego${_favorites.length == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                              color: const Color(0xFFA78BFA),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5CF6),
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : _favorites.isEmpty
                      ? _buildEmptyState()
                      : _buildFavoritesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF141829),
                border: Border.all(color: const Color(0xFF1E2340), width: 2),
              ),
              child: const Icon(Icons.favorite_border_rounded,
                  color: Color(0xFF334155), size: 36),
            ),
            const SizedBox(height: 24),
            Text('Sin favoritos aún',
                style: GoogleFonts.inter(
                  color: const Color(0xFFF1F5F9),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            Text(
                'Explora el catálogo y marca juegos\ncon el corazón para guardarlos aquí',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.5,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: _favorites.length,
      itemBuilder: (_, i) {
        final game = _favorites[i];
        return Dismissible(
          key: ValueKey(game.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444), size: 22),
                SizedBox(height: 2),
                Text('Eliminar',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 10)),
              ],
            ),
          ),
          onDismissed: (_) => _removeFavorite(game.id),
          child: _buildFavoriteTile(game),
        );
      },
    );
  }

  Widget _buildFavoriteTile(Game game) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => DetailPage(game: game)));
        _loadFavorites();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF141829),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E2340)),
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: game.isMatureContent
                  ? MatureOverlay(
                      width: 72,
                      height: 54,
                      borderRadius: BorderRadius.circular(10))
                  : game.backgroundImage.isNotEmpty
                      ? Hero(
                          tag: 'game-${game.id}',
                          child: Image.network(game.backgroundImage,
                              width: 72,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  width: 72,
                                  height: 54,
                                  color: const Color(0xFF1E2340),
                                  child: const Icon(
                                      Icons.videogame_asset_rounded,
                                      color: Color(0xFF334155)))),
                        )
                      : Container(
                          width: 72,
                          height: 54,
                          color: const Color(0xFF1E2340)),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.name,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFF1F5F9),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFBBF24), size: 12),
                    const SizedBox(width: 3),
                    Text('${game.rating}',
                        style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    if (game.metacritic > 0) ...[
                      const SizedBox(width: 10),
                      Text('MC ${game.metacritic}',
                          style: TextStyle(
                              color: game.metacritic >= 80
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(width: 10),
                    if (game.genres.isNotEmpty)
                      Expanded(
                        child: Text(game.genres.first.name,
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                  ]),
                ],
              ),
            ),

            // Remove button
            GestureDetector(
              onTap: () => _removeFavorite(game.id),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.favorite_rounded,
                    color: Color(0xFFEC4899), size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
