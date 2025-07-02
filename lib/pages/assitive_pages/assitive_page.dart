import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'chat_history_page.dart';

class AssistivePage extends StatefulWidget {
  const AssistivePage({super.key});

  @override
  State<AssistivePage> createState() => _AssistivePageState();
}

class _AssistivePageState extends State<AssistivePage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  late final String chatId;
  late final GenerativeModel model;
  late final ChatSession chat;

  @override
  void initState() {
    super.initState();
    chatId = const Uuid().v4();
    model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey:
          'AIzaSyBRUCEwpquGdDx4tWZdwed_i5-LCWPTQkg', // Replace with secure storage in production
    );
    chat = model.startChat();
  }

  void _sendMessage(String text) async {
    if (text.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not authenticated")));
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'message': text});
      _controller.clear();
    });

    try {
      // Insert user message
      await Supabase.instance.client.from('chatbot_messages').insert({
        'chat_id': chatId,
        'user_id': userId,
        'role': 'user',
        'message': text,
      });

      // Get AI response
      final response = await chat.sendMessage(Content.text(text));
      final reply = response.text ?? 'No response';

      setState(() {
        _messages.add({'role': 'ai', 'message': reply});
      });

      // Insert AI message
      await Supabase.instance.client.from('chatbot_messages').insert({
        'chat_id': chatId,
        'user_id': userId,
        'role': 'ai',
        'message': reply,
      });

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistive Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatHistoryPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.deepPurpleAccent
                          : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: MarkdownBody(
                      data: msg['message'] ?? '',
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ).copyWith(
                            p: const TextStyle(
                              color: Colors.white,
                            ), // white text
                          ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 50),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ask something...',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
