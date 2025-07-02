import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseDetailPage extends StatelessWidget {
  final Map<String, dynamic> course;

  const CourseDetailPage({super.key, required this.course});

  Future<void> _handleEnroll(BuildContext context) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to enroll.')),
      );
      return;
    }

    final userId = user.id;
    final courseId = course['id'];

    try {
      // Optional: check if already enrolled
      final existing = await client
          .from('enrollments')
          .select()
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are already enrolled in this course.'),
          ),
        );
        return;
      }

      // Step 1: Insert enrollment and get ID
      final enrollmentInsertResponse = await client
          .from('enrollments')
          .insert({'user_id': userId, 'course_id': courseId})
          .select()
          .single();

      final enrollmentId = enrollmentInsertResponse['id'];

      // Step 2: Insert progress for the enrollment
      await client.from('progress').insert({
        'enrollment_id': enrollmentId,
        'progress_percent': 0,
      });

      // Show confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🎉 Congratulations!'),
          content: const Text('Thank you for enrolling in this course.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Close CourseDetailPage
              },
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Enrollment failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(course['title'] ?? 'Course Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (course['image'] != null &&
                course['image'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  course['image'],
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              course['title'] ?? '',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Instructor: ${course['instructor'] ?? ''}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text('Duration: ${course['duration'] ?? ''}'),
            const SizedBox(height: 4),
            Text('Mode: ${course['mode'] ?? ''}'),
            const SizedBox(height: 16),
            Text(
              course['description'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _handleEnroll(context),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Enroll Now'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
