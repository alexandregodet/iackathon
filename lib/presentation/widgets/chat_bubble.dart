import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';

import '../../core/di/injection.dart';
import '../../data/datasources/tts_service.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(colorScheme, isDark, isUser: false),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: !isUser && !widget.message.isStreaming
                  ? () => setState(() => _showActions = !_showActions)
                  : null,
              child: _buildMessageContainer(
                context,
                isUser,
                colorScheme,
                isDark,
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            _buildAvatar(colorScheme, isDark, isUser: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(
    ColorScheme colorScheme,
    bool isDark, {
    required bool isUser,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser
            ? colorScheme.secondary.withValues(alpha: isDark ? 0.3 : 0.15)
            : colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isUser
              ? colorScheme.secondary.withValues(alpha: isDark ? 0.5 : 0.3)
              : colorScheme.primary.withValues(alpha: isDark ? 0.5 : 0.3),
        ),
      ),
      child: Center(
        child: Text(
          isUser ? 'U' : '>',
          style: TextStyle(
            color: isUser ? colorScheme.secondary : colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContainer(
    BuildContext context,
    bool isUser,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser
            ? colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1)
            : isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isUser
              ? colorScheme.primary.withValues(alpha: isDark ? 0.5 : 0.3)
              : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.5 : 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message.hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                widget.message.imageBytes!,
                key: ValueKey('img_${widget.message.id}'),
                width: 200,
                fit: BoxFit.cover,
                gaplessPlayback: false,
              ),
            ),
            if (widget.message.content.isNotEmpty) const SizedBox(height: 10),
          ],
          // Thinking section
          if (!isUser && _shouldShowThinking()) ...[
            _buildThinkingSection(context, colorScheme, isDark),
            if (widget.message.content.isNotEmpty || widget.message.isStreaming)
              const SizedBox(height: 10),
          ],
          if (widget.message.content.isNotEmpty ||
              (widget.message.isStreaming && !widget.message.hasImage))
            _buildMessageContent(
              context,
              isUser: isUser,
              colorScheme: colorScheme,
            ),
          if (widget.message.isStreaming && !widget.isCurrentlyThinking) ...[
            const SizedBox(height: 8),
            _buildTypingIndicator(colorScheme, isUser),
          ],
          // Action buttons
          if (!isUser && _showActions && !widget.message.isStreaming) ...[
            const SizedBox(height: 10),
            _buildActionButtons(colorScheme, isDark),
          ],
          // Token count
          if (widget.message.content.isNotEmpty &&
              !widget.message.isStreaming) ...[
            const SizedBox(height: 6),
            _buildTokenCount(colorScheme, isUser),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme, bool isUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '_',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'processing...',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  bool _shouldShowThinking() {
    return widget.message.hasThinking || widget.isCurrentlyThinking;
  }

  Widget _buildThinkingSection(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final thinkingInProgress =
        widget.isCurrentlyThinking && !widget.message.isThinkingComplete;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.message.hasThinking
                ? () =>
                      setState(() => _isThinkingExpanded = !_isThinkingExpanded)
                : null,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.psychology, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      thinkingInProgress ? '# thinking...' : '# reasoning',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  if (thinkingInProgress)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: colorScheme.primary,
                      ),
                    )
                  else if (widget.message.hasThinking)
                    Icon(
                      _isThinkingExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
          if (_isThinkingExpanded || thinkingInProgress) ...[
            Container(
              height: 1,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                widget.message.thinkingContent ?? '',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
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
    required ColorScheme colorScheme,
  }) {
    final content = widget.message.content.isEmpty && widget.message.isStreaming
        ? '...'
        : widget.message.content;

    final textColor = colorScheme.onSurface;

    if (isUser) {
      return Text(
        content,
        style: TextStyle(color: textColor, fontSize: 13, height: 1.5),
      );
    }

    final theme = Theme.of(context);
    return MarkdownWidget(
      markdown: Markdown.fromString(content),
      theme: MarkdownThemeData.mergeTheme(
        theme,
        textStyle: TextStyle(color: textColor, fontSize: 13, height: 1.5),
        h1Style: TextStyle(
          color: colorScheme.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        h2Style: TextStyle(
          color: colorScheme.primary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        h3Style: TextStyle(
          color: colorScheme.tertiary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        linkColor: colorScheme.primary,
        surfaceColor: colorScheme.surfaceContainer,
        monospaceBackgroundColor: colorScheme.surfaceContainerHigh,
        quoteStyle: TextStyle(
          color: textColor.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme, bool isDark) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _buildActionChip(
          icon: Icons.copy,
          label: 'copy',
          onTap: () {
            widget.onCopy?.call();
            setState(() => _showActions = false);
          },
          colorScheme: colorScheme,
          isDark: isDark,
        ),
        _buildTtsChip(colorScheme, isDark),
        if (widget.canRegenerate)
          _buildActionChip(
            icon: Icons.refresh,
            label: 'regen',
            onTap: () {
              widget.onRegenerate?.call();
              setState(() => _showActions = false);
            },
            colorScheme: colorScheme,
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTtsChip(ColorScheme colorScheme, bool isDark) {
    final ttsService = getIt<TtsService>();
    final isPlaying = ttsService.isPlayingMessage(widget.message.id);

    return _buildActionChip(
      icon: isPlaying ? Icons.stop : Icons.volume_up,
      label: isPlaying ? 'stop' : 'speak',
      onTap: () async {
        if (isPlaying) {
          await ttsService.stop();
        } else {
          await ttsService.speak(widget.message.content, widget.message.id);
        }
        setState(() {});
      },
      colorScheme: colorScheme,
      isDark: isDark,
    );
  }

  Widget _buildTokenCount(ColorScheme colorScheme, bool isUser) {
    final tokens = _estimateTokens(widget.message.content);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '~$tokens tokens',
          style: TextStyle(fontSize: 9, color: colorScheme.outline),
        ),
      ],
    );
  }

  int _estimateTokens(String text) {
    return (text.length / 4).ceil();
  }
}
