import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sollu/presentation/providers/providers.dart';
import 'lyrics_view_screen.dart';
import 'search_screen.dart';
import 'saved_lyrics_screen.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    LyricsViewScreen(),
    SearchScreen(),
    SavedLyricsScreen(),
    SettingsScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    // Activate the listener that pushes lyrics to the native overlay
    ref.read(overlayLyricsPusherProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.music_note), label: 'Now Playing'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.save), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}