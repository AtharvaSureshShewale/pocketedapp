import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlogDetailPage extends StatefulWidget {
  final Map<String, dynamic> blog;

  const BlogDetailPage({super.key, required this.blog});

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  late final int readTimeInSeconds;
  Timer? _timer;
  bool _rewarded = false;

  @override
  void initState() {
    super.initState();
    readTimeInSeconds = ((int.tryParse(widget.blog['time_to_read']?.toString() ?? '1') ?? 1) * 60);
    startReadingTimer();
  }

  void startReadingTimer() {
    _timer = Timer(Duration(seconds: readTimeInSeconds), () async {
      await rewardUserIfEligible();
    });
  }

  Future<void> rewardUserIfEligible() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    final blogId = widget.blog['id'];
    final points = widget.blog['points'] ?? 0;

    if (userId == null || blogId == null || _rewarded) return;

    final existingRead = await Supabase.instance.client
        .from('blog_reads')
        .select()
        .eq('user_id', userId)
        .eq('blog_id', blogId)
        .maybeSingle();

    if (existingRead != null) return; // Already rewarded

    // Add read history
    await Supabase.instance.client.from('blog_reads').insert({
      'user_id': userId,
      'blog_id': blogId,
    });

    // Update user's points in profile
    await Supabase.instance.client.rpc('increment_user_points', params: {
      'p_user_id': userId,
      'p_points': points,
    });

    if (mounted) {
      setState(() {
        _rewarded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🎉 You earned $points points for reading!')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.blog['title'] ?? '';
    final coverImageUrl = widget.blog['coverImageUrl'] ?? '';
    final description = widget.blog['description'] ?? '';
    final readTime = widget.blog['readTime'] ?? '';
    final publishedAt = widget.blog['publishedAt'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Blog Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (coverImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                coverImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox(height: 200, child: Center(child: Icon(Icons.broken_image))),
              ),
            ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('🕒 $readTime • 📅 $publishedAt', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
