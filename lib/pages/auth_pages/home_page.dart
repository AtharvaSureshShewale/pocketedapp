import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pocketed/auth/auth_service.dart';
import 'package:pocketed/pages/blogs/blogs_section.dart';
import 'package:pocketed/pages/courses/available_courses_list.dart';
import 'package:pocketed/pages/courses/enrolled_courses_list.dart';
import 'package:pocketed/services/course_service.dart';
import 'package:pocketed/services/leaderboard_service.dart' as leaderboard;
import 'package:pocketed/services/quiz_service.dart' as quiz_service;
import 'package:pocketed/services/supabase_service.dart';
import 'package:pocketed/widgets/shared_scaffold.dart';
import 'package:pocketed/widgets/leaderboard_card.dart';
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
  
  // Leaderboard data
  List<leaderboard.MainLeaderboardEntry> _topLeaderboard = [];
  leaderboard.MainLeaderboardEntry? _currentUserEntry;
  int? _currentUserPosition;
  
  // Key for BlogSection to refresh read status
  final GlobalKey _blogSectionKey = GlobalKey();

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
  StreamSubscription<List<Map<String, dynamic>>>? _leaderboardSubscription;

  @override
  void initState() {
    super.initState();
    loadAllData();
    fetchBlogs();
    _listenToPoints();
    _listenToLeaderboard();
    _cleanupDuplicatesOnStart();
  }

  @override
  void dispose() {
    _pointsSubscription?.cancel();
    _leaderboardSubscription?.cancel();
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

      // Load leaderboard data
      print('🏠 Home page: Loading leaderboard data...');
      final leaderboardData = await leaderboard.fetchMainLeaderboard();
      print('🏠 Home page: Got ${leaderboardData.length} leaderboard entries');
      
      final currentUserEntry = await leaderboard.getCurrentUserEntry();
      final currentUserPosition = await leaderboard.getCurrentUserPosition();
      
      print('🏠 Home page: Current user entry: $currentUserEntry');
      print('🏠 Home page: Current user position: $currentUserPosition');

      if (!mounted) return;

      setState(() {
        _username = username ?? 'User';
        _userEmail = email;
        _allCourses = all;
        _enrolledCourses = enrolled;
        _blogs = blogs;
        _points = profile?['points'] ?? 0;
        _topLeaderboard = leaderboardData.take(5).toList(); // Top 5 only
        _currentUserEntry = currentUserEntry;
        _currentUserPosition = currentUserPosition;
        _isLoading = false;
      });
      
      print('🏠 Home page: Set top leaderboard with ${_topLeaderboard.length} entries');
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

  void _listenToLeaderboard() {
    print('🎧 Setting up leaderboard listener...');
    
    // Listen to changes in profiles table
    _leaderboardSubscription = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .listen((event) {
          print('🎧 Leaderboard data changed, refreshing...');
          loadAllData(); // Reload all data when leaderboard changes
        });
  }

  void _cleanupDuplicatesOnStart() async {
    // Clean up duplicates when the app starts
    await leaderboard.cleanupDuplicateLeaderboardEntries();
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

                        // 🏆 Leaderboard Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '🏆 Top Leaderboard',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/leaderboard');
                              },
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLeaderboardPreview(),

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
                          key: _blogSectionKey,
                          blogPosts: blogs,
                          isHorizontal: true,
                          onCardTap: (blog) async {
                            await Navigator.pushNamed(
                              context,
                              '/blogDetails',
                              arguments: blog,
                            );
                            // Refresh blog read status when returning from blog detail
                            if (_blogSectionKey.currentState != null) {
                              (_blogSectionKey.currentState as dynamic).refreshReadStatus();
                            }
                          },
                        ),

                        const SizedBox(height: 32),

                        // 🔧 Debug Tools
                        const Text(
                          '🔧 Debug Tools',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Leaderboard & Blog Tools',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        await leaderboard.initializeDatabase();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Database initialized')),
                                        );
                                      },
                                      child: const Text('Init DB'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await leaderboard.addTestData();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Test data added')),
                                        );
                                      },
                                      child: const Text('Add Test Data'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await leaderboard.syncLeaderboardData();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Leaderboard synced')),
                                        );
                                      },
                                      child: const Text('Sync Leaderboard'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await leaderboard.cleanupDuplicateLeaderboardEntries();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Duplicates cleaned')),
                                        );
                                      },
                                      child: const Text('Clean Duplicates'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await leaderboard.cleanupDuplicateBlogReads();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Blog duplicates cleaned')),
                                        );
                                      },
                                      child: const Text('Clean Blog Duplicates'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Quiz Progression Tools',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        final currentDay = await quiz_service.getUserCurrentDay();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Current day: $currentDay')),
                                        );
                                      },
                                      child: const Text('Check Current Day'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await quiz_service.updateUserCurrentDay(1);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Reset to Day 1')),
                                        );
                                      },
                                      child: const Text('Reset to Day 1'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final progression = await quiz_service.getUserQuizProgression();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Found ${progression.length} quizzes')),
                                        );
                                      },
                                      child: const Text('Check Progression'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await quiz_service.generateAutomatedDailyQuiz();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Generated new quiz')),
                                        );
                                      },
                                      child: const Text('Generate Quiz'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                      ),
      ),
    );
  }

  Widget _buildLeaderboardPreview() {
    print('🏆 Building leaderboard preview with ${_topLeaderboard.length} entries');
    
    if (_topLeaderboard.isEmpty) {
      print('🏆 No leaderboard data available');
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Text(
              'No leaderboard data yet',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                print('🔄 Manual refresh triggered');
                await loadAllData();
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _topLeaderboard.asMap().entries.map((entry) {
          final index = entry.key;
          final leaderboardEntry = entry.value;
          final position = index + 1;
          
          return LeaderboardCard(
            entry: leaderboardEntry,
            position: position,
            showDetails: false,
          );
        }).toList(),
      ),
    );
  }
}
