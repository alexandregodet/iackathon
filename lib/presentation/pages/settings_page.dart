import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../data/datasources/gemma_service.dart';
import '../../data/datasources/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsService = getIt<SettingsService>();
  final _gemmaService = getIt<GemmaService>();

  late int _maxTokens;
  late double _temperature;
  late int _themeMode;
  late TextEditingController _systemPromptController;

  @override
  void initState() {
    super.initState();
    _maxTokens = _settingsService.maxTokens;
    _temperature = _settingsService.temperature;
    _themeMode = _settingsService.themeMode;
    _systemPromptController = TextEditingController(
      text: _settingsService.systemPrompt ?? '',
    );
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    await _settingsService.setMaxTokens(_maxTokens);
    await _settingsService.setTemperature(_temperature);

    final systemPrompt = _systemPromptController.text.trim();
    await _settingsService.setSystemPrompt(
      systemPrompt.isEmpty ? null : systemPrompt,
    );

    _gemmaService.setSystemPrompt(systemPrompt.isEmpty ? null : systemPrompt);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parametres enregistres'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parametres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionHeader(context, 'Apparence', Icons.palette),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Choisissez le theme de l\'application',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        icon: Icon(Icons.brightness_auto),
                        label: Text('Auto'),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: Icon(Icons.light_mode),
                        label: Text('Clair'),
                      ),
                      ButtonSegment(
                        value: 2,
                        icon: Icon(Icons.dark_mode),
                        label: Text('Sombre'),
                      ),
                    ],
                    selected: {_themeMode},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _themeMode = selection.first;
                      });
                      // Apply theme immediately
                      _settingsService.setThemeMode(_themeMode);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Model Parameters Section
          _buildSectionHeader(context, 'Parametres du modele', Icons.tune),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Max Tokens
                  Text(
                    'Tokens maximum: $_maxTokens',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nombre maximum de tokens dans la reponse',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                  ),
                  Slider(
                    value: _maxTokens.toDouble(),
                    min: 256,
                    max: 4096,
                    divisions: 15,
                    label: _maxTokens.toString(),
                    onChanged: (value) {
                      setState(() {
                        _maxTokens = value.round();
                      });
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Temperature
                  Text(
                    'Temperature: ${_temperature.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Controle la creativite des reponses (0 = deterministe, 1 = creatif)',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                  ),
                  Slider(
                    value: _temperature,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    label: _temperature.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() {
                        _temperature = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // System Prompt Section
          _buildSectionHeader(
            context,
            'Instructions systeme',
            Icons.settings_suggest,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Definissez le comportement par defaut de l\'assistant',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _systemPromptController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText:
                          'Ex: Tu es un assistant utile. Reponds toujours en francais...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _systemPromptController.clear();
                        },
                        child: const Text('Effacer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader(context, 'A propos', Icons.info_outline),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'IAckathon',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Assistant IA local propulse par Gemma',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          FilledButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer les parametres'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
