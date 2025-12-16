import 'dart:io';

import 'package:flutter/material.dart';

import '../../../domain/entities/checklist.dart';
import '../../../domain/entities/checklist_response.dart';

class QuestionCard extends StatefulWidget {
  final ChecklistQuestion question;
  final QuestionResponse? response;
  final ValueChanged<String?> onResponseChanged;
  final ValueChanged<String?> onCommentChanged;
  final VoidCallback onAddAttachment;
  final ValueChanged<String> onRemoveAttachment;

  const QuestionCard({
    super.key,
    required this.question,
    this.response,
    required this.onResponseChanged,
    required this.onCommentChanged,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  late TextEditingController _responseController;
  late TextEditingController _commentController;
  bool _showComment = false;

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController(
      text: widget.response?.response ?? '',
    );
    _commentController = TextEditingController(
      text: widget.response?.comment ?? '',
    );
    _showComment = widget.response?.comment?.isNotEmpty ?? false;
  }

  @override
  void didUpdateWidget(QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.response?.response != widget.response?.response) {
      final newText = widget.response?.response ?? '';
      if (_responseController.text != newText) {
        _responseController.text = newText;
      }
    }
    if (oldWidget.response?.comment != widget.response?.comment) {
      final newText = widget.response?.comment ?? '';
      if (_commentController.text != newText) {
        _commentController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionHeader(colorScheme, textTheme),
            const SizedBox(height: 12),
            _buildResponseField(colorScheme),
            if (widget.question.attachment) ...[
              const SizedBox(height: 12),
              _buildAttachmentSection(colorScheme, textTheme),
            ],
            if (widget.question.comment) ...[
              const SizedBox(height: 12),
              _buildCommentSection(colorScheme, textTheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${widget.question.id}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.question.title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.question.mandatory)
                    Text(
                      '* Obligatoire',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (widget.question.hint != null && widget.question.hint!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.question.hint!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResponseField(ColorScheme colorScheme) {
    final isLongFormat = widget.question.format == 'long';

    return TextField(
      controller: _responseController,
      decoration: InputDecoration(
        hintText: 'Votre reponse...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      maxLines: isLongFormat ? 4 : 1,
      onChanged: widget.onResponseChanged,
    );
  }

  Widget _buildAttachmentSection(ColorScheme colorScheme, TextTheme textTheme) {
    final attachments = widget.response?.attachmentPaths ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_file,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Pieces jointes',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: widget.onAddAttachment,
              icon: const Icon(Icons.add_a_photo, size: 18),
              label: const Text('Ajouter'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: attachments.length,
              itemBuilder: (context, index) {
                final path = attachments[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildAttachmentThumbnail(path, colorScheme),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentThumbnail(String path, ColorScheme colorScheme) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => widget.onRemoveAttachment(path),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 14,
                color: colorScheme.onError,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showComment = !_showComment;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _showComment ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ajouter un commentaire',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showComment) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Commentaire optionnel...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            maxLines: 2,
            onChanged: widget.onCommentChanged,
          ),
        ],
      ],
    );
  }
}
