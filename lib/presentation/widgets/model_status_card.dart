import 'package:flutter/material.dart';

import '../blocs/chat/chat_state.dart';
import '../../data/datasources/gemma_service.dart';

class ModelStatusCard extends StatelessWidget {
  final ChatState state;
  final VoidCallback onDownload;
  final VoidCallback onLoad;

  const ModelStatusCard({
    super.key,
    required this.state,
    required this.onDownload,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(context),
                const SizedBox(height: 24),
                _buildTitle(context),
                const SizedBox(height: 8),
                _buildSubtitle(context),
                const SizedBox(height: 24),
                _buildAction(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    IconData icon;
    Color color;

    switch (state.modelState) {
      case GemmaModelState.notInstalled:
        icon = Icons.download;
        color = colorScheme.primary;
      case GemmaModelState.downloading:
        icon = Icons.downloading;
        color = colorScheme.tertiary;
      case GemmaModelState.installed:
        icon = Icons.check_circle;
        color = colorScheme.secondary;
      case GemmaModelState.loading:
        icon = Icons.memory;
        color = colorScheme.tertiary;
      case GemmaModelState.error:
        icon = Icons.error;
        color = colorScheme.error;
      default:
        icon = Icons.psychology;
        color = colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 48, color: color),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final modelName = state.selectedModel?.name ?? 'Modele';
    String title;

    switch (state.modelState) {
      case GemmaModelState.notInstalled:
        title = 'Modele non installe';
      case GemmaModelState.downloading:
        title = 'Telechargement en cours...';
      case GemmaModelState.installed:
        title = '$modelName installe';
      case GemmaModelState.loading:
        title = 'Chargement de $modelName...';
      case GemmaModelState.error:
        title = 'Erreur';
      default:
        title = modelName;
    }

    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final model = state.selectedModel;
    String subtitle;

    switch (state.modelState) {
      case GemmaModelState.notInstalled:
        subtitle = model != null
            ? 'Telechargez ${model.name}\n(~${model.sizeLabel})'
            : 'Telechargez le modele pour commencer';
      case GemmaModelState.downloading:
        subtitle = '${(state.downloadProgress * 100).toStringAsFixed(1)}%';
      case GemmaModelState.installed:
        subtitle = 'Chargez le modele en memoire pour discuter';
      case GemmaModelState.loading:
        subtitle = 'Preparation du modele...';
      case GemmaModelState.error:
        subtitle = state.error ?? 'Une erreur est survenue';
      default:
        subtitle = '';
    }

    return Column(
      children: [
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        if (model != null && state.modelState == GemmaModelState.notInstalled) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (model.isMultimodal)
                _buildChip(context, 'Vision', Icons.visibility, isHighlighted: true),
              if (model.requiresAuth)
                _buildChip(context, 'Auth requise', Icons.lock),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label,
    IconData icon, {
    bool isHighlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme.tertiaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isHighlighted
                ? colorScheme.onTertiaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isHighlighted
                      ? colorScheme.onTertiaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    switch (state.modelState) {
      case GemmaModelState.notInstalled:
        return FilledButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.download),
          label: const Text('Telecharger'),
        );
      case GemmaModelState.downloading:
        return Column(
          children: [
            LinearProgressIndicator(
              value: state.downloadProgress,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Text(
              'Telechargement...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      case GemmaModelState.installed:
        return FilledButton.icon(
          onPressed: onLoad,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Charger le modele'),
        );
      case GemmaModelState.loading:
        return const CircularProgressIndicator();
      case GemmaModelState.error:
        return FilledButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.refresh),
          label: const Text('Reessayer'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
