// lib/pages/home/available_courses_list.dart
import 'package:flutter/material.dart';
import 'package:pocketed/widgets/course_card.dart';
import 'package:pocketed/pages/courses/course_detail_page.dart';

class AvailableCoursesList extends StatelessWidget {
  final List<Map<String, dynamic>> allCourses;

  const AvailableCoursesList({super.key, required this.allCourses});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: allCourses.map((course) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CourseCard(
              title: course['title'] ?? '',
              instructor: course['instructor'] ?? '',
              imageUrl: course['image'] ?? '',
              duration: course['duration'] ?? '',
              mode: course['mode'] ?? '',
              description: course['description'] ?? '',
              isHorizontal: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailPage(course: course),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
