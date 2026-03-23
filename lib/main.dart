import 'package:flutter/material.dart';
import 'views/home_page.dart';

void main() {
  runApp(const PlayRiftApp());
}

class PlayRiftApp extends StatelessWidget {
  const PlayRiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlayRift',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF107C10), // Verde Xbox
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: 'Arial',
      ),
      home: const HomePage(),
    );
  }
}