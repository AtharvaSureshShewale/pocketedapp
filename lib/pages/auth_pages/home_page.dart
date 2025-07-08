import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pocketed/auth/auth_service.dart';
import 'package:pocketed/pages/blogs/blogs_section.dart';
import 'package:pocketed/pages/courses/available_courses_list.dart';
import 'package:pocketed/pages/courses/enrolled_courses_list.dart';
import 'package:pocketed/services/course_service.dart';
import 'package:pocketed/services/supabase_service.dart';
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
  String _userEmail = '';
  bool _isLoading = true;

  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _enrolledCourses = [];
  List<Map<String, dynamic>> _blogs = [];

  List<Map<String, dynamic>> blogs = [];
  bool isLoading = true;

  Future<void> fetchBlogs() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('blogs')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        blogs = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching blogs: $e');
      setState(() => isLoading = false);
    }
  }

  int _points = 0;

  StreamSubscription<List<Map<String, dynamic>>>? _pointsSubscription;

  @override
  void initState() {
    super.initState();
    loadAllData();
    fetchBlogs();
    _listenToPoints();
  }

  @override
  void dispose() {
    _pointsSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadAllData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final userId = user.id;
      final username = await authService.getCurrentUsername();
      final email = user.email ?? '';

      final enrolled = await courseService.getEnrolledCoursesWithProgress(
        userId,
      );
      final all = await courseService.getAllCourses();

      final blogs = await Supabase.instance.client
          .from('blogs')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false);

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('points')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _username = username ?? 'User';
        _userEmail = email;
        _allCourses = all;
        _enrolledCourses = enrolled;
        _blogs = blogs;
        _points = profile?['points'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  void _listenToPoints() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _pointsSubscription = Supabase.instance.client
        .from('profiles:id=eq.$userId')
        .stream(primaryKey: ['id'])
        .listen((event) {
          if (event.isNotEmpty) {
            setState(() {
              _points = event.first['points'] ?? 0;
            });
          }
        });
  }

  void logout() async {
    try {
      await authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        // 👋 Welcome and Email
                        Text(
                          'Welcome, $_username!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Email: $_userEmail'),

                        // 🌟 Points
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber),
                            const SizedBox(width: 6),
                            Text(
                              'Points: $_points',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // 📚 Courses
                        if (_enrolledCourses.isNotEmpty) ...[
                          const Text(
                            'Your Enrolled Courses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          EnrolledCoursesList(
                            enrolledCourses: _enrolledCourses,
                          ),
                        ] else ...[
                          const Text(
                            'Available Courses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AvailableCoursesList(allCourses: _allCourses),
                        ],

                        const SizedBox(height: 32),

                        // 📝 Blogs
                        const Text(
                          'Latest Blogs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        BlogSection(
                          blogPosts: blogs,
                          isHorizontal: true,
                          onCardTap: (blog) async {
                            Navigator.pushNamed(
                              context,
                              '/blogDetails',
                              arguments: blog,
                            );
                            setState(() {
                              final index = blogs.indexWhere(
                                (b) => b['id'] == blog['id'],
                              );
                              if (index != -1) blogs[index]['isRead'] = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
