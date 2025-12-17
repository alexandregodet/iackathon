import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/gemma_model_info.dart' show AvailableModels;
import 'ask_pdf_page.dart';
import 'checklist_history_page.dart';
import 'checklist_page.dart';
import 'model_selection_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Royal Banner Header
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            actions: [
              _buildRoyalSeal(context, isDark),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
                tooltip: 'Parametres',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'La Compagnie d\'Excalibur',
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              background: _buildHeaderBackground(isDark),
            ),
          ),
          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Manuscript Card - Welcome
                  _buildManuscriptCard(
                    context,
                    colorScheme,
                    isDark,
                    illuminatedLetter: 'B',
                    title: 'Bienvenue, Chevalier',
                    description:
                        'ienvenue dans l\'antre sacre de la maintenance. '
                        'Que votre quete soit fructueuse et vos inspections sans faille.',
                  ),
                  const SizedBox(height: 24),

                  // Medieval Divider
                  _buildDivider(colorScheme),
                  const SizedBox(height: 24),

                  // Features Section
                  _buildSectionTitle(context, 'Pouvoirs Magiques'),
                  const SizedBox(height: 16),
                  _buildFeaturesList(context, colorScheme, isDark),
                  const SizedBox(height: 24),

                  // Medieval Divider
                  _buildDivider(colorScheme),
                  const SizedBox(height: 24),

                  // System Info
                  _buildSectionTitle(context, 'Artefacts du Royaume'),
                  const SizedBox(height: 16),
                  _buildSystemInfo(context, colorScheme, isDark),
                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(context, colorScheme, isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF5A252C),
                  const Color(0xFF3A151C),
                ]
              : [
                  const Color(0xFF722F37),
                  const Color(0xFF5A252C),
                ],
        ),
      ),
      child: Stack(
        children: [
          // Diamond pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _DiamondPatternPainter(
                color: AppTheme.goldColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Gold bottom border
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.3),
                    AppTheme.goldColor,
                    AppTheme.goldColor.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoyalSeal(BuildContext context, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppTheme.waxRedColor,
            AppTheme.waxRedColor.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '\u2694', // Crossed swords
          style: TextStyle(
            fontSize: 18,
            color: isDark ? AppTheme.goldColor : AppTheme.parchmentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildManuscriptCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark, {
    required String illuminatedLetter,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.surfaceContainerLow,
                  colorScheme.surfaceContainer,
                ]
              : [
                  Colors.white.withValues(alpha: 0.5),
                  Colors.white.withValues(alpha: 0.2),
                ],
        ),
        border: Border.all(
          color: colorScheme.outline,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Decorative corner ornament
          Positioned(
            top: -12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: colorScheme.surface,
              child: Text(
                '\u2619', // Floral heart
                style: TextStyle(
                  fontSize: 20,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Illuminated Letter
                Text(
                  illuminatedLetter,
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
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
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
            '\u269C', // Fleur-de-lis
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Text(
          '\u2726 ', // Four-pointed star
          style: TextStyle(
            color: AppTheme.goldColor,
            fontSize: 16,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _buildFeaturesList(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final features = [
      ('local', 'Magie locale', 'Sortileges executes sur l\'appareil'),
      ('offline', 'Hors connexion', 'Nul besoin du reseau royal'),
      ('multimodal', 'Vision enchantee', 'Analyse de textes et images'),
      ('thinking', 'Sagesse profonde', 'Raisonnement DeepSeek'),
      ('rag', 'Grimoires PDF', 'Contexte des parchemins'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainer,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: features.map((f) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  '\u2022 ',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
                Text(
                  f.$2,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  ' : ',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                Expanded(
                  child: Text(
                    f.$3,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSystemInfo(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final infos = [
      ('Moteur', 'Gemma 2/3'),
      ('Quantification', 'int4/int8'),
      ('Contexte', '8192 tokens'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: infos.map((info) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  info.$1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  info.$2,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Column(
      children: [
        // Primary action - Select Model
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ModelSelectionPage()),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\u2726 ',
                  style: TextStyle(color: colorScheme.onPrimary),
                ),
                const Text('Choisir un Sortilege'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Checklist GRIFFON
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ChecklistPage(
                  assetPath: 'assets/checklists/griffon.json',
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\u2694 ',
                  style: TextStyle(color: colorScheme.primary),
                ),
                const Text('Inspection du GRIFFON'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // History
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChecklistHistoryPage()),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\u2617 ',
                  style: TextStyle(color: colorScheme.primary),
                ),
                const Text('Archives du Royaume'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Ask my PDF
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AskPdfPage(
                  modelInfo: AvailableModels.gemma3_1b,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\u{1F4DC} ',
                  style: TextStyle(color: colorScheme.primary),
                ),
                const Text('Interroger mes Grimoires'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for diamond pattern
class _DiamondPatternPainter extends CustomPainter {
  final Color color;

  _DiamondPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 60.0;
    const diamondSize = 10.0;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        final path = Path()
          ..moveTo(x, y - diamondSize)
          ..lineTo(x + diamondSize, y)
          ..lineTo(x, y + diamondSize)
          ..lineTo(x - diamondSize, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
