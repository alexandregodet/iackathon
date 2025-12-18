import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/di/injection.dart';
import '../../domain/entities/gemma_model_info.dart';
import '../blocs/ask_pdf/ask_pdf_bloc.dart';
import '../blocs/ask_pdf/ask_pdf_event.dart';
import '../blocs/ask_pdf/ask_pdf_state.dart';
import '../widgets/pdf_chat_bubble.dart';
import '../widgets/pdf_source_panel.dart';

class AskPdfPage extends StatefulWidget {
  final GemmaModelInfo modelInfo;

  const AskPdfPage({super.key, required this.modelInfo});

  @override
  State<AskPdfPage> createState() => _AskPdfPageState();
}

class _AskPdfPageState extends State<AskPdfPage> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AskPdfBloc>()..add(const AskPdfInitialize()),
      child: BlocConsumer<AskPdfBloc, AskPdfState>(
        listener: (context, state) {
          // Scroll to bottom when new messages arrive
          if (state.hasMessages) {
            _scrollToBottom();
          }

          // Show error snackbar
          if (state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Une erreur est survenue'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: _buildAppBar(context, state),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AskPdfState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask my PDF',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (state.hasDocument)
            Text(
              state.documentName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
      actions: [
        if (state.hasDocument)
          IconButton(
            onPressed: () =>
                context.read<AskPdfBloc>().add(const AskPdfClearSession()),
            icon: const Icon(Icons.close),
            tooltip: 'Fermer le PDF',
          ),
        if (state.hasSources)
          IconButton(
            onPressed: () =>
                context.read<AskPdfBloc>().add(const AskPdfToggleSourcePanel()),
            icon: Icon(
              state.isSourcePanelOpen
                  ? Icons.chevron_right
                  : Icons.format_quote,
            ),
            tooltip: state.isSourcePanelOpen
                ? 'Masquer les sources'
                : 'Afficher les sources',
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AskPdfState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if embedder needs setup
    if (!state.isEmbedderReady) {
      return _buildEmbedderSetup(context, state);
    }

    return Row(
      children: [
        // Main content
        Expanded(
          child: Column(
            children: [
              // Chat area
              Expanded(
                child: state.hasDocument
                    ? _buildChatArea(context, state)
                    : _buildWelcomeState(context, state),
              ),
              // Input area
              if (state.hasDocument)
                _buildInputArea(context, state, colorScheme, isDark),
            ],
          ),
        ),
        // Source panel
        if (state.isSourcePanelOpen && state.hasSources)
          PdfSourcePanel(
            sources: state.currentSources,
            selectedIndex: state.selectedSourceIndex,
            onSourceSelected: (index) => context.read<AskPdfBloc>().add(
                  AskPdfSelectSource(index),
                ),
            onClose: () => context.read<AskPdfBloc>().add(
                  const AskPdfToggleSourcePanel(),
                ),
          ),
      ],
    );
  }

  Widget _buildEmbedderSetup(BuildContext context, AskPdfState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_suggest,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Configuration requise',
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le modele d\'embedding doit etre installe pour analyser vos PDFs',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            if (state.isEmbedderDownloading) ...[
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: state.embedderDownloadProgress,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(state.embedderDownloadProgress * 100).toInt()}%',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ] else if (state.isEmbedderLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Chargement...',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ] else if (!state.isEmbedderInstalled) ...[
              FilledButton.icon(
                onPressed: () => context.read<AskPdfBloc>().add(
                      const AskPdfDownloadEmbedder(),
                    ),
                icon: const Icon(Icons.download),
                label: const Text('Telecharger'),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: () => context.read<AskPdfBloc>().add(
                      const AskPdfLoadEmbedder(),
                    ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Charger'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeState(BuildContext context, AskPdfState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Interrogez vos documents',
              style: GoogleFonts.cinzel(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Selectionnez un fichier PDF pour commencer.\nL\'IA analysera le contenu et repondra a vos questions\nen citant les sources du document.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (state.isLoadingDocument) ...[
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  if (state.documentProcessingTotal > 0)
                    Text(
                      'Traitement: ${state.documentProcessingCurrent}/${state.documentProcessingTotal} chunks',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    )
                  else
                    Text(
                      'Extraction du texte...',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: () => _pickPdfFile(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('Selectionner un PDF'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea(BuildContext context, AskPdfState state) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!state.hasMessages) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Posez votre premiere question',
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Document: ${state.documentName}\n${state.documentPageCount} pages - ${state.documentChunkCount} segments',
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final isLastMessage = index == state.messages.length - 1;

        return PdfChatBubble(
          message: message,
          isCurrentlyThinking: isLastMessage && state.isThinking,
          highlightedSourceIndex: state.selectedSourceIndex,
          onSourceTapped: (sourceIndex) => context.read<AskPdfBloc>().add(
                AskPdfSelectSource(sourceIndex),
              ),
          onCopy: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copie dans le presse-papier'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputArea(
    BuildContext context,
    AskPdfState state,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Change PDF button
            IconButton(
              onPressed: state.isGenerating ? null : () => _pickPdfFile(context),
              icon: const Icon(Icons.attach_file),
              tooltip: 'Changer de PDF',
            ),
            const SizedBox(width: 8),
            // Question input
            Expanded(
              child: TextField(
                controller: _questionController,
                focusNode: _focusNode,
                enabled: state.canSendQuestion,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Posez votre question...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: state.canSendQuestion
                    ? (_) => _sendQuestion(context)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            // Send/Stop button
            if (state.isGenerating)
              IconButton(
                onPressed: () => context.read<AskPdfBloc>().add(
                      const AskPdfStopGeneration(),
                    ),
                icon: Icon(Icons.stop, color: colorScheme.error),
                tooltip: 'Arreter',
              )
            else
              IconButton(
                onPressed: state.canSendQuestion ? () => _sendQuestion(context) : null,
                icon: Icon(
                  Icons.send,
                  color: state.canSendQuestion
                      ? colorScheme.primary
                      : colorScheme.outline,
                ),
                tooltip: 'Envoyer',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPdfFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (!mounted) return;

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      context.read<AskPdfBloc>().add(
            AskPdfSelectFile(
              filePath: file.path!,
              fileName: file.name,
            ),
          );
    }
  }

  void _sendQuestion(BuildContext context) {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    context.read<AskPdfBloc>().add(AskPdfSendQuestion(question));
    _questionController.clear();
    _focusNode.requestFocus();
  }
}
