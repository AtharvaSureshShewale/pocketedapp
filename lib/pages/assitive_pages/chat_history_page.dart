import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'assistive_chat_session.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = Supabase.instance.client
        .from('chatbot_messages')
        .select('chat_id, message, created_at')
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final rows = snapshot.data!;
          final Map<String, Map<String, dynamic>> grouped = {};

          for (final row in rows) {
            if (!grouped.containsKey(row['chat_id'])) {
              grouped[row['chat_id']] = row;
            }
          }

          final sessions = grouped.values.toList();

          if (sessions.isEmpty) return const Center(child: Text('No chat history'));

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (_, i) {
              final s = sessions[i];
              final preview = (s['message'] as String?)?.split('\n').first ?? '';
              final createdAt = DateTime.tryParse(s['created_at'] ?? '')?.toLocal();

              return ListTile(
                title: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: createdAt != null ? Text('$createdAt') : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssistiveChatSession(chatId: s['chat_id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
