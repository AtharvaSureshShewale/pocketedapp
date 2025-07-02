// lib/pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:pocketed/auth/auth_service.dart';
import 'package:pocketed/pages/courses/available_courses_list.dart';
import 'package:pocketed/pages/courses/enrolled_courses_list.dart';
import 'package:pocketed/services/course_service.dart';
import 'package:pocketed/widgets/shared_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService authService = AuthService();
  final CourseService courseService = CourseService();

  String _username = 'Loading...';
  bool _isLoading = true;

  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _enrolledCourses = [];

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final username = await authService.getCurrentUsername();

      if (userId == null) return;

      final enrolled = await courseService.getEnrolledCoursesWithProgress(userId);
      final all = await courseService.getAllCourses();

      if (!mounted) return;

      setState(() {
        _username = username ?? 'User';
        _allCourses = all;
        _enrolledCourses = enrolled;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  void logout() async {
    try {
      await authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = authService.getCurrentUserEmail();

    return SharedScaffold(
      currentRoute: '/home',
      showNavbar: true,
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadAllData,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, $_username!',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Email: ${userEmail ?? "Not available"}'),
                        const SizedBox(height: 24),
                        if (_enrolledCourses.isNotEmpty) ...[
                          const Text('Your Enrolled Courses',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          EnrolledCoursesList(enrolledCourses: _enrolledCourses),
                        ] else ...[
                          const Text('Available Courses',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          AvailableCoursesList(allCourses: _allCourses),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
