import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_model.dart';
import '../services/game_service.dart';
import '../services/favorites_service.dart';
import 'widgets/mature_overlay.dart';

class DetailPage extends StatefulWidget {
  final Game game;
  const DetailPage({super.key, required this.game});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final GameService _service = GameService();

  List<String> _screenshots = [];
  List<Game> _seriesGames = [];
  String _description = '';
  bool _isFavorite = false;
  bool _loadingScreenshots = true;
  bool _loadingSeries = true;
  bool _loadingDescription = true;

  Game get game => widget.game;

  @override
  void initState() {
    super.initState();
    _loadExtra();
  }

  Future<void> _loadExtra() async {
    final favFuture = FavoritesService.isFavorite(game.id);
    final ssFuture =
        _service.getScreenshots(game.id).catchError((_) => <String>[]);
    final seriesFuture =
        _service.getGameSeries(game.id).catchError((_) => <Game>[]);
    final detailFuture =
        _service.getGameDetail(game.id).catchError((_) => game);

    final results =
        await Future.wait([favFuture, ssFuture, seriesFuture, detailFuture]);

    if (!mounted) return;
    final detailGame = results[3] as Game;
    setState(() {
      _isFavorite = results[0] as bool;
      _screenshots = results[1] as List<String>;
      _seriesGames = results[2] as List<Game>;
      _description = detailGame.description;
      _loadingScreenshots = false;
      _loadingSeries = false;
      _loadingDescription = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final nowFavorite = await FavoritesService.toggle(game);
    if (!mounted) return;
    setState(() => _isFavorite = nowFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
                nowFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: const Color(0xFFEC4899),
                size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                nowFavorite
                    ? '${game.name} agregado a favoritos'
                    : '${game.name} eliminado de favoritos',
                style: const TextStyle(color: Color(0xFFF1F5F9)),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E2340),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        slivers: [
          // Hero AppBar
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: const Color(0xFF0A0E1A),
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _circleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: _circleButton(
                  icon: _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _isFavorite ? const Color(0xFFEC4899) : null,
                  onTap: _toggleFavorite,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
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
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x000A0E1A),
                          Color(0x800A0E1A),
                          Color(0xFF0A0E1A),
                        ],
                        stops: [0.3, 0.65, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Game name
                Text(game.name,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF1F5F9),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    )),

                const SizedBox(height: 16),

                // Metrics row
                _buildMetrics(),

                const SizedBox(height: 24),

                // Description
                _buildDescription(),

                // Genres
                if (game.genres.isNotEmpty) ...[
                  _sectionLabel('GÉNEROS'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: game.genres
                        .map((g) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2340),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF2D3258)),
                              ),
                              child: Text(g.name,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFA5B4FC),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Platforms
                if (game.platforms.isNotEmpty) ...[
                  _sectionLabel('PLATAFORMAS'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: game.platforms
                        .map((p) => _platformChip(p.slug, p.name))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Release date
                if (game.released.isNotEmpty) ...[
                  _sectionLabel('LANZAMIENTO'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: Color(0xFF64748B), size: 14),
                      const SizedBox(width: 8),
                      Text(game.released,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Screenshots
                _buildScreenshots(),

                // Series
                _buildSeriesGames(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(
      {required IconData icon, Color? color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E1A).withAlpha(180),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1E2340)),
        ),
        child: Icon(icon, color: color ?? const Color(0xFFF1F5F9), size: 18),
      ),
    );
  }

  // Metrics
  Widget _buildMetrics() {
    return Row(
      children: [
        _metricChip(
          icon: Icons.star_rounded,
          value: '${game.rating}',
          label: 'Rating',
          color: const Color(0xFFFBBF24),
        ),
        const SizedBox(width: 8),
        if (game.metacritic > 0) ...[
          _metricChip(
            icon: Icons.bar_chart_rounded,
            value: '${game.metacritic}',
            label: 'Metacritic',
            color: _metacriticColor(game.metacritic),
          ),
          const SizedBox(width: 8),
        ],
        if (game.playtime > 0)
          _metricChip(
            icon: Icons.timer_rounded,
            value: '${game.playtime}h',
            label: 'Promedio',
            color: const Color(0xFF64748B),
          ),
      ],
    );
  }

  Widget _metricChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141829),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E2340)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 10)),
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

  // Description
  Widget _buildDescription() {
    if (_loadingDescription) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('DESCRIPCIÓN'),
          const SizedBox(height: 10),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF141829),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    if (_description.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('DESCRIPCIÓN'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141829),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E2340)),
          ),
          child: Text(_description,
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.7,
              )),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Screenshots
  Widget _buildScreenshots() {
    if (_loadingScreenshots) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('CAPTURAS'),
          const SizedBox(height: 10),
          const SizedBox(
            height: 120,
            child: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF8B5CF6), strokeWidth: 2)),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    if (_screenshots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('CAPTURAS'),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _screenshots.length,
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () =>
                    _showFullScreenImage(context, _screenshots, i),
                child: Container(
                  width: 290,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E2340)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(_screenshots[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF141829),
                          child: const Icon(Icons.broken_image_rounded,
                              color: Color(0xFF334155), size: 32))),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showFullScreenImage(
      BuildContext context, List<String> images, int initial) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text('${initial + 1} / ${images.length}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
            centerTitle: true,
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initial),
            itemCount: images.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: Image.network(images[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                        color: Color(0xFF334155),
                        size: 64)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Series
  Widget _buildSeriesGames() {
    if (_loadingSeries || _seriesGames.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('DE LA MISMA SAGA'),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _seriesGames.length,
            itemBuilder: (_, i) {
              final sg = _seriesGames[i];
              return GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => DetailPage(game: sg))),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141829),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E2340)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            sg.isMatureContent
                                ? const MatureOverlay(
                                    width: double.infinity,
                                    height: double.infinity)
                                : sg.backgroundImage.isNotEmpty
                                    ? Image.network(sg.backgroundImage,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                                color:
                                                    const Color(0xFF1E2340)))
                                    : Container(
                                        color: const Color(0xFF1E2340)),
                            // Gradient
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
                                    stops: const [0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sg.name,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFF1F5F9),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFBBF24), size: 11),
                              const SizedBox(width: 3),
                              Text('${sg.rating}',
                                  style: const TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Section label
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(text,
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          )),
    );
  }

  // Platform chip
  Widget _platformChip(String slug, String name) {
    final icons = {
      'pc': Icons.computer_rounded,
      'playstation4': Icons.sports_esports_rounded,
      'playstation5': Icons.sports_esports_rounded,
      'xbox-one': Icons.sports_esports_rounded,
      'xbox-series-x': Icons.sports_esports_rounded,
      'nintendo-switch': Icons.videogame_asset_rounded,
      'ios': Icons.phone_iphone_rounded,
      'android': Icons.phone_android_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141829),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E2340)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons[slug] ?? Icons.devices_rounded,
              color: const Color(0xFF94A3B8), size: 14),
          const SizedBox(width: 6),
          Text(name,
              style: const TextStyle(
                  color: Color(0xFF94A3B8), fontSize: 11)),
        ],
      ),
    );
  }
}
