import 'package:flutter/material.dart';

class BlogCard extends StatelessWidget {
  final String title;
  final String coverImageUrl;
  final String readTime;
  final String publishedAt;
  final bool isHorizontal;
  final String content;
  final VoidCallback? onTap;
  final bool isRead;

  const BlogCard({
    super.key,
    required this.title,
    required this.coverImageUrl,
    required this.readTime,
    required this.publishedAt,
    this.isHorizontal = false,
    this.onTap,
    this.content = '',
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = isHorizontal ? 260.0 : double.infinity;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            SizedBox(
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
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 12),
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
                        Row(
                          children: [
                            Text(
                              '🕒 $readTime • 📅 $publishedAt',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Spacer(),
                            if (isRead)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'READ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Read indicator overlay on image
            if (isRead && coverImageUrl.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
