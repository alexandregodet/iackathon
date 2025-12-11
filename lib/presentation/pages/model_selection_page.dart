import 'package:flutter/material.dart';

import '../../domain/entities/gemma_model_info.dart';
import 'chat_page.dart';

class ModelSelectionPage extends StatelessWidget {
  const ModelSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un modele'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Modeles multimodaux', Icons.image),
          const SizedBox(height: 8),
          ...AvailableModels.multimodal.map(
            (model) => _ModelCard(model: model),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Modeles texte', Icons.text_fields),
          const SizedBox(height: 8),
          ...AvailableModels.textOnly.map(
            (model) => _ModelCard(model: model),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _ModelCard extends StatelessWidget {
  final GemmaModelInfo model;

  const _ModelCard({required this.model});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _onSelectModel(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: model.isMultimodal
                      ? colorScheme.tertiaryContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  model.isMultimodal ? Icons.image : Icons.text_fields,
                  color: model.isMultimodal
                      ? colorScheme.onTertiaryContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          model.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (model.requiresAuth) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: colorScheme.outline,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      model.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildChip(
                          context,
                          model.sizeLabel,
                          Icons.storage,
                        ),
                        const SizedBox(width: 8),
                        if (model.isMultimodal)
                          _buildChip(
                            context,
                            'Vision',
                            Icons.visibility,
                            isHighlighted: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
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

  void _onSelectModel(BuildContext context) {
    if (model.requiresAuth) {
      _showTokenDialog(context);
    } else {
      _navigateToChat(context);
    }
  }

  void _showTokenDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Token HuggingFace requis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ce modele necessite une authentification HuggingFace.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Token HuggingFace',
                hintText: 'hf_...',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToChat(context, token: controller.text);
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(BuildContext context, {String? token}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          modelInfo: model,
          huggingFaceToken: token,
        ),
      ),
    );
  }
}
