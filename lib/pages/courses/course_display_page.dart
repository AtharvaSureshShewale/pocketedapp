// lib/pages/courses/course_display_page.dart

import 'package:flutter/material.dart';
import 'package:pocketed/widgets/shared_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pocketed/widgets/course_card.dart';
import 'package:pocketed/pages/courses/course_detail_page.dart';

class CourseDisplayPage extends StatefulWidget {
  const CourseDisplayPage({super.key});

  @override
  State<CourseDisplayPage> createState() => _CourseDisplayPageState();
}

class _CourseDisplayPageState extends State<CourseDisplayPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _courses = [];
  Set<String> _enrolledCourseIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Fetch all courses
      final courses = await supabase.from('courses').select();

      // Fetch enrolled course_ids
      final enrollments = await supabase
          .from('enrollments')
          .select('course_id')
          .eq('user_id', userId);

      final enrolledIds = {
        for (var e in enrollments) e['course_id'] as String,
      };

      if (!mounted) return;

      setState(() {
        _courses = List<Map<String, dynamic>>.from(courses);
        _enrolledCourseIds = enrolledIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading courses: $e')),
      );
    }
  }
@override
Widget build(BuildContext context) {
  return SharedScaffold(
    currentRoute: '/courses',
    showNavbar: true,
    appBar: AppBar(
      title: const Text("All Courses"),
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                final isEnrolled = _enrolledCourseIds.contains(course['id']);

                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CourseCard(
                        title: course['title'] ?? '',
                        instructor: course['instructor'] ?? '',
                        imageUrl: course['image'] ?? '',
                        duration: course['duration'] ?? '',
                        mode: course['mode'] ?? '',
                        description: course['description'] ?? '',
                        isHorizontal: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseDetailPage(course: course),
                            ),
                          );
                        },
                      ),
                    ),
                    if (isEnrolled)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Enrolled',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
  );
}
}