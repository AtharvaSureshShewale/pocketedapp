// lib/pages/home/course_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getEnrolledCoursesWithProgress(String userId) async {
    final enrollments = await supabase
        .from('enrollments')
        .select('id, course_id, courses(*)')
        .eq('user_id', userId);

    final enrollmentIds = enrollments.map((e) => e['id'] as String).toList();

    final progressList = await supabase
        .from('progress')
        .select('enrollment_id, progress_percent')
        .inFilter('enrollment_id', enrollmentIds);

    final progressMap = {
      for (var p in progressList) p['enrollment_id']: p,
    };

    final enriched = enrollments.map((e) {
      final progress = progressMap[e['id']] ?? {'progress_percent': 0};
      return {
        ...e,
        'progress': progress,
      };
    }).toList();

    return List<Map<String, dynamic>>.from(enriched);
  }

  Future<List<Map<String, dynamic>>> getAllCourses() async {
    final courses = await supabase.from('courses').select();
    return List<Map<String, dynamic>>.from(courses);
  }
}
