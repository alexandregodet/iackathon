import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';

import '../../domain/entities/chat_message.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isCurrentlyThinking;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final bool canRegenerate;

  const ChatBubble({
    super.key,
    required this.message,
    this.isCurrentlyThinking = false,
    this.onCopy,
    this.onRegenerate,
    this.canRegenerate = false,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isThinkingExpanded = false;
  bool _showActions = false;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isUser ? colorScheme.onPrimary : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.psychology,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: !isUser && !widget.message.isStreaming
                  ? () => setState(() => _showActions = !_showActions)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.hasImage) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          widget.message.imageBytes!,
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (widget.message.content.isNotEmpty)
                        const SizedBox(height: 8),
                    ],
                    // Thinking section for assistant messages
                    if (!isUser && _shouldShowThinking()) ...[
                      _buildThinkingSection(context, colorScheme),
                      if (widget.message.content.isNotEmpty ||
                          widget.message.isStreaming)
                        const SizedBox(height: 12),
                    ],
                    if (widget.message.content.isNotEmpty ||
                        (widget.message.isStreaming && !widget.message.hasImage))
                      _buildMessageContent(
                        context,
                        isUser: isUser,
                        textColor: textColor,
                        colorScheme: colorScheme,
                      ),
                    if (widget.message.isStreaming && !widget.isCurrentlyThinking) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.primary,
                        ),
                      ),
                    ],
                    // Action buttons for assistant messages
                    if (!isUser && _showActions && !widget.message.isStreaming) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionButton(
                            icon: Icons.copy,
                            label: 'Copier',
                            onTap: () {
                              widget.onCopy?.call();
                              setState(() => _showActions = false);
                            },
                            colorScheme: colorScheme,
                          ),
                          if (widget.canRegenerate) ...[
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.refresh,
                              label: 'Regenerer',
                              onTap: () {
                                widget.onRegenerate?.call();
                                setState(() => _showActions = false);
                              },
                              colorScheme: colorScheme,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(
                Icons.person,
                size: 18,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _shouldShowThinking() {
    return widget.message.hasThinking || widget.isCurrentlyThinking;
  }

  Widget _buildThinkingSection(BuildContext context, ColorScheme colorScheme) {
    final thinkingInProgress = widget.isCurrentlyThinking && !widget.message.isThinkingComplete;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - toujours visible
          InkWell(
            onTap: widget.message.hasThinking
                ? () => setState(() => _isThinkingExpanded = !_isThinkingExpanded)
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_alt,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      thinkingInProgress ? 'Reflexion en cours...' : 'Raisonnement',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (thinkingInProgress)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  else if (widget.message.hasThinking)
                    Icon(
                      _isThinkingExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
          // Content - visible if expanded or currently thinking
          if (_isThinkingExpanded || thinkingInProgress) ...[
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.message.thinkingContent ?? '',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    BuildContext context, {
    required bool isUser,
    required Color textColor,
    required ColorScheme colorScheme,
  }) {
    final content = widget.message.content.isEmpty && widget.message.isStreaming
        ? '...'
        : widget.message.content;

    // Pour les messages utilisateur, afficher en texte simple
    if (isUser) {
      return Text(
        content,
        style: TextStyle(color: textColor),
      );
    }

    // Pour les réponses de l'assistant, utiliser le rendu Markdown
    final theme = Theme.of(context);
    return MarkdownWidget(
      markdown: Markdown.fromString(content),
      theme: MarkdownThemeData.mergeTheme(
        theme,
        textStyle: TextStyle(color: textColor, fontSize: 14),
        h1Style: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        h2Style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        h3Style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        linkColor: colorScheme.primary,
        surfaceColor: colorScheme.surfaceContainerLowest,
        monospaceBackgroundColor: colorScheme.surfaceContainerLowest,
        quoteStyle: TextStyle(
          color: textColor.withValues(alpha: 0.8),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
