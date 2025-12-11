import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';

import '../../domain/entities/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
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
                  if (message.hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        message.imageBytes!,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (message.content.isNotEmpty) const SizedBox(height: 8),
                  ],
                  if (message.content.isNotEmpty ||
                      (message.isStreaming && !message.hasImage))
                    _buildMessageContent(
                      context,
                      isUser: isUser,
                      textColor: textColor,
                      colorScheme: colorScheme,
                    ),
                  if (message.isStreaming) ...[
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
                ],
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

  Widget _buildMessageContent(
    BuildContext context, {
    required bool isUser,
    required Color textColor,
    required ColorScheme colorScheme,
  }) {
    final content = message.content.isEmpty && message.isStreaming
        ? '...'
        : message.content;

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
}
