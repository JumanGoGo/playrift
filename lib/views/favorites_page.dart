import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05000A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05000A),
        title: const Text('Favoritos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: const Center(
        child: Text('Próximamente...',
          style: TextStyle(color: Colors.white38)),
      ),
    );
  }
}