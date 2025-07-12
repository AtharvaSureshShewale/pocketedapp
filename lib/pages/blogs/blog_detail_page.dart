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
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    readTimeInSeconds = ((int.tryParse(widget.blog['time_to_read']?.toString() ?? '1') ?? 1) * 60);
    _checkIfAlreadyRewarded();
  }

  Future<void> _checkIfAlreadyRewarded() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    final blogId = widget.blog['id'];

    if (userId == null || blogId == null) return;

    try {
      final existingRead = await Supabase.instance.client
          .from('blog_reads')
          .select()
          .eq('user_id', userId)
          .eq('blog_id', blogId)
          .maybeSingle();

      if (existingRead != null) {
        if (mounted) {
          setState(() {
            _rewarded = true;
          });
        }
        return; // Already rewarded, don't start timer
      }

      // Only start timer if not already rewarded
      startReadingTimer();
    } catch (e) {
      print('Error checking if already rewarded: $e');
    }
  }

  void startReadingTimer() {
    print('📖 Starting reading timer for ${widget.blog['title']} - ${readTimeInSeconds} seconds');
    
    _timer = Timer(Duration(seconds: readTimeInSeconds), () async {
      if (!_isDisposed) {
        await rewardUserIfEligible();
      }
    });
  }

  Future<void> rewardUserIfEligible() async {
    if (_rewarded || _isDisposed) {
      print('⚠️ Skipping reward - already rewarded or disposed');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    final blogId = widget.blog['id'];
    final points = widget.blog['points'] ?? 0;

    if (userId == null || blogId == null) {
      print('❌ Cannot reward - missing user or blog ID');
      return;
    }

    try {
      // Double-check if already rewarded (race condition protection)
      final existingRead = await Supabase.instance.client
          .from('blog_reads')
          .select()
          .eq('user_id', userId)
          .eq('blog_id', blogId)
          .maybeSingle();

      if (existingRead != null) {
        print('⚠️ Already rewarded for this blog');
        if (mounted) {
          setState(() {
            _rewarded = true;
          });
        }
        return;
      }

      print('🎉 Awarding $points points for reading ${widget.blog['title']}');

      // Add read history first
      await Supabase.instance.client.from('blog_reads').insert({
        'user_id': userId,
        'blog_id': blogId,
        'read_at': DateTime.now().toIso8601String(),
      });

      // Then update user's points
      await Supabase.instance.client.rpc('increment_user_points', params: {
        'p_user_id': userId,
        'p_points': points,
      });

      if (mounted && !_isDisposed) {
        setState(() {
          _rewarded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 You earned $points points for reading!'),
            backgroundColor: Colors.green,
          ),
        );
        print('✅ Points awarded successfully');
      }
    } catch (e) {
      print('❌ Error awarding points: $e');
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error awarding points: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    print('🗑️ Blog detail page disposed - timer cancelled');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.blog['title'] ?? '';
    final coverImageUrl = widget.blog['coverImageUrl'] ?? '';
    final description = widget.blog['content'] ?? '';
    final readTime = widget.blog['readTime'] ?? '';
    final publishedAt = widget.blog['publishedAt'] ?? '';
    final points = widget.blog['points'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Details'),
        actions: [
          if (_rewarded)
            const Icon(Icons.check_circle, color: Colors.green, size: 24)
        ],
      ),
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
          Row(
            children: [
              Text('🕒 $readTime • 📅 $publishedAt', 
                   style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const Spacer(),
              Text('⭐ $points points', 
                   style: const TextStyle(fontSize: 14, color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (_rewarded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('You earned $points points for reading this blog!', 
                       style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          if (!_rewarded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('Read for ${readTimeInSeconds ~/ 60} minutes to earn $points points!', 
                       style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
