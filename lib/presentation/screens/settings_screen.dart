import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sollu/presentation/providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoRefresh = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoRefresh = prefs.getBool('auto_refresh') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabledSources = ref.watch(enabledSourcesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Auto-refresh lyrics'),
            subtitle: const Text('Automatically update lyrics when song changes'),
            value: _autoRefresh,
            onChanged: (value) async {
              setState(() => _autoRefresh = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('auto_refresh', value);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Lyrics Sources',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Generate switches for all sources
          ...enabledSources.keys.map((source) {
            return SwitchListTile(
              title: Text(source),
              value: enabledSources[source] ?? true,
              onChanged: (value) {
                ref.read(enabledSourcesProvider.notifier).toggleSource(source);
                // Force lyrics refresh
                ref.read(lyricsRefreshTriggerProvider.notifier).state++;
              },
            );
          }),
          const Divider(),
          const ListTile(
            title: Text('About'),
            subtitle: Text('Sollu v1.0.0'),
          ),
        ],
      ),
    );
  }
}