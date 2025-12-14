import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../data/datasources/gemma_service.dart';
import '../../domain/entities/gemma_model_info.dart';
import 'chat_page.dart';

class ModelSelectionPage extends StatefulWidget {
  const ModelSelectionPage({super.key});

  @override
  State<ModelSelectionPage> createState() => _ModelSelectionPageState();
}

class _ModelSelectionPageState extends State<ModelSelectionPage> {
  late final GemmaService _gemmaService;
  late final StreamSubscription<GemmaModelState> _stateSubscription;
  late final StreamSubscription<double> _progressSubscription;

  GemmaModelState _modelState = GemmaModelState.notInstalled;
  double _downloadProgress = 0.0;
  GemmaModelInfo? _currentModel;

  @override
  void initState() {
    super.initState();
    _gemmaService = getIt<GemmaService>();

    // Initialize with current values (no setState needed in initState)
    _modelState = _gemmaService.state;
    _downloadProgress = _gemmaService.downloadProgress;
    _currentModel = _gemmaService.currentModel;

    _stateSubscription = _gemmaService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _modelState = state;
          _currentModel = _gemmaService.currentModel;
        });
      }
    });

    _progressSubscription = _gemmaService.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _downloadProgress = progress;
        });
      }
    });
  }

  void _refreshState() {
    if (mounted) {
      setState(() {
        _modelState = _gemmaService.state;
        _downloadProgress = _gemmaService.downloadProgress;
        _currentModel = _gemmaService.currentModel;
      });
    }
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    _progressSubscription.cancel();
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
            const Text('select_model'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTerminalBlock(
            context,
            colorScheme,
            isDark,
            children: [
              _buildLine(colorScheme, '# Available Models'),
              const SizedBox(height: 4),
              _buildLine(colorScheme, 'type: gemma2/gemma3'),
              _buildLine(colorScheme, 'quantization: int4/int8'),
              _buildLine(colorScheme, 'select: tap to load', isHighlight: true),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, colorScheme, '# MULTIMODAL'),
          const SizedBox(height: 12),
          ...AvailableModels.multimodal.map(
            (model) => _ModelCard(
              model: model,
              isMultimodal: true,
              isDownloading:
                  _modelState == GemmaModelState.downloading &&
                  _currentModel?.filename == model.filename,
              downloadProgress: _downloadProgress,
              onNavigationReturn: _refreshState,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, colorScheme, '# TEXT_ONLY'),
          const SizedBox(height: 12),
          ...AvailableModels.textOnly.map(
            (model) => _ModelCard(
              model: model,
              isMultimodal: false,
              isDownloading:
                  _modelState == GemmaModelState.downloading &&
                  _currentModel?.filename == model.filename,
              downloadProgress: _downloadProgress,
              onNavigationReturn: _refreshState,
            ),
          ),
          const SizedBox(height: 40),
        ],
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

  Widget _buildSectionHeader(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
  ) {
    return Text(
      title,
      style: TextStyle(
        color: colorScheme.tertiary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final GemmaModelInfo model;
  final bool isMultimodal;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback? onNavigationReturn;

  const _ModelCard({
    required this.model,
    required this.isMultimodal,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.onNavigationReturn,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDownloading
              ? colorScheme.tertiary
              : isDark
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
          width: isDownloading ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDownloading ? null : () => _onSelectModel(context),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Text('> ', style: TextStyle(color: colorScheme.primary)),
                    Expanded(
                      child: Text(
                        model.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (model.requiresAuth)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: colorScheme.error.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 10,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AUTH',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  '  ${model.description}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Tags row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildTag(
                      context,
                      'size: ${model.sizeLabel}',
                      colorScheme.onSurfaceVariant,
                      colorScheme,
                    ),
                    if (isMultimodal)
                      _buildTag(
                        context,
                        'vision: true',
                        colorScheme.tertiary,
                        colorScheme,
                      ),
                    if (model.supportsThinking)
                      _buildTag(
                        context,
                        'thinking: true',
                        colorScheme.primary,
                        colorScheme,
                      ),
                  ],
                ),
                // Download progress
                if (isDownloading) ...[
                  const SizedBox(height: 14),
                  _buildDownloadProgress(context, colorScheme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadProgress(BuildContext context, ColorScheme colorScheme) {
    final percentage = (downloadProgress * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'downloading: $percentage%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: downloadProgress,
            minHeight: 4,
            backgroundColor: colorScheme.tertiary.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.tertiary),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(
    BuildContext context,
    String text,
    Color textColor,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  void _onSelectModel(BuildContext context) {
    if (model.requiresAuth) {
      _showTokenDialog(context);
    } else {
      _navigateToChat(context);
    }
  }

  void _showTokenDialog(BuildContext context) {
    final controller = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text('> ', style: TextStyle(color: colorScheme.primary)),
            const Expanded(child: Text('auth_required')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '# HuggingFace token required for download',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'token',
                hintText: 'hf_...',
                prefixIcon: Icon(Icons.vpn_key),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToChat(context, token: controller.text);
            },
            child: const Text('> continue'),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(BuildContext context, {String? token}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ChatPage(modelInfo: model, huggingFaceToken: token),
          ),
        )
        .then((_) {
          // Refresh state when returning from ChatPage
          onNavigationReturn?.call();
        });
  }
}
