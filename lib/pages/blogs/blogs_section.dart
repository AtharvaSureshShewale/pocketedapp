import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'blog_card.dart';

class BlogSection extends StatefulWidget {
  final List<Map<String, dynamic>> blogPosts;
  final bool isHorizontal;
  final void Function(Map<String, dynamic> blog)? onCardTap;

  const BlogSection({
    super.key,
    required this.blogPosts,
    this.isHorizontal = false,
    this.onCardTap,
  });

  @override
  State<BlogSection> createState() => _BlogSectionState();
}

class _BlogSectionState extends State<BlogSection> {
  Set<String> _readBlogIds = {};
  bool _isLoadingReadStatus = true;

  @override
  void initState() {
    super.initState();
    _loadReadStatus();
  }

  Future<void> _loadReadStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoadingReadStatus = false);
        return;
      }

      final blogIds = widget.blogPosts.map((blog) => blog['id']).whereType<String>().toList();
      if (blogIds.isEmpty) {
        setState(() => _isLoadingReadStatus = false);
        return;
      }

      final readBlogs = await Supabase.instance.client
          .from('blog_reads')
          .select('blog_id')
          .eq('user_id', user.id)
          .inFilter('blog_id', blogIds);

      setState(() {
        _readBlogIds = readBlogs.map((read) => read['blog_id'] as String).toSet();
        _isLoadingReadStatus = false;
      });
    } catch (e) {
      print('Error loading blog read status: $e');
      setState(() => _isLoadingReadStatus = false);
    }
  }

  // Method to refresh read status (can be called from parent)
  Future<void> refreshReadStatus() async {
    await _loadReadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        widget.isHorizontal
            ? SizedBox(
                height: 280,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.blogPosts.length,
                  itemBuilder: (context, index) {
                    final blog = widget.blogPosts[index];
                    final isRead = _readBlogIds.contains(blog['id']);
                    
                    return BlogCard(
                      title: blog['title'] ?? '',
                      coverImageUrl:
                          blog['coverImageUrl'] ?? blog['cover_image_url'] ?? '',
                      content: blog['content'] ?? blog['description'] ?? '',
                      readTime:
                          '${blog['time_to_read']?.toString() ?? blog['readTime'] ?? ''} min',
                      publishedAt:
                          (blog['created_at']?.toString().split('T')[0]) ??
                          blog['publishedAt'] ?? '',
                      isHorizontal: true,
                      isRead: isRead,
                      onTap: () => widget.onCardTap?.call(blog),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                ),
              )
            : ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: widget.blogPosts.length,
                itemBuilder: (context, index) {
                  final blog = widget.blogPosts[index];
                  final isRead = _readBlogIds.contains(blog['id']);
                  
                  return BlogCard(
                    title: blog['title'] ?? '',
                    coverImageUrl:
                        blog['coverImageUrl'] ?? blog['cover_image_url'] ?? '',
                    content: blog['content'] ?? blog['description'] ?? '',
                    readTime:
                        '${blog['time_to_read']?.toString() ?? blog['readTime'] ?? ''} min',
                    publishedAt:
                        (blog['created_at']?.toString().split('T')[0]) ??
                        blog['publishedAt'] ?? '',
                    isHorizontal: false,
                    isRead: isRead,
                    onTap: () => widget.onCardTap?.call(blog),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
              ),
      ],
    );
  }
}
