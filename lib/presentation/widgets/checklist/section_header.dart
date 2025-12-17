import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/checklist.dart';

class SectionHeader extends StatelessWidget {
  final ChecklistSection section;
  final int sectionNumber;
  final int totalSections;

  const SectionHeader({
    super.key,
    required this.section,
    required this.sectionNumber,
    required this.totalSections,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: colorScheme.outline,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Chapter badge - medieval style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: AppTheme.goldColor,
                    width: 2,
                  ),
                ),
                child: Text(
                  'Chapitre $sectionNumber/$totalSections',
                  style: GoogleFonts.cinzel(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '\u2694 ',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${section.questions.length} epreuve${section.questions.length > 1 ? 's' : ''}',
                      style: GoogleFonts.crimsonText(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Decorative divider
          Row(
            children: [
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '\u269C',
                  style: TextStyle(
                    fontSize: 12,
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
                        Colors.transparent,
                        colorScheme.outline.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title with illuminated first letter effect
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Illuminated letter
              Text(
                section.title.isNotEmpty ? section.title[0] : 'S',
                style: GoogleFonts.medievalSharp(
                  fontSize: 32,
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
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    section.title.length > 1 ? section.title.substring(1) : '',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (section.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              section.description,
              style: GoogleFonts.crimsonText(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
