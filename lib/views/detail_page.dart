import 'package:flutter/material.dart';
import '../models/game_model.dart';

class DetailPage extends StatelessWidget {
  final Game game;
  const DetailPage({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05000A),
      body: CustomScrollView(
        slivers: [

          // ── Hero image con AppBar flotante ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF05000A),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen de portada
                  Hero(
                    tag: 'game-${game.id}',
                    child:
                    game.backgroundImage.isNotEmpty
                      ? Image.network(
                          game.backgroundImage,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[900],
                            child: const Icon(Icons.videogame_asset,
                                color: Colors.white24, size: 64)),
                        )
                      : Container(color: Colors.grey[900]),
                  ), 

                  // Gradiente para legibilidad
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF05000A).withOpacity(0.95),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenido ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Nombre del juego
                Text(
                  game.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Fila de métricas ──
                Row(
                  children: [
                    _metricBadge(
                      icon: Icons.star,
                      label: game.rating.toString(),
                      color: const Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 12),
                    if (game.metacritic > 0)
                      _metricBadge(
                        icon: Icons.bar_chart,
                        label: 'MC ${game.metacritic}',
                        color: game.metacritic >= 80
                            ? Colors.green
                            : game.metacritic >= 60
                                ? Colors.orange
                                : Colors.red,
                      ),
                    const SizedBox(width: 12),
                    if (game.playtime > 0)
                      _metricBadge(
                        icon: Icons.timer_outlined,
                        label: '${game.playtime}h promedio',
                        color: Colors.blueGrey,
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Géneros ──
                if (game.genres.isNotEmpty) ...[
                  _sectionLabel('GÉNEROS'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: game.genres.map((g) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFB200FF), width: 1),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB200FF).withOpacity(0.3),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: Text(g.name,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                ],


                if (game.platforms.isNotEmpty) ...[
                      _sectionLabel('PLATAFORMAS'),
                      const SizedBox(height: 10),
                      Wrap(
                        children: game.platforms
                            .map((p) => _platformIcon(p.slug))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],


                // ── Fecha de lanzamiento ──
                if (game.released.isNotEmpty) ...[
                  _sectionLabel('LANZAMIENTO'),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white38, size: 16),
                    const SizedBox(width: 8),
                    Text(game.released,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 15)),
                  ]),
                  const SizedBox(height: 24),
                ],

                // ── Información adicional ──
                _sectionLabel('INFORMACIÓN'),
                const SizedBox(height: 12),
                _infoRow('Rating', '${game.rating} / 5.0'),
                _infoRow('Metacritic',
                    game.metacritic > 0 ? '${game.metacritic} / 100' : 'N/A'),
                _infoRow('Tiempo promedio',
                    game.playtime > 0 ? '${game.playtime} horas' : 'N/A'),
                _infoRow('Géneros',
                    game.genres.map((g) => g.name).join(', ')),

              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Text(label,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ));
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
        ],
      ),
    );
  }
  Widget _platformIcon(String slug) {
  final icons = {
    'pc':            Icons.computer,
    'playstation4':  Icons.sports_esports,
    'playstation5':  Icons.sports_esports,
    'xbox-one':      Icons.sports_esports,
    'xbox-series-x': Icons.sports_esports,
    'nintendo-switch': Icons.videogame_asset,
    'ios':           Icons.phone_iphone,
    'android':       Icons.phone_android,
  };

  final colors = {
    'pc':             Colors.blueGrey,
    'playstation4':   const Color(0xFF003791),
    'playstation5':   const Color(0xFF003791),
    'xbox-one':       const Color(0xFF00E5FF),
    'xbox-series-x':  const Color(0xFF00E5FF),
    'nintendo-switch':const Color(0xFFFF007F),
    'ios':            Colors.white70,
    'android':        const Color(0xFF78C257),
  };

  return Container(
    margin: const EdgeInsets.only(right: 8, bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: (colors[slug] ?? Colors.grey).withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: (colors[slug] ?? Colors.grey).withOpacity(0.4)),
      boxShadow: [
        BoxShadow(
          color: (colors[slug] ?? Colors.transparent).withOpacity(0.2),
          blurRadius: 6,
        )
      ],
    ),
    child: Icon(
      icons[slug] ?? Icons.devices,
      color: colors[slug] ?? Colors.white38,
      size: 18,
    ),
  );
}
}