// lib/pages/home/enrolled_courses_list.dart
import 'package:flutter/material.dart';
import 'package:pocketed/pages/courses/course_detail_page.dart';

class EnrolledCoursesList extends StatelessWidget {
  final List<Map<String, dynamic>> enrolledCourses;

  const EnrolledCoursesList({super.key, required this.enrolledCourses});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: enrolledCourses.map((enrollment) {
        final course = enrollment['courses'] ?? {};
        final progress = enrollment['progress'] ?? {'progress_percent': 0};
        final progressValue = (progress['progress_percent'] ?? 0).toDouble();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailPage(course: course),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course['title'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progressValue / 100,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text('${progressValue.toInt()}% completed',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
