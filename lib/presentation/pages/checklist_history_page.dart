import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/checklist_summary.dart';
import '../blocs/checklist_history/checklist_history_bloc.dart';
import '../blocs/checklist_history/checklist_history_event.dart';
import '../blocs/checklist_history/checklist_history_state.dart';

class ChecklistHistoryPage extends StatelessWidget {
  const ChecklistHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ChecklistHistoryBloc>()..add(const ChecklistHistoryLoad()),
      child: const _ChecklistHistoryContent(),
    );
  }
}

class _ChecklistHistoryContent extends StatefulWidget {
  const _ChecklistHistoryContent();

  @override
  State<_ChecklistHistoryContent> createState() =>
      _ChecklistHistoryContentState();
}

class _ChecklistHistoryContentState extends State<_ChecklistHistoryContent> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedItems = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archives du Royaume'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(context, colorScheme),
          Expanded(
            child: BlocBuilder<ChecklistHistoryBloc, ChecklistHistoryState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Consultation des grimoires...',
                          style: GoogleFonts.crimsonText(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.errorContainer,
                            border: Border.all(
                              color: colorScheme.error,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 40,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.error!,
                          style: GoogleFonts.crimsonText(
                            fontSize: 14,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context
                              .read<ChecklistHistoryBloc>()
                              .add(const ChecklistHistoryLoad()),
                          child: const Text('Reessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final summaries = state.displayedSummaries;

                if (summaries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surfaceContainer,
                            border: Border.all(
                              color: colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              state.hasSearch ? '\u2717' : '\u2617',
                              style: TextStyle(
                                fontSize: 32,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.hasSearch
                              ? 'Aucun parchemin trouve'
                              : 'Les archives sont vides',
                          style: GoogleFonts.cinzel(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.hasSearch
                              ? 'La quete "${state.searchQuery}" ne figure point dans les grimoires'
                              : 'Aucune quete n\'a encore ete accomplie',
                          style: GoogleFonts.crimsonText(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<ChecklistHistoryBloc>()
                        .add(const ChecklistHistoryLoad());
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: summaries.length,
                    itemBuilder: (context, index) {
                      final summary = summaries[index];
                      return _buildChecklistCard(context, summary, colorScheme);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Fouiller les parchemins...',
          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<ChecklistHistoryBloc>()
                        .add(const ChecklistHistoryClearSearch());
                  },
                )
              : null,
        ),
        style: GoogleFonts.crimsonText(fontSize: 15),
        onChanged: (value) {
          context
              .read<ChecklistHistoryBloc>()
              .add(ChecklistHistorySearch(value));
        },
      ),
    );
  }

  Widget _buildChecklistCard(
    BuildContext context,
    ChecklistSummary summary,
    ColorScheme colorScheme,
  ) {
    final isExpanded = _expandedItems.contains(summary.checklistId);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Left accent border
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: colorScheme.primary,
                  width: 4,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedItems.remove(summary.checklistId);
                    } else {
                      _expandedItems.add(summary.checklistId);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          // Royal seal icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primaryContainer,
                              border: Border.all(
                                color: AppTheme.goldColor,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '\u2617',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: colorScheme.onPrimaryContainer,
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
                                  summary.checklistTitle,
                                  style: GoogleFonts.cinzel(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '\u2694 ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      'Destrier: ${summary.serialNumber}',
                                      style: GoogleFonts.cinzel(
                                        fontSize: 11,
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Tags count badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: summary.allTags.isNotEmpty
                                  ? colorScheme.secondaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: summary.allTags.isNotEmpty
                                    ? AppTheme.goldColor.withValues(alpha: 0.5)
                                    : colorScheme.outline,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\u2728 ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: summary.allTags.isNotEmpty
                                        ? AppTheme.goldColor
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '${summary.allTags.length}',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: summary.allTags.isNotEmpty
                                        ? colorScheme.onSecondaryContainer
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Info row
                      Row(
                        children: [
                          _buildInfoChip(
                            colorScheme,
                            '\u2726',
                            dateFormat.format(summary.completedAt),
                          ),
                          const SizedBox(width: 12),
                          _buildInfoChip(
                            colorScheme,
                            '\u2714',
                            '${summary.filledFields}/${summary.totalFields} epreuves',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Expanded tags section
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '\u269C ',
                        style: TextStyle(
                          color: AppTheme.goldColor,
                        ),
                      ),
                      Text(
                        'Sceaux Magiques',
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (summary.allTags.isEmpty)
                    Text(
                      'Aucun sceau n\'a ete appose sur ce parchemin',
                      style: GoogleFonts.crimsonText(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: summary.allTags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: AppTheme.goldColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\u2726 ',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppTheme.goldColor,
                                ),
                              ),
                              Text(
                                tag,
                                style: GoogleFonts.crimsonText(
                                  fontSize: 12,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(ColorScheme colorScheme, String icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.crimsonText(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
