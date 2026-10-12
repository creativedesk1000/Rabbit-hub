import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onSettingsChanged});

  final VoidCallback onSettingsChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _farmName = TextEditingController();
  String _unit = 'kg';
  String _dateFormat = 'MMM d, yyyy';
  String _theme = 'Light';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _farmName.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await AppDatabase.instance.settings();
    if (!mounted) return;
    setState(() {
      _farmName.text = settings['farm_name'] ?? '';
      _unit = settings['weight_unit'] ?? 'kg';
      _dateFormat = settings['date_format'] ?? 'MMM d, yyyy';
      _theme = settings['theme'] ?? 'Light';
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AppDatabase.instance.setSettings({
      'farm_name': _farmName.text.trim().isEmpty
          ? 'Rabbit Hub'
          : _farmName.text.trim(),
      'weight_unit': _unit,
      'date_format': _dateFormat,
      'theme': _theme,
    });
    themeModeNotifier.value = switch (_theme) {
      'Dark' => ThemeMode.dark,
      'System' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    widget.onSettingsChanged();
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text('Rabbitry', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(
                controller: _farmName,
                decoration: const InputDecoration(
                  labelText: 'Farm / rabbitry name',
                  prefixIcon: Icon(Icons.home_work_outlined),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _unit,
                decoration: const InputDecoration(
                  labelText: 'Default weight unit',
                ),
                items: const ['kg', 'g', 'lb']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _unit = value!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _dateFormat,
                decoration: const InputDecoration(labelText: 'Date format'),
                items: const [
                  DropdownMenuItem(
                    value: 'MMM d, yyyy',
                    child: Text('Oct 11, 2026'),
                  ),
                  DropdownMenuItem(
                    value: 'dd/MM/yyyy',
                    child: Text('11/10/2026'),
                  ),
                  DropdownMenuItem(
                    value: 'yyyy-MM-dd',
                    child: Text('2026-10-11'),
                  ),
                ],
                onChanged: (value) => setState(() => _dateFormat = value!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _theme,
                decoration: const InputDecoration(labelText: 'Appearance'),
                items: const ['Light', 'Dark', 'System']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _theme = value!),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save settings'),
              ),
              const SizedBox(height: 28),
              Text(
                'Data & privacy',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Local backup'),
                  subtitle: const Text(
                    'Backup and restore will be available in a later part.',
                  ),
                  trailing: const Icon(Icons.lock_clock_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About Rabbit Hub'),
                  subtitle: const Text('Part 1 · Local rabbit profiles'),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Rabbit Hub',
                    applicationVersion: 'Part 1',
                    applicationLegalese:
                        'Rabbit records are stored locally on this device.',
                  ),
                ),
              ),
            ],
          ),
  );
}
