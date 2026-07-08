import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoRefresh = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _autoRefresh = prefs.getBool('auto_refresh') ?? true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SwitchListTile(
        title: const Text('Auto-refresh lyrics'),
        value: _autoRefresh,
        onChanged: (value) async {
          setState(() => _autoRefresh = value);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('auto_refresh', value);
        },
      ),
    );
  }
}