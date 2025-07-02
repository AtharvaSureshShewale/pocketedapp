import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssistiveChatSession extends StatefulWidget {
  final String chatId;

  const AssistiveChatSession({super.key, required this.chatId});

  @override
  State<AssistiveChatSession> createState() => _AssistiveChatSessionState();
}

class _AssistiveChatSessionState extends State<AssistiveChatSession> {
  late Future<List<Map<String, dynamic>>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _messagesFuture = Supabase.instance.client
        .from('chatbot_messages')
        .select()
        .eq('chat_id', widget.chatId)
        .order('created_at', ascending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Session')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final messages = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (_, i) {
              final m = messages[i];
              final isUser = m['role'] == 'user';
              final messageText = m['message'] ?? '';
              final timestamp = m['created_at'] != null
                  ? DateTime.parse(m['created_at']).toLocal().toString()
                  : null;

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.deepPurpleAccent : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: MarkdownBody(
                        data: messageText,
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    if (timestamp != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          timestamp,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
