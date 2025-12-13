import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/conversation_info.dart';
import '../blocs/chat/chat_bloc.dart';
import '../blocs/chat/chat_event.dart';
import '../blocs/chat/chat_state.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(const ChatLoadConversations());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createNewConversation(context),
            tooltip: 'Nouvelle conversation',
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state.isLoadingConversations) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune conversation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Creez une nouvelle conversation pour commencer',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _createNewConversation(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle conversation'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.conversations.length,
            itemBuilder: (context, index) {
              final conversation = state.conversations[index];
              final isSelected = state.currentConversationId == conversation.id;

              return _ConversationTile(
                conversation: conversation,
                isSelected: isSelected,
                onTap: () => _selectConversation(context, conversation),
                onDelete: () => _deleteConversation(context, conversation),
                onRename: () => _renameConversation(context, conversation),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewConversation(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle'),
      ),
    );
  }

  void _createNewConversation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Nouvelle conversation'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Titre (optionnel)',
              hintText: 'Ex: Questions sur Flutter',
            ),
            autofocus: true,
            onSubmitted: (_) {
              Navigator.of(dialogContext).pop();
              context.read<ChatBloc>().add(
                    ChatCreateConversation(
                      title: controller.text.isNotEmpty ? controller.text : null,
                    ),
                  );
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<ChatBloc>().add(
                      ChatCreateConversation(
                        title: controller.text.isNotEmpty ? controller.text : null,
                      ),
                    );
                Navigator.of(context).pop();
              },
              child: const Text('Creer'),
            ),
          ],
        );
      },
    );
  }

  void _selectConversation(BuildContext context, ConversationInfo conversation) {
    context.read<ChatBloc>().add(ChatLoadConversation(conversation.id));
    Navigator.of(context).pop();
  }

  void _deleteConversation(BuildContext context, ConversationInfo conversation) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la conversation'),
        content: Text(
          'Voulez-vous vraiment supprimer "${conversation.title}" ?\n'
          'Cette action est irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ChatBloc>().add(
                    ChatDeleteConversation(conversation.id),
                  );
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

  void _renameConversation(BuildContext context, ConversationInfo conversation) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController(text: conversation.title);
        return AlertDialog(
          title: const Text('Renommer la conversation'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nouveau titre',
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Navigator.of(dialogContext).pop();
                context.read<ChatBloc>().add(
                      ChatRenameConversation(
                        conversationId: conversation.id,
                        newTitle: value,
                      ),
                    );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.of(dialogContext).pop();
                  context.read<ChatBloc>().add(
                        ChatRenameConversation(
                          conversationId: conversation.id,
                          newTitle: controller.text,
                        ),
                      );
                }
              },
              child: const Text('Renommer'),
            ),
          ],
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationInfo conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? colorScheme.primaryContainer : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.chat,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (conversation.lastMessage != null)
              Text(
                conversation.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Row(
              children: [
                Text(
                  dateFormat.format(conversation.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${conversation.messageCount} messages',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'rename':
                onRename();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Renommer'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: colorScheme.error)),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
