import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/pdf_source.dart';

/// Panel displaying PDF sources with citations
class PdfSourcePanel extends StatelessWidget {
  final List<PdfSource> sources;
  final int? selectedIndex;
  final ValueChanged<int?>? onSourceSelected;
  final VoidCallback? onClose;

  const PdfSourcePanel({
    super.key,
    required this.sources,
    this.selectedIndex,
    this.onSourceSelected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest,
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, colorScheme, isDark),
          Expanded(
            child: sources.isEmpty
                ? _buildEmptyState(context, colorScheme)
                : _buildSourceList(context, colorScheme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainer
            : colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.format_quote,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sources',
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '${sources.length} ref.',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.find_in_page_outlined,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune source',
              style: GoogleFonts.cinzel(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Posez une question pour voir les references du PDF',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceList(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        final isSelected = selectedIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SourceCard(
            source: source,
            isSelected: isSelected,
            onTap: () => onSourceSelected?.call(isSelected ? null : index),
          ),
        );
      },
    );
  }
}

class _SourceCard extends StatelessWidget {
  final PdfSource source;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SourceCard({
    required this.source,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : isDark
                    ? colorScheme.surfaceContainer
                    : colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with citation number and page
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      source.citationLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.description_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Page ${source.pageNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (source.similarityScore > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(source.similarityScore)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(source.similarityScore * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getScoreColor(source.similarityScore),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Content excerpt
              Text(
                source.content,
                maxLines: isSelected ? 10 : 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: colorScheme.onSurface,
                ),
              ),

              // Image preview if available
              if (source.hasImage && isSelected) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                    source.imageBytes!,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return AppTheme.forestColor;
    if (score >= 0.6) return AppTheme.goldColor;
    return AppTheme.burgundyColor;
  }
}

/// Inline citation chip that can be tapped
class CitationChip extends StatelessWidget {
  final int sourceIndex;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const CitationChip({
    super.key,
    required this.sourceIndex,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: isHighlighted
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '[${sourceIndex + 1}]',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isHighlighted
                  ? colorScheme.onPrimary
                  : colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
