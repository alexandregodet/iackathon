import 'dart:async';

import 'package:flutter/material.dart';

import 'model_selection_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showCursor = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    // Blinking cursor effect with cancelable timer
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) {
        setState(() => _showCursor = !_showCursor);
      }
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('> ', style: TextStyle(color: colorScheme.primary)),
            const Text('IAckathon'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
            tooltip: 'config',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Terminal header
            _buildTerminalBlock(
              context,
              colorScheme,
              isDark,
              children: [
                _buildLine(colorScheme, '# IAckathon - Local AI Assistant'),
                const SizedBox(height: 8),
                _buildLine(colorScheme, 'version: 1.0.0'),
                _buildLine(colorScheme, 'runtime: flutter_gemma'),
                _buildLine(colorScheme, 'status: ready', isHighlight: true),
              ],
            ),
            const SizedBox(height: 20),

            // Features
            _buildTerminalBlock(
              context,
              colorScheme,
              isDark,
              children: [
                _buildLine(colorScheme, '# Features'),
                const SizedBox(height: 8),
                _buildFeatureLine(colorScheme, 'local', 'On-device inference'),
                _buildFeatureLine(
                  colorScheme,
                  'offline',
                  'No network required',
                ),
                _buildFeatureLine(
                  colorScheme,
                  'multimodal',
                  'Text + Image support',
                ),
                _buildFeatureLine(
                  colorScheme,
                  'thinking',
                  'DeepSeek reasoning',
                ),
                _buildFeatureLine(colorScheme, 'rag', 'PDF document context'),
              ],
            ),
            const SizedBox(height: 20),

            // System info
            _buildTerminalBlock(
              context,
              colorScheme,
              isDark,
              children: [
                _buildLine(colorScheme, '# System'),
                const SizedBox(height: 8),
                _buildLine(colorScheme, 'engine: Gemma 2/3'),
                _buildLine(colorScheme, 'quantization: int4/int8'),
                _buildLine(colorScheme, 'context: 8192 tokens'),
              ],
            ),
            const SizedBox(height: 32),

            // Command prompt
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: colorScheme.primary.withValues(
                    alpha: isDark ? 0.5 : 0.3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '\$ ',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'start --model=gemma',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                  Text(
                    _showCursor ? '_' : ' ',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Start button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ModelSelectionPage()),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('> ', style: TextStyle(color: colorScheme.onPrimary)),
                    const Text('SELECT_MODEL'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalBlock(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark, {
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLine(
    ColorScheme colorScheme,
    String text, {
    bool isHighlight = false,
  }) {
    return Text(
      text,
      style: TextStyle(
        color: isHighlight ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildFeatureLine(ColorScheme colorScheme, String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('  - ', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          Text(
            key,
            style: TextStyle(
              color: colorScheme.tertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(': ', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
