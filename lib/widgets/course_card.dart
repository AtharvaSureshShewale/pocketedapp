import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final String title;
  final String instructor;
  final String imageUrl;
  final String duration;
  final String mode;
  final String description;
  final bool isHorizontal;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.title,
    required this.instructor,
    required this.imageUrl,
    required this.duration,
    required this.mode,
    required this.description,
    this.isHorizontal = false,
    this.onTap,
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
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    imageUrl,
                    height: 140,
                    width: width,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(height: 140, child: Center(child: Icon(Icons.broken_image))),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Instructor: $instructor', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('Duration: $duration | Mode: $mode'),
                    const SizedBox(height: 8),
                    Text(description, maxLines: 3, overflow: TextOverflow.ellipsis),
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
