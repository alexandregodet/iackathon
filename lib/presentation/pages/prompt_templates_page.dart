import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../data/datasources/database.dart';
import '../../data/datasources/prompt_template_service.dart';

class PromptTemplatesPage extends StatefulWidget {
  const PromptTemplatesPage({super.key});

  @override
  State<PromptTemplatesPage> createState() => _PromptTemplatesPageState();
}

class _PromptTemplatesPageState extends State<PromptTemplatesPage> {
  final _templateService = getIt<PromptTemplateService>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modeles de prompts'),
      ),
      body: StreamBuilder<List<PromptTemplate>>(
        stream: _templateService.watchAllTemplates(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun modele de prompt',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Creez des modeles pour reutiliser vos prompts',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _buildTemplateCard(context, template);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, PromptTemplate template) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEditDialog(context, template),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (template.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        template.category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.delete, color: colorScheme.error),
                    onPressed: () => _confirmDelete(context, template),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                template.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    PromptTemplate? template,
  ) async {
    final isEditing = template != null;
    final nameController = TextEditingController(text: template?.name ?? '');
    final contentController =
        TextEditingController(text: template?.content ?? '');
    final categoryController =
        TextEditingController(text: template?.category ?? '');
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifier le modele' : 'Nouveau modele'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  hintText: 'Ex: Resume de texte',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Categorie (optionnel)',
                  hintText: 'Ex: Redaction, Analyse',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Contenu du prompt',
                  hintText: 'Ecrivez votre modele de prompt...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isEditing ? 'Enregistrer' : 'Creer'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final name = nameController.text.trim();
      final content = contentController.text.trim();
      final category = categoryController.text.trim();

      if (name.isEmpty || content.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Le nom et le contenu sont requis')),
        );
        return;
      }

      if (isEditing) {
        await _templateService.updateTemplate(
          id: template.id,
          name: name,
          content: content,
          category: category.isEmpty ? null : category,
        );
      } else {
        await _templateService.createTemplate(
          name: name,
          content: content,
          category: category.isEmpty ? null : category,
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PromptTemplate template,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le modele'),
        content: Text('Voulez-vous vraiment supprimer "${template.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _templateService.deleteTemplate(template.id);
    }
  }
}

class PromptTemplatePicker extends StatelessWidget {
  final Function(String content) onSelected;

  const PromptTemplatePicker({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final templateService = getIt<PromptTemplateService>();
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.description, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Modeles de prompts',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PromptTemplatesPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Gerer'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<PromptTemplate>>(
                  stream: templateService.watchAllTemplates(),
                  builder: (context, snapshot) {
                    final templates = snapshot.data ?? [];

                    if (templates.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 48,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun modele disponible',
                              style: TextStyle(color: colorScheme.outline),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PromptTemplatesPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Creer un modele'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              Icons.description,
                              color: colorScheme.primary,
                            ),
                            title: Text(template.name),
                            subtitle: template.category != null
                                ? Text(template.category!)
                                : null,
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              onSelected(template.content);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
