import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/local_store.dart';
import 'core/theme/app_theme.dart';
import 'features/add_song/add_song_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/search/songs_list_screen.dart';
import 'features/setlists/setlists_screen.dart';

void main() {
  runApp(const ProviderScope(child: ChordPlaneApp()));
}

class ChordPlaneApp extends StatefulWidget {
  const ChordPlaneApp({super.key});

  @override
  State<ChordPlaneApp> createState() => _ChordPlaneAppState();
}

class _ChordPlaneAppState extends State<ChordPlaneApp> {
  static const _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;
  LocalStore? _store;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadStore();
  }

  Future<void> _loadStore() async {
    final store = await LocalStore.load();
    if (mounted) setState(() => _store = store);
  }

  Future<void> _loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final savedThemeMode = preferences.getString(_themeModeKey);
    if (!mounted || savedThemeMode == null) return;

    setState(() {
      _themeMode = savedThemeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _setDarkMode(bool isDark) async {
    final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    setState(() {
      _themeMode = themeMode;
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, isDark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return MaterialApp(
      title: 'ChordPlane',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: store == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : MainNavigationShell(store: store, onDarkModeChanged: _setDarkMode),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({
    required this.store,
    required this.onDarkModeChanged,
    super.key,
  });

  final LocalStore store;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      SongsListScreen(store: widget.store),
      FavoritesScreen(store: widget.store),
      AddSongScreen(
        store: widget.store,
        onSaved: () => setState(() => _selectedIndex = 0),
      ),
      SetlistsScreen(store: widget.store),
      ProfileScreen(onDarkModeChanged: widget.onDarkModeChanged),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Songs list',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Setlists',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
