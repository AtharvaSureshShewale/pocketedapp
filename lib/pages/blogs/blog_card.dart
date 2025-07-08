import 'package:flutter/material.dart';

class BlogCard extends StatelessWidget {
  final String title;
  final String coverImageUrl;
  final String readTime;
  final String publishedAt;
  final bool isHorizontal;
  final String content;
  final VoidCallback? onTap;

  const BlogCard({
    super.key,
    required this.title,
    required this.coverImageUrl,
    required this.readTime,
    required this.publishedAt,
    this.isHorizontal = false,
    this.onTap,
    this.content = '',
  });

  @override
  Widget build(BuildContext context) {
    final width = isHorizontal ? 260.0 : double.infinity;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (coverImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    coverImageUrl,
                    height: 140,
                    width: width,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(height: 140, child: Center(child: Icon(Icons.broken_image))),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🕒 $readTime • 📅 $publishedAt',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
