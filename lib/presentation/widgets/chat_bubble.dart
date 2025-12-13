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

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  bool _isThinkingExpanded = false;
  bool _showActions = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _buildAvatar(colorScheme, isUser: false),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: !isUser && !widget.message.isStreaming
                      ? () => setState(() => _showActions = !_showActions)
                      : null,
                  child: _buildMessageContainer(context, isUser, colorScheme),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 12),
                _buildAvatar(colorScheme, isUser: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, {required bool isUser}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUser
              ? [
                  colorScheme.secondary,
                  colorScheme.secondary.withValues(alpha: 0.7),
                ]
              : [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isUser ? colorScheme.secondary : colorScheme.primary)
                .withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
        size: 18,
        color: isUser ? colorScheme.onSecondary : colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildMessageContainer(
    BuildContext context,
    bool isUser,
    ColorScheme colorScheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUser
            ? colorScheme.primary
            : isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 20),
        ),
        border: isUser
            ? null
            : Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
        boxShadow: [
          BoxShadow(
            color: (isUser ? colorScheme.primary : colorScheme.shadow)
                .withValues(alpha: isUser ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message.hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                widget.message.imageBytes!,
                width: 220,
                fit: BoxFit.cover,
              ),
            ),
            if (widget.message.content.isNotEmpty) const SizedBox(height: 12),
          ],
          // Thinking section
          if (!isUser && _shouldShowThinking()) ...[
            _buildThinkingSection(context, colorScheme),
            if (widget.message.content.isNotEmpty || widget.message.isStreaming)
              const SizedBox(height: 14),
          ],
          if (widget.message.content.isNotEmpty ||
              (widget.message.isStreaming && !widget.message.hasImage))
            _buildMessageContent(
              context,
              isUser: isUser,
              colorScheme: colorScheme,
            ),
          if (widget.message.isStreaming && !widget.isCurrentlyThinking) ...[
            const SizedBox(height: 10),
            _buildTypingIndicator(colorScheme, isUser),
          ],
          // Action buttons
          if (!isUser && _showActions && !widget.message.isStreaming) ...[
            const SizedBox(height: 12),
            _buildActionButtons(colorScheme),
          ],
          // Token count
          if (widget.message.content.isNotEmpty &&
              !widget.message.isStreaming) ...[
            const SizedBox(height: 8),
            _buildTokenCount(colorScheme, isUser),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme, bool isUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 200)),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: (isUser ? colorScheme.onPrimary : colorScheme.primary)
                    .withValues(alpha: 0.3 + (0.7 * value)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  bool _shouldShowThinking() {
    return widget.message.hasThinking || widget.isCurrentlyThinking;
  }

  Widget _buildThinkingSection(BuildContext context, ColorScheme colorScheme) {
    final thinkingInProgress =
        widget.isCurrentlyThinking && !widget.message.isThinkingComplete;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.message.hasThinking
                ? () => setState(() => _isThinkingExpanded = !_isThinkingExpanded)
                : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.psychology_alt_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      thinkingInProgress ? 'Reflexion en cours...' : 'Raisonnement',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  if (thinkingInProgress)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  else if (widget.message.hasThinking)
                    Icon(
                      _isThinkingExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
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
              padding: const EdgeInsets.all(14),
              child: Text(
                widget.message.thinkingContent ?? '',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
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

    final textColor = isUser ? colorScheme.onPrimary : colorScheme.onSurface;

    if (isUser) {
      return Text(
        content,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          height: 1.5,
        ),
      );
    }

    final theme = Theme.of(context);
    return MarkdownWidget(
      markdown: Markdown.fromString(content),
      theme: MarkdownThemeData.mergeTheme(
        theme,
        textStyle: TextStyle(color: textColor, fontSize: 15, height: 1.5),
        h1Style: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        h2Style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        h3Style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        linkColor: colorScheme.primary,
        surfaceColor: colorScheme.surfaceContainer,
        monospaceBackgroundColor: colorScheme.surfaceContainer,
        quoteStyle: TextStyle(
          color: textColor.withValues(alpha: 0.8),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionChip(
          icon: Icons.copy_rounded,
          label: 'Copier',
          onTap: () {
            widget.onCopy?.call();
            setState(() => _showActions = false);
          },
          colorScheme: colorScheme,
        ),
        _buildTtsChip(colorScheme),
        if (widget.canRegenerate)
          _buildActionChip(
            icon: Icons.refresh_rounded,
            label: 'Regenerer',
            onTap: () {
              widget.onRegenerate?.call();
              setState(() => _showActions = false);
            },
            colorScheme: colorScheme,
          ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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

  Widget _buildTtsChip(ColorScheme colorScheme) {
    final ttsService = getIt<TtsService>();
    final isPlaying = ttsService.isPlayingMessage(widget.message.id);

    return _buildActionChip(
      icon: isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
      label: isPlaying ? 'Stop' : 'Ecouter',
      onTap: () async {
        if (isPlaying) {
          await ttsService.stop();
        } else {
          await ttsService.speak(widget.message.content, widget.message.id);
        }
        setState(() {});
      },
      colorScheme: colorScheme,
    );
  }

  Widget _buildTokenCount(ColorScheme colorScheme, bool isUser) {
    final tokens = _estimateTokens(widget.message.content);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.token_rounded,
          size: 12,
          color: isUser
              ? colorScheme.onPrimary.withValues(alpha: 0.5)
              : colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          '~$tokens tokens',
          style: TextStyle(
            fontSize: 11,
            color: isUser
                ? colorScheme.onPrimary.withValues(alpha: 0.5)
                : colorScheme.outline,
          ),
        ),
      ],
    );
  }

  int _estimateTokens(String text) {
    return (text.length / 4).ceil();
  }
}
