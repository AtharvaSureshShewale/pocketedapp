import 'package:flutter/material.dart';
import 'blog_card.dart';

class BlogSection extends StatelessWidget {
  final List<Map<String, dynamic>> blogPosts;
  final bool isHorizontal;

  const BlogSection({
    super.key,
    required this.blogPosts,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        isHorizontal
            ? SizedBox(
                height: 280,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: blogPosts.length,
                  itemBuilder: (context, index) {
                    final blog = blogPosts[index];
                    return BlogCard(
                      title: blog['title'] ?? '',
                      coverImageUrl:
                          blog['coverImageUrl'] ??
                          blog['cover_image_url'] ??
                          '',
                      content: blog['content'] ?? blog['description'] ?? '',
                      readTime:
                          '${blog['time_to_read']?.toString() ?? blog['readTime'] ?? ''} min',
                      publishedAt:
                          (blog['created_at']?.toString().split('T')[0]) ??
                          blog['publishedAt'] ??
                          '',
                      isHorizontal: true,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/blogDetail',
                          arguments: blog,
                        );
                      },
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                ),
              )
            : ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: blogPosts.length,
                itemBuilder: (context, index) {
                  final blog = blogPosts[index];
                  return BlogCard(
                    title: blog['title'] ?? '',
                    coverImageUrl:
                        blog['coverImageUrl'] ?? blog['cover_image_url'] ?? '',
                    content: blog['content'] ?? blog['description'] ?? '',
                    readTime:
                        '${blog['time_to_read']?.toString() ?? blog['readTime'] ?? ''} min',
                    publishedAt:
                        (blog['created_at']?.toString().split('T')[0]) ??
                        blog['publishedAt'] ??
                        '',
                    isHorizontal: false,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/blogDetail',
                        arguments: blog,
                      );
                    },
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
              ),
      ],
    );
  }
}
