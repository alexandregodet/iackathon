import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di/injection.dart';
import '../../domain/entities/checklist.dart';
import '../blocs/checklist/checklist_bloc.dart';
import '../blocs/checklist/checklist_event.dart';
import '../blocs/checklist/checklist_state.dart';
import '../widgets/checklist/question_card.dart';
import '../widgets/checklist/section_header.dart';

class ChecklistPage extends StatelessWidget {
  final String assetPath;

  const ChecklistPage({
    super.key,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChecklistBloc>()..add(ChecklistLoadFromAsset(assetPath)),
      child: const _ChecklistPageContent(),
    );
  }
}

class _ChecklistPageContent extends StatefulWidget {
  const _ChecklistPageContent();

  @override
  State<_ChecklistPageContent> createState() => _ChecklistPageContentState();
}

class _ChecklistPageContentState extends State<_ChecklistPageContent> {
  late PageController _pageController;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, String questionUuid) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (pickedFile != null && mounted) {
      context.read<ChecklistBloc>().add(ChecklistAddAttachment(
            questionUuid: questionUuid,
            file: pickedFile,
          ));
    }
  }

  void _showCompletionSummaryDialog(BuildContext context, ChecklistState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tagController = TextEditingController();
    // Capture navigator and bloc before showing dialog to avoid context issues
    final navigator = Navigator.of(context);
    final bloc = context.read<ChecklistBloc>();

    // Collect all AI tags from responses (mutable list for editing)
    final editableTags = <_EditableTag>[];
    for (final response in state.responses.values) {
      if (response.aiTags != null) {
        for (final tagData in response.aiTags!) {
          final tag = tagData['tag'] as String?;
          if (tag != null && tag.isNotEmpty) {
            // Avoid duplicates
            if (!editableTags.any((t) => t.tag == tag)) {
              editableTags.add(_EditableTag(tag: tag, isAiGenerated: true));
            }
          }
        }
      }
    }

    // Build summary of responses
    final responseSummaries = <_ResponseSummary>[];
    if (state.checklist != null) {
      for (final section in state.checklist!.answers.sections) {
        for (final question in section.questions) {
          final response = state.responses[question.uuid];
          if (response != null && response.response != null && response.response!.isNotEmpty) {
            responseSummaries.add(_ResponseSummary(
              sectionTitle: section.title,
              questionTitle: question.title,
              response: response.response!,
              hasAttachment: response.attachmentPaths.isNotEmpty,
              hasAiAnalysis: response.aiTags != null && response.aiTags!.isNotEmpty,
            ));
          }
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checklist terminee',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'SN: ${state.serialNumber}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.save, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Donnees enregistrees en base de donnees',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Responses summary
                  Text(
                    'Resume des reponses (${responseSummaries.length})',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: responseSummaries.length,
                      itemBuilder: (context, index) {
                        final summary = responseSummaries[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      summary.questionTitle,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (summary.hasAttachment)
                                    Icon(Icons.attach_file, size: 14, color: colorScheme.onSurfaceVariant),
                                  if (summary.hasAiAnalysis)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(Icons.auto_awesome, size: 14, color: colorScheme.secondary),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                summary.response,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Tags section (editable)
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.label, size: 18, color: colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Tags (${editableTags.length})',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Appuyez sur un tag pour le supprimer',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Display tags with delete capability
                  if (editableTags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: editableTags.map((editableTag) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              editableTags.remove(editableTag);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: editableTag.isAiGenerated
                                  ? colorScheme.secondaryContainer
                                  : colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (editableTag.isAiGenerated)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.auto_awesome,
                                      size: 12,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                Text(
                                  editableTag.tag,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: editableTag.isAiGenerated
                                        ? colorScheme.onSecondaryContainer
                                        : colorScheme.onTertiaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.close,
                                  size: 14,
                                  color: editableTag.isAiGenerated
                                      ? colorScheme.onSecondaryContainer
                                      : colorScheme.onTertiaryContainer,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Text(
                      'Aucun tag',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  // Add new tag input
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tagController,
                          decoration: InputDecoration(
                            hintText: 'Ajouter un tag...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            prefixIcon: const Icon(Icons.add, size: 20),
                          ),
                          onSubmitted: (value) {
                            final trimmed = value.trim();
                            if (trimmed.isNotEmpty && !editableTags.any((t) => t.tag == trimmed)) {
                              setDialogState(() {
                                editableTags.add(_EditableTag(tag: trimmed, isAiGenerated: false));
                                tagController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          final trimmed = tagController.text.trim();
                          if (trimmed.isNotEmpty && !editableTags.any((t) => t.tag == trimmed)) {
                            setDialogState(() {
                              editableTags.add(_EditableTag(tag: trimmed, isAiGenerated: false));
                              tagController.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                navigator.popUntil((route) => route.isFirst);
              },
              child: const Text('Ignorer les modifications'),
            ),
            FilledButton.icon(
              onPressed: () {
                // Save the modified tags
                _saveModifiedTagsWithBloc(bloc, editableTags);
                Navigator.of(dialogContext).pop();
                navigator.popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveModifiedTagsWithBloc(
    ChecklistBloc bloc,
    List<_EditableTag> editableTags,
  ) {
    // Convert editable tags to the format expected by the database
    final tagsData = editableTags.map((t) => {
      'tag': t.tag,
      'type': t.isAiGenerated ? 'ia' : 'manuel',
      'bbox': null,
    }).toList();

    bloc.add(ChecklistUpdateTags(tags: tagsData));
  }

  void _showImageSourceDialog(String questionUuid) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, questionUuid);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, questionUuid);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<ChecklistBloc, ChecklistState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: colorScheme.error,
            ),
          );
        }
        if (state.isSubmitted) {
          _showCompletionSummaryDialog(context, state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text('> ', style: TextStyle(color: colorScheme.primary)),
                Expanded(
                  child: Text(
                    state.checklist?.answers.title ?? 'Checklist',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (state.isSaving)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: _buildBody(context, state),
          bottomNavigationBar: state.checklist != null
              ? _buildBottomNavigation(context, state)
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ChecklistState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.checklist == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            const Text('Impossible de charger la checklist'),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (!state.isOnContextPage) _buildProgressIndicator(context, state),
        _buildSectionDots(context, state),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: state.totalPages,
            onPageChanged: (index) {
              context.read<ChecklistBloc>().add(ChecklistGoToSection(index));
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildContextPage(context, state);
              }
              final sectionIndex = index - 1;
              final section = state.checklist!.answers.sections[sectionIndex];
              return _buildSectionPage(context, section, state, sectionIndex, state.totalSections);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContextPage(BuildContext context, ChecklistState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.checklist?.answers.title ?? 'Checklist',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.checklist?.answers.description.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.checklist!.answers.description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.qr_code,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Numero de serie (SN)',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Identifiant unique du vehicule GRIFFON-FELIN',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Ex: 62030010',
                    labelText: 'Serial Number *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.tag),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                  onChanged: (value) {
                    context.read<ChecklistBloc>().add(ChecklistUpdateSerialNumber(value));
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '* Champ obligatoire pour demarrer la checklist',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.error,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(context, 'Sections', '${state.totalSections}'),
                _buildInfoRow(context, 'Questions', '${state.totalQuestionsCount}'),
                _buildInfoRow(context, 'Part Number', state.checklist?.context.pn ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.primary)),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, ChecklistState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Text(
                '${state.answeredQuestionsCount}/${state.totalQuestionsCount}',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: state.progressPercent,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDots(BuildContext context, ChecklistState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          state.totalPages,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == state.currentSectionIndex
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionPage(
    BuildContext context,
    ChecklistSection section,
    ChecklistState state,
    int sectionIndex,
    int totalSections,
  ) {
    final responses = state.responses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            section: section,
            sectionNumber: sectionIndex + 1,
            totalSections: totalSections,
          ),
          const SizedBox(height: 16),
          ...section.questions.map((question) {
            final response = responses[question.uuid];
            final isAnalyzing =
                state.analyzingQuestions.contains(question.uuid);
            final aiResult = state.aiAnalysisResults[question.uuid];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: QuestionCard(
                question: question,
                response: response,
                sectionTitle: section.title,
                sectionDescription: section.description,
                onResponseChanged: (value) {
                  context.read<ChecklistBloc>().add(ChecklistUpdateResponse(
                        questionUuid: question.uuid,
                        response: value,
                      ));
                },
                onCommentChanged: (value) {
                  context.read<ChecklistBloc>().add(ChecklistUpdateComment(
                        questionUuid: question.uuid,
                        comment: value,
                      ));
                },
                onAddAttachment: () => _showImageSourceDialog(question.uuid),
                onRemoveAttachment: (filePath) {
                  context.read<ChecklistBloc>().add(ChecklistRemoveAttachment(
                        questionUuid: question.uuid,
                        filePath: filePath,
                      ));
                },
                isAnalyzing: isAnalyzing,
                aiAnalysisResult: aiResult,
                onAnalyzeWithAI: () {
                  if (response != null &&
                      response.attachmentPaths.isNotEmpty) {
                    context.read<ChecklistBloc>().add(ChecklistAnalyzeWithAI(
                          questionUuid: question.uuid,
                          sectionTitle: section.title,
                          sectionDescription: section.description,
                          questionTitle: question.title,
                          questionHint: question.hint,
                          answer: response.response ?? '',
                          imagePath: response.attachmentPaths.first,
                        ));
                  }
                },
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, ChecklistState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (state.canGoPrevious)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Precedent'),
                ),
              )
            else
              const Expanded(child: SizedBox()),
            const SizedBox(width: 16),
            if (state.canGoNext)
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.isOnContextPage && !state.canStartChecklist
                      ? null
                      : () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                  icon: Icon(state.isOnContextPage ? Icons.play_arrow : Icons.arrow_forward),
                  label: Text(state.isOnContextPage ? 'Demarrer' : 'Suivant'),
                ),
              )
            else
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<ChecklistBloc>().add(const ChecklistSubmit());
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Terminer'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResponseSummary {
  final String sectionTitle;
  final String questionTitle;
  final String response;
  final bool hasAttachment;
  final bool hasAiAnalysis;

  const _ResponseSummary({
    required this.sectionTitle,
    required this.questionTitle,
    required this.response,
    required this.hasAttachment,
    required this.hasAiAnalysis,
  });
}

class _EditableTag {
  final String tag;
  final bool isAiGenerated;

  const _EditableTag({
    required this.tag,
    required this.isAiGenerated,
  });
}
