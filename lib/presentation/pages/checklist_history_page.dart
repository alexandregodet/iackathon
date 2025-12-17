import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection.dart';
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
        title: Row(
          children: [
            Text('> ', style: TextStyle(color: colorScheme.primary)),
            const Text('Historique'),
          ],
        ),
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: colorScheme.error),
                        const SizedBox(height: 16),
                        Text(state.error!),
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
                        Icon(
                          state.hasSearch
                              ? Icons.search_off
                              : Icons.assignment_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.hasSearch
                              ? 'Aucun resultat pour "${state.searchQuery}"'
                              : 'Aucune checklist completee',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
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
          hintText: 'Rechercher par tag, SN ou titre...',
          prefixIcon: const Icon(Icons.search),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
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
    final textTheme = Theme.of(context).textTheme;
    final isExpanded = _expandedItems.contains(summary.checklistId);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Main content - tappable to expand
          Material(
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
                    // Header row with title and expand icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.assignment,
                            color: colorScheme.onPrimaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary.checklistTitle,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.tag,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'SN: ${summary.serialNumber}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: summary.allTags.isNotEmpty
                                ? colorScheme.secondaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: summary.allTags.isNotEmpty
                                    ? colorScheme.onSecondaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${summary.allTags.length}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: summary.allTags.isNotEmpty
                                      ? colorScheme.onSecondaryContainer
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
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
                          Icons.calendar_today,
                          dateFormat.format(summary.completedAt),
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          colorScheme,
                          Icons.check_circle_outline,
                          '${summary.filledFields}/${summary.totalFields} champs',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expanded tags section with animation
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tags IA',
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (summary.allTags.isEmpty)
                    Text(
                      'Aucun tag IA genere pour cette checklist',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
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
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            tag,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
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

  Widget _buildInfoChip(ColorScheme colorScheme, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
