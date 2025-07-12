import 'package:flutter/material.dart';
import 'package:pocketed/models/quiz_models.dart';
import 'package:pocketed/services/quiz_service.dart' as quiz_service;
import 'package:pocketed/widgets/shared_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyQuizPage extends StatefulWidget {
  const DailyQuizPage({super.key});

  @override
  State<DailyQuizPage> createState() => _DailyQuizPageState();
}

class _DailyQuizPageState extends State<DailyQuizPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _quizProgression = [];
  int _currentDay = 1;

  @override
  void initState() {
    super.initState();
    _loadQuizProgression();
    _initializeAutomatedQuizGeneration();
  }

  Future<void> _initializeAutomatedQuizGeneration() async {
    try {
      await quiz_service.initializeAutomatedQuizGeneration();
      // Reload progression after potential quiz generation
      _loadQuizProgression();
    } catch (e) {
      print('Error initializing automated quiz generation: $e');
    }
  }

  Future<void> _loadQuizProgression() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final progression = await quiz_service.getUserQuizProgression();
      final currentDay = await quiz_service.getUserCurrentDay();

      setState(() {
        _quizProgression = progression;
        _currentDay = currentDay;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load quiz progression: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startQuiz(Map<String, dynamic> quizData) {
    final quiz = quizData['quiz'];
    if (quiz != null) {
      Navigator.pushNamed(
        context,
        '/quiz/questions',
        arguments: {'quiz': Quiz.fromJson(quiz)},
      ).then((_) {
        // Reload progression when returning from quiz
        _loadQuizProgression();
      });
    }
  }

  void _viewScoreboard() {
    Navigator.pushNamed(context, '/quiz/scoreboard');
  }
  


  @override
  Widget build(BuildContext context) {
    return SharedScaffold(
      currentRoute: '/quiz',
      appBar: AppBar(
        title: const Text('Daily Quizzes'),
      ),
      showNavbar: true,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuizProgression,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_quizProgression.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No Quizzes Available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('There are no quizzes available yet. Check back later!'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuizProgression,
              child: const Text('Refresh'),
            ),

          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            'Daily Quizzes',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your Progress: Day $_currentDay',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildScoreboardButton(),
          const SizedBox(height: 20),
          Expanded(
            child: _buildQuizProgressionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboardButton() {
    return ElevatedButton(
      onPressed: _viewScoreboard,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F1729),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Score Board',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuizProgressionList() {
    return ListView.builder(
      itemCount: _quizProgression.length,
      itemBuilder: (context, index) {
        final quizData = _quizProgression[index];
        return _buildQuizCard(quizData);
      },
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quizData) {
    final quiz = quizData['quiz'];
    final dayNumber = quizData['dayNumber'] as int;
    final isCompleted = quizData['isCompleted'] as bool;
    final isCurrentDay = quizData['isCurrentDay'] as bool;
    final isLocked = quizData['isLocked'] as bool;
    final isAvailable = quizData['isAvailable'] as bool;
    final score = quizData['score'] as int;

    final title = quiz['title'] ?? 'Quiz Day $dayNumber';
    final description = quiz['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCardColor(isCompleted, isCurrentDay, isLocked),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(isCompleted, isCurrentDay, isLocked),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getDayBadgeColor(isCompleted, isCurrentDay, isLocked),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Day $dayNumber',
                  style: TextStyle(
                    color: _getDayBadgeTextColor(isCompleted, isCurrentDay, isLocked),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isCurrentDay && !isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'CURRENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LOCKED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getTextColor(isCompleted, isCurrentDay, isLocked),
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: _getTextColor(isCompleted, isCurrentDay, isLocked).withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isCompleted)
                Text(
                  'Score: $score',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              else if (isLocked)
                const Text(
                  'Complete previous days to unlock',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                )
              else
                const Text(
                  'Ready to start!',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              if (isAvailable && !isCompleted)
                ElevatedButton(
                  onPressed: () => _startQuiz(quizData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Start Quiz'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                )
              else if (isCompleted)
                ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[100],
                    foregroundColor: Colors.green[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16),
                      SizedBox(width: 4),
                      Text('Completed'),
                    ],
                  ),
                )
              else if (isLocked)
                ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 16),
                      SizedBox(width: 4),
                      Text('Locked'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCardColor(bool isCompleted, bool isCurrentDay, bool isLocked) {
    if (isCompleted) return Colors.green[50]!;
    if (isCurrentDay) return Colors.blue[50]!;
    if (isLocked) return Colors.grey[50]!;
    return Colors.white;
  }

  Color _getBorderColor(bool isCompleted, bool isCurrentDay, bool isLocked) {
    if (isCompleted) return Colors.green;
    if (isCurrentDay) return Colors.blue;
    if (isLocked) return Colors.grey;
    return Colors.grey[300]!;
  }

  Color _getDayBadgeColor(bool isCompleted, bool isCurrentDay, bool isLocked) {
    if (isCompleted) return Colors.green;
    if (isCurrentDay) return Colors.blue;
    if (isLocked) return Colors.grey;
    return Colors.blue;
  }

  Color _getDayBadgeTextColor(bool isCompleted, bool isCurrentDay, bool isLocked) {
    return Colors.white;
  }

  Color _getTextColor(bool isCompleted, bool isCurrentDay, bool isLocked) {
    if (isLocked) return Colors.grey[600]!;
    return Colors.black87;
  }
} 