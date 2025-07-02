import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// Save a single chat message
Future<void> saveMessageToSupabase({
  required int chatId,
  required String role,
  required String message,
  int? userId,
}) async {
  await supabase.from('chat_messages').insert({
    'chat_id': chatId,
    'user_id': userId,
    'role': role,
    'message': message,
  });
}

/// Fetch a list of chat sessions (grouped by chat_id)
Future<List<Map<String, dynamic>>> fetchChatSessions() async {
  final response = await supabase
      .from('chat_messages')
      .select('chat_id, created_at, message')
      .order('created_at', ascending: false);

  final seenIds = <int>{};
  final sessions = <Map<String, dynamic>>[];

  for (var row in response) {
    final id = row['chat_id'] as int;
    if (seenIds.contains(id)) continue;
    seenIds.add(id);
    sessions.add(row);
  }

  return sessions;
}

/// Fetch messages for a specific chat session
Future<List<Map<String, dynamic>>> fetchMessagesForChat(int chatId) async {
  final response = await supabase
      .from('chat_messages')
      .select()
      .eq('chat_id', chatId)
      .order('created_at');

  return List<Map<String, dynamic>>.from(response);
}
