import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di/injection.dart';
import '../../data/datasources/gemma_service.dart';
import '../../data/datasources/rag_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/document_info.dart';
import '../../domain/entities/gemma_model_info.dart';
import '../blocs/chat/chat_bloc.dart';
import '../blocs/chat/chat_event.dart';
import '../blocs/chat/chat_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/model_status_card.dart';
import 'conversations_page.dart';
import 'prompt_templates_page.dart';

class ChatPage extends StatelessWidget {
  final GemmaModelInfo modelInfo;
  final String? huggingFaceToken;

  const ChatPage({
    super.key,
    required this.modelInfo,
    this.huggingFaceToken,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatBloc>()
        ..add(ChatInitialize(modelInfo))
        ..add(const ChatCheckEmbedder())
        ..add(const ChatLoadDocuments()),
      child: _ChatPageContent(
        modelInfo: modelInfo,
        huggingFaceToken: huggingFaceToken,
      ),
    );
  }
}

class _ChatPageContent extends StatefulWidget {
  final GemmaModelInfo modelInfo;
  final String? huggingFaceToken;

  const _ChatPageContent({
    required this.modelInfo,
    this.huggingFaceToken,
  });

  @override
  State<_ChatPageContent> createState() => _ChatPageContentState();
}

class _ChatPageContentState extends State<_ChatPageContent> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  Uint8List? _selectedImageBytes;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  void _showImageSourceDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: colorScheme.primary),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: colorScheme.primary),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PromptTemplatePicker(
        onSelected: (content) {
          _controller.text = content;
        },
      ),
    );
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  void _showSystemPromptDialog() {
    final gemmaService = getIt<GemmaService>();
    final controller = TextEditingController(text: gemmaService.systemPrompt);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings_suggest, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Instructions systeme'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 6,
            decoration: InputDecoration(
              hintText:
                  'Ex: Tu es un assistant utile. Reponds toujours en francais...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clear();
              gemmaService.setSystemPrompt(null);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Instructions systeme effacees'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Effacer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              gemmaService.setSystemPrompt(controller.text);
              Navigator.pop(context);
              if (controller.text.trim().isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Instructions systeme enregistrees'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPdf(BuildContext context) async {
    final bloc = context.read<ChatBloc>();
    final state = bloc.state;

    // Check embedder status
    if (!state.isEmbedderReady) {
      final shouldContinue = await _showEmbedderDialog(context, state);
      if (!shouldContinue) return;
    }

    // Pick PDF file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      bloc.add(ChatDocumentSelected(
        filePath: file.path!,
        fileName: file.name,
      ));
    }
  }

  Future<bool> _showEmbedderDialog(BuildContext context, ChatState state) async {
    final colorScheme = Theme.of(context).colorScheme;
    final bloc = context.read<ChatBloc>();

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => BlocProvider.value(
            value: bloc,
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final isDownloading =
                    state.embedderState == EmbedderState.downloading;
                final isLoading = state.embedderState == EmbedderState.loading;
                final isInstalled =
                    state.embedderState == EmbedderState.installed;
                final isReady = state.embedderState == EmbedderState.ready;

                if (isReady) {
                  Navigator.pop(context, true);
                  return const SizedBox.shrink();
                }

                return AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.download, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Modele RAG'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isDownloading && !isLoading && !isInstalled)
                        const Text(
                          'Pour analyser les documents PDF, un modele d\'embedding (~75 Mo) doit etre telecharge.',
                        ),
                      if (isDownloading) ...[
                        const Text('Telechargement en cours...'),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: state.embedderDownloadProgress,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(state.embedderDownloadProgress * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (isLoading) ...[
                        const Text('Chargement du modele...'),
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                      ],
                      if (isInstalled) ...[
                        const Text(
                          'Modele telecharge. Appuyez sur Charger pour continuer.',
                        ),
                      ],
                      if (state.hasRagError) ...[
                        const SizedBox(height: 8),
                        Text(
                          state.ragErrorMessage!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    if (!isDownloading && !isLoading)
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                    if (!isDownloading && !isLoading && !isInstalled)
                      FilledButton(
                        onPressed: () {
                          context.read<ChatBloc>().add(
                                const ChatDownloadEmbedder(),
                              );
                        },
                        child: const Text('Telecharger'),
                      ),
                    if (isInstalled)
                      FilledButton(
                        onPressed: () {
                          context.read<ChatBloc>().add(const ChatLoadEmbedder());
                        },
                        child: const Text('Charger'),
                      ),
                  ],
                );
              },
            ),
          ),
        ) ??
        false;
  }

  void _showDocumentsDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bloc = context.read<ChatBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Documents (${state.documents.length})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _pickPdf(context);
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Ajouter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Les documents actifs seront utilises pour enrichir vos questions.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 16),
                      if (state.documents.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 48,
                                  color: colorScheme.outline,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aucun document',
                                  style: TextStyle(color: colorScheme.outline),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: state.documents.length,
                            itemBuilder: (context, index) {
                              final doc = state.documents[index];
                              return _buildDocumentTile(context, doc);
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDocumentTile(BuildContext context, DocumentInfo doc) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.picture_as_pdf,
          color: doc.isActive ? colorScheme.primary : colorScheme.outline,
        ),
        title: Text(
          doc.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${doc.totalChunks} chunks',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: doc.isActive,
              onChanged: (value) {
                context.read<ChatBloc>().add(
                      ChatToggleDocument(
                        documentId: doc.id,
                        isActive: value,
                      ),
                    );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: () {
                _confirmDeleteDocument(context, doc);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDocument(BuildContext context, DocumentInfo doc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le document ?'),
        content: Text('Voulez-vous supprimer "${doc.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ChatBloc>().add(ChatRemoveDocument(doc.id));
              Navigator.pop(dialogContext);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
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

  void _showErrorSnackBar(BuildContext context, ChatState state) {
    if (state.error == null) return;

    final colorScheme = Theme.of(context).colorScheme;
    final error = state.error!;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error.isRecoverable ? Icons.warning_amber_rounded : Icons.error_rounded,
              color: colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.userMessage,
                style: TextStyle(color: colorScheme.onError),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.error,
        duration: Duration(seconds: error.isRecoverable ? 5 : 8),
        behavior: SnackBarBehavior.floating,
        action: error.isRecoverable
            ? SnackBarAction(
                label: 'Reessayer',
                textColor: colorScheme.onError,
                onPressed: () => _handleRetry(context, error),
              )
            : null,
      ),
    );
  }

  void _handleRetry(BuildContext context, dynamic error) {
    final bloc = context.read<ChatBloc>();
    final errorCode = error.code as String;

    if (errorCode.startsWith('NETWORK_') || errorCode == 'MODEL_LOADING_FAILED') {
      if (bloc.state.modelState == GemmaModelState.error) {
        bloc.add(ChatDownloadModel(huggingFaceToken: widget.huggingFaceToken));
      }
    } else if (errorCode == 'MODEL_NOT_LOADED') {
      bloc.add(const ChatLoadModel());
    }
  }

  void _sendMessage(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImageBytes == null) return;

    context.read<ChatBloc>().add(
          ChatSendMessage(text, imageBytes: _selectedImageBytes),
        );
    _controller.clear();
    _clearSelectedImage();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            final title = state.currentConversation != null
                ? state.currentConversation!.title
                : widget.modelInfo.name;
            return Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                _buildModelStatusBadge(context, state),
              ],
            );
          },
        ),
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (!state.isModelReady) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<ChatBloc>(),
                            child: const ConversationsPage(),
                          ),
                        ),
                      );
                    },
                    tooltip: 'Historique des conversations',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_suggest),
                    onPressed: _showSystemPromptDialog,
                    tooltip: 'Instructions systeme',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      context.read<ChatBloc>().add(const ChatClearConversation());
                    },
                    tooltip: 'Effacer la conversation',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listenWhen: (previous, current) {
          // Seulement ecouter les nouvelles erreurs
          return (current.hasError && previous.error != current.error) ||
              (current.isGenerating && !previous.isGenerating);
        },
        listener: (context, state) {
          if (state.hasError) {
            _showErrorSnackBar(context, state);
          }
          if (state.isGenerating) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          if (!state.isModelReady) {
            return ModelStatusCard(
              state: state,
              onDownload: () {
                context.read<ChatBloc>().add(
                      ChatDownloadModel(huggingFaceToken: widget.huggingFaceToken),
                    );
              },
              onLoad: () {
                context.read<ChatBloc>().add(const ChatLoadModel());
              },
            );
          }

          return Column(
            children: [
              Expanded(
                child: state.messages.isEmpty
                    ? _buildEmptyState(context, state)
                    : _buildMessageList(state.messages, state),
              ),
              if (state.messages.isNotEmpty)
                _buildContextIndicator(context, state),
              _buildInputBar(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ChatState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isMultimodal ? Icons.image : Icons.chat_bubble_outline,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Demarrez une conversation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              state.isMultimodal
                  ? 'Posez une question ou envoyez une image'
                  : 'Posez une question au modele',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            if (state.isMultimodal) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Vision activee',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onTertiaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages, ChatState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isLastMessage = index == messages.length - 1;
        final isLastAssistant =
            isLastMessage && message.role == MessageRole.assistant;

        return ChatBubble(
          message: message,
          isCurrentlyThinking: isLastMessage && state.isThinking,
          canRegenerate: isLastAssistant && !state.isGenerating,
          onCopy: message.role == MessageRole.assistant
              ? () {
                  context.read<ChatBloc>().add(ChatCopyMessage(message.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message copie'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              : null,
          onRegenerate: isLastAssistant
              ? () {
                  context.read<ChatBloc>().add(ChatRegenerateMessage(message.id));
                }
              : null,
        );
      },
    );
  }

  Widget _buildContextIndicator(BuildContext context, ChatState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final usagePercent = state.contextUsagePercent;
    final tokensUsed = state.estimatedTokensUsed;
    final maxTokens = ChatState.maxContextTokens;

    Color progressColor;
    if (usagePercent > 0.9) {
      progressColor = colorScheme.error;
    } else if (usagePercent > 0.7) {
      progressColor = Colors.orange;
    } else {
      progressColor = colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.memory,
            size: 16,
            color: state.isContextNearlyFull
                ? colorScheme.error
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Contexte',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '~$tokensUsed / $maxTokens tokens',
                      style: TextStyle(
                        fontSize: 11,
                        color: state.isContextNearlyFull
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                        fontWeight: state.isContextNearlyFull
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: usagePercent,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(progressColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          if (state.isContextNearlyFull) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Le contexte est presque plein.\nCreez une nouvelle conversation.',
              child: Icon(
                Icons.warning_amber,
                size: 18,
                color: colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ChatState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImageBytes != null) _buildImagePreview(colorScheme),
            // Processing indicator
            if (state.isProcessingDocument)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '# processing ${state.documentProcessingCurrent}/${state.documentProcessingTotal}',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Add button (+)
                _buildAddButton(context, state, colorScheme, isDark),
                const SizedBox(width: 8),
                // Text field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      enabled: !state.isGenerating,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: state.isGenerating
                            ? '> processing...'
                            : _selectedImageBytes != null
                                ? '> describe image...'
                                : '> enter message...',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(context),
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send/Stop button
                _buildSendButton(context, state, colorScheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    ChatState state,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final hasAttachments = state.hasActiveDocuments || _selectedImageBytes != null;
    final isDisabled = state.isGenerating || state.isProcessingDocument;

    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: hasAttachments
            ? colorScheme.primary.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: isDisabled ? null : () => _showAttachmentMenu(context, state),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: hasAttachments
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : isDark
                        ? colorScheme.primary.withValues(alpha: 0.3)
                        : colorScheme.outlineVariant,
              ),
            ),
            child: Badge(
              isLabelVisible: state.activeDocumentCount > 0,
              label: Text(
                '${state.activeDocumentCount}',
                style: const TextStyle(fontSize: 9),
              ),
              child: Icon(
                Icons.add,
                color: isDisabled
                    ? colorScheme.outline
                    : hasAttachments
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(
    BuildContext context,
    ChatState state,
    ColorScheme colorScheme,
  ) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: state.isGenerating
            ? colorScheme.error.withValues(alpha: 0.15)
            : colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: state.isGenerating
              ? () => context.read<ChatBloc>().add(const ChatStopGeneration())
              : () => _sendMessage(context),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: state.isGenerating
                    ? colorScheme.error.withValues(alpha: 0.5)
                    : colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              state.isGenerating ? Icons.stop : Icons.arrow_forward,
              color: state.isGenerating ? colorScheme.error : colorScheme.primary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context, ChatState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '> ',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                  Text(
                    'attach',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // PDF option
            _buildAttachmentOption(
              context: context,
              icon: Icons.description,
              label: 'pdf',
              subtitle: state.hasActiveDocuments
                  ? '${state.activeDocumentCount} active'
                  : 'add document',
              isActive: state.hasActiveDocuments,
              onTap: () {
                Navigator.pop(context);
                _pickPdf(context);
              },
              onLongPress: () {
                Navigator.pop(context);
                _showDocumentsDialog(context);
              },
              colorScheme: colorScheme,
            ),
            // Image option (multimodal only)
            if (state.isMultimodal)
              _buildAttachmentOption(
                context: context,
                icon: Icons.image,
                label: 'image',
                subtitle: _selectedImageBytes != null ? 'attached' : 'add photo',
                isActive: _selectedImageBytes != null,
                onTap: () {
                  Navigator.pop(context);
                  _showImageSourceDialog();
                },
                colorScheme: colorScheme,
              ),
            // Templates option
            _buildAttachmentOption(
              context: context,
              icon: Icons.code,
              label: 'template',
              subtitle: 'prompt library',
              onTap: () {
                Navigator.pop(context);
                _showTemplatePicker(context);
              },
              colorScheme: colorScheme,
              useSecondary: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool isActive = false,
    required ColorScheme colorScheme,
    bool useSecondary = false,
  }) {
    final color = isActive
        ? colorScheme.primary
        : useSecondary
            ? colorScheme.secondary
            : colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? color : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark
                        ? colorScheme.primary.withValues(alpha: 0.5)
                        : colorScheme.outlineVariant,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Image.memory(
                    _selectedImageBytes!,
                    key: ValueKey(_selectedImageBytes.hashCode),
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                    gaplessPlayback: false,
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _clearSelectedImage,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: colorScheme.onError,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '# image attached',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelStatusBadge(BuildContext context, ChatState state) {
    final colorScheme = Theme.of(context).colorScheme;

    Color badgeColor;
    IconData icon;
    String tooltip;

    if (state.isModelReady) {
      badgeColor = Colors.green;
      icon = Icons.check_circle;
      tooltip = 'Modele pret';
    } else if (state.isLoading) {
      badgeColor = Colors.orange;
      icon = Icons.hourglass_top;
      tooltip = 'Chargement...';
    } else if (state.isDownloading) {
      badgeColor = Colors.blue;
      icon = Icons.download;
      tooltip = 'Telechargement ${(state.downloadProgress * 100).toInt()}%';
    } else if (state.modelState == GemmaModelState.error) {
      badgeColor = colorScheme.error;
      icon = Icons.error;
      tooltip = 'Erreur';
    } else if (state.isModelInstalled) {
      badgeColor = Colors.grey;
      icon = Icons.circle;
      tooltip = 'Modele installe (non charge)';
    } else {
      badgeColor = Colors.grey;
      icon = Icons.download;
      tooltip = 'Modele non installe';
    }

    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: 16,
        color: badgeColor,
      ),
    );
  }
}
