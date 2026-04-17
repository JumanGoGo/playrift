import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/home_page.dart';
import 'views/browse_page.dart';
import 'views/favorites_page.dart';

void main() {
  runApp(const PlayRiftApp());
}

class PlayRiftApp extends StatelessWidget {
  const PlayRiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0E1A),
      ),
    );

    return MaterialApp(
      title: 'PlayRift',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          surface: const Color(0xFF0A0E1A),
          primary: const Color(0xFF8B5CF6),
          secondary: const Color(0xFF06B6D4),
          error: const Color(0xFFEF4444),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        splashColor: const Color(0xFF8B5CF6).withAlpha(25),
        highlightColor: const Color(0xFF8B5CF6).withAlpha(13),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _browseKey = GlobalKey<BrowsePageState>();
  final _favoritesKey = GlobalKey<FavoritesPageState>();

  void _goToBrowseWithGenre(int genreId) {
    setState(() => _currentIndex = 1);
    _browseKey.currentState?.filterByGenre(genreId);
  }

  late final List<Widget> _pages = [
    HomePage(onGenreTap: _goToBrowseWithGenre),
    BrowsePage(key: _browseKey),
    FavoritesPage(key: _favoritesKey),
  ];

  void _onTabTap(int i) {
    setState(() => _currentIndex = i);
    if (i == 2) _favoritesKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      extendBody: true,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A).withAlpha(230),
              border: const Border(
                top: BorderSide(color: Color(0xFF1E2340), width: 0.5),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(0, Icons.home_outlined, Icons.home_rounded,
                        'Inicio'),
                    _navItem(1, Icons.explore_outlined,
                        Icons.explore_rounded, 'Explorar'),
                    _navItem(2, Icons.favorite_outline_rounded,
                        Icons.favorite_rounded, 'Favoritos'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF8B5CF6).withAlpha(20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? const Color(0xFF8B5CF6) : const Color(0xFF475569),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}
