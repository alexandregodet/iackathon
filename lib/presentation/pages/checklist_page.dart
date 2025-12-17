import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/checklist.dart';
import '../blocs/checklist/checklist_bloc.dart';
import '../blocs/checklist/checklist_event.dart';
import '../blocs/checklist/checklist_state.dart';
import '../widgets/checklist/question_card.dart';
import '../widgets/checklist/section_header.dart';
import 'checklist_history_page.dart';

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
              // Royal seal for success
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.forestColor,
                      AppTheme.forestColor.withValues(alpha: 0.8),
                    ],
                  ),
                  border: Border.all(color: AppTheme.goldColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '\u2714', // Checkmark
                    style: TextStyle(
                      fontSize: 24,
                      color: AppTheme.goldColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quete Accomplie!',
                      style: GoogleFonts.cinzel(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Destrier: ${state.serialNumber}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
                      color: AppTheme.forestColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppTheme.forestColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.save_alt, color: AppTheme.forestColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Les parchemins ont ete archives dans les grimoires du royaume',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppTheme.forestColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Responses summary
                  Row(
                    children: [
                      Text(
                        '\u2726 ',
                        style: TextStyle(color: AppTheme.goldColor),
                      ),
                      Text(
                        'Compte-Rendu (${responseSummaries.length})',
                        style: GoogleFonts.cinzel(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
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
                            color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border(
                              left: BorderSide(
                                color: colorScheme.primary,
                                width: 3,
                              ),
                            ),
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
                                      child: Text(
                                        '\u2728',
                                        style: TextStyle(fontSize: 12, color: AppTheme.goldColor),
                                      ),
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
                      Text(
                        '\u269C ',
                        style: TextStyle(color: AppTheme.goldColor),
                      ),
                      Text(
                        'Sceaux Magiques (${editableTags.length})',
                        style: GoogleFonts.cinzel(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Touchez un sceau pour le retirer',
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
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: editableTag.isAiGenerated
                                    ? AppTheme.goldColor.withValues(alpha: 0.5)
                                    : colorScheme.outline,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (editableTag.isAiGenerated)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      '\u2728',
                                      style: TextStyle(fontSize: 10, color: AppTheme.goldColor),
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
                      'Aucun sceau appose',
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
                            hintText: 'Apposer un nouveau sceau...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
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
              child: const Text('Ignorer'),
            ),
            FilledButton.icon(
              onPressed: () {
                // Save the modified tags
                _saveModifiedTagsWithBloc(bloc, editableTags);
                Navigator.of(dialogContext).pop();
                // Go back to home then navigate to history
                navigator.popUntil((route) => route.isFirst);
                navigator.push(
                  MaterialPageRoute(builder: (_) => const ChecklistHistoryPage()),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Sceller'),
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
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.goldColor, width: 3),
            ),
          ),
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Capturer une Image',
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.camera_alt, color: colorScheme.onPrimaryContainer),
                ),
                title: Text('Invoquer le miroir magique', style: GoogleFonts.crimsonText(fontSize: 16)),
                subtitle: Text('Prendre une photo', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, questionUuid);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.photo_library, color: colorScheme.onSecondaryContainer),
                ),
                title: Text('Consulter les archives', style: GoogleFonts.crimsonText(fontSize: 16)),
                subtitle: Text('Choisir depuis la galerie', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, questionUuid);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<ChecklistBloc, ChecklistState>(
      listenWhen: (previous, current) {
        // Only listen when isSubmitted changes from false to true
        // or when there's a new error
        return (current.isSubmitted && !previous.isSubmitted) ||
            (current.error != null && current.error != previous.error);
      },
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
            title: Text(
              state.checklist?.answers.title ?? 'Checklist',
              overflow: TextOverflow.ellipsis,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Royal seal
              if (state.serialNumber.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.goldColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\u2694 ',
                        style: TextStyle(fontSize: 12, color: AppTheme.goldColor),
                      ),
                      Text(
                        state.serialNumber,
                        style: GoogleFonts.cinzel(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Chargement des parchemins...',
              style: GoogleFonts.crimsonText(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (state.checklist == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.errorContainer,
                border: Border.all(
                  color: Theme.of(context).colorScheme.error,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Parchemin introuvable',
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La quete ne peut etre chargee',
              style: GoogleFonts.crimsonText(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
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
          // Manuscript-style context card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.5),
                  Colors.white.withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(color: colorScheme.outline, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                // Decorative ornament
                Positioned(
                  top: -12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    color: colorScheme.surface,
                    child: Text(
                      '\u2619',
                      style: TextStyle(fontSize: 20, color: colorScheme.primary),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Illuminated letter
                      Text(
                        state.checklist?.answers.title.isNotEmpty == true
                            ? state.checklist!.answers.title[0]
                            : 'C',
                        style: GoogleFonts.medievalSharp(
                          fontSize: 56,
                          color: colorScheme.primary,
                          height: 0.9,
                          shadows: [
                            Shadow(
                              color: AppTheme.goldColor.withValues(alpha: 0.5),
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.checklist?.answers.title ?? 'Checklist',
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (state.checklist?.answers.description.isNotEmpty ?? false) ...[
                              const SizedBox(height: 8),
                              Text(
                                state.checklist!.answers.description,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Serial number input - Scroll style
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              border: Border.all(color: colorScheme.outline, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '\u269C ',
                      style: TextStyle(color: AppTheme.goldColor, fontSize: 18),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Numero du Destrier',
                            style: GoogleFonts.cinzel(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Identifiant unique du vehicule',
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
                    labelText: 'Serial Number',
                    prefixIcon: const Icon(Icons.tag),
                  ),
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    context.read<ChecklistBloc>().add(ChecklistUpdateSerialNumber(value));
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '* Requis pour debuter la quete',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.error,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Medieval divider
          _buildMedievalDivider(colorScheme),
          const SizedBox(height: 24),

          // Info section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '\u2726 ',
                      style: TextStyle(color: AppTheme.goldColor),
                    ),
                    Text(
                      'Details de la Quete',
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(context, 'Chapitres', '${state.totalSections}'),
                _buildInfoRow(context, 'Epreuves', '${state.totalQuestionsCount}'),
                _buildInfoRow(context, 'Grimoire', state.checklist?.context.pn ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedievalDivider(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  colorScheme.outline.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '\u269C',
            style: TextStyle(
              fontSize: 20,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.outline.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.crimsonText(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cinzel(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
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
                'Progression de la Quete',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${state.answeredQuestionsCount}/${state.totalQuestionsCount}',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colorScheme.outline),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: state.progressPercent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      AppTheme.goldColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
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
          (index) {
            final isActive = index == state.currentSectionIndex;
            final isCompleted = index < state.currentSectionIndex;

            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? colorScheme.primary
                    : isCompleted
                        ? AppTheme.forestColor
                        : Colors.transparent,
                border: Border.all(
                  color: isActive
                      ? AppTheme.goldColor
                      : colorScheme.outline,
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            );
          },
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
        ),
        border: Border(
          top: BorderSide(color: AppTheme.goldColor, width: 3),
        ),
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onPrimary,
                    side: BorderSide(color: AppTheme.goldColor),
                  ),
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
                  label: Text(state.isOnContextPage ? 'Debuter' : 'Suivant'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.goldColor,
                    foregroundColor: AppTheme.inkColor,
                  ),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.goldColor,
                    foregroundColor: AppTheme.inkColor,
                  ),
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
