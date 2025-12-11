import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di/injection.dart';
import '../../data/datasources/gemma_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/gemma_model_info.dart';
import '../blocs/chat/chat_bloc.dart';
import '../blocs/chat/chat_event.dart';
import '../blocs/chat/chat_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/model_status_card.dart';

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
      create: (_) => getIt<ChatBloc>()..add(ChatInitialize(modelInfo)),
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
        title: Text(widget.modelInfo.name),
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (!state.isModelReady) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
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
                    : _buildMessageList(state.messages),
              ),
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

  Widget _buildMessageList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(message: messages[index]);
      },
    );
  }

  Widget _buildInputBar(BuildContext context, ChatState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImageBytes != null) _buildImagePreview(colorScheme),
            Row(
              children: [
                if (state.isMultimodal)
                  IconButton(
                    onPressed: state.isGenerating ? null : _showImageSourceDialog,
                    icon: Icon(
                      Icons.add_photo_alternate,
                      color: state.isGenerating
                          ? colorScheme.outline
                          : colorScheme.primary,
                    ),
                    tooltip: 'Ajouter une image',
                  ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !state.isGenerating,
                    decoration: InputDecoration(
                      hintText: state.isGenerating
                          ? 'Generation en cours...'
                          : _selectedImageBytes != null
                              ? 'Posez une question sur l\'image...'
                              : 'Ecrivez votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(context),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed:
                      state.isGenerating ? null : () => _sendMessage(context),
                  elevation: 0,
                  child: state.isGenerating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _selectedImageBytes!,
              height: 120,
              width: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _clearSelectedImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
