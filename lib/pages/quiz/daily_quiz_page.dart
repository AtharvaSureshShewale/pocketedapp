import 'package:flutter/material.dart';
import 'package:pocketed/models/quiz_models.dart';
import 'package:pocketed/services/quiz_service.dart';
import 'package:pocketed/widgets/shared_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyQuizPage extends StatefulWidget {
  const DailyQuizPage({super.key});

  @override
  State<DailyQuizPage> createState() => _DailyQuizPageState();
}

class _DailyQuizPageState extends State<DailyQuizPage> {
  bool _isLoading = true;
  Quiz? _dailyQuiz;
  String? _errorMessage;
  bool _hasCompletedQuiz = false;
  int _userScore = 0;

  @override
  void initState() {
    super.initState();
    _loadDailyQuiz();
  }

  Future<void> _loadDailyQuiz() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final quiz = await fetchDailyQuiz();
      
      // Check if user has completed this quiz
      if (quiz != null) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final attempt = await Supabase.instance.client
              .from('user_quiz_attempts')
              .select('id, score, completed')
              .eq('user_id', userId)
              .eq('quiz_id', quiz.id)
              .eq('completed', true)
              .maybeSingle();
          
          if (attempt != null) {
            setState(() {
              _hasCompletedQuiz = true;
              _userScore = attempt['score'] ?? 0;
            });
          }
        }
      }
      
      setState(() {
        _dailyQuiz = quiz;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load daily quiz: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startQuiz() {
    if (_dailyQuiz != null) {
      Navigator.pushNamed(
        context,
        '/quiz/questions',
        arguments: {'quiz': _dailyQuiz},
      ).then((_) {
        // Reload quiz data when returning from the quiz
        _loadDailyQuiz();
      });
    }
  }

  void _viewScoreboard() {
    Navigator.pushNamed(context, '/quiz/scoreboard');
  }
  
  void _goToAdminPage() {
    Navigator.pushNamed(context, '/quiz/admin');
  }

  void _deleteQuiz() async {
    if (_dailyQuiz == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      // Delete the quiz
      await Supabase.instance.client
          .from('quizzes')
          .delete()
          .eq('id', _dailyQuiz!.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz deleted successfully')),
      );
      
      // Reload
      _loadDailyQuiz();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to delete quiz: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedScaffold(
      currentRoute: '/quiz',
      appBar: AppBar(
        title: const Text('Daily Quiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: _goToAdminPage,
            tooltip: 'Admin Panel',
          ),
          if (_dailyQuiz != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteQuiz,
              tooltip: 'Delete Current Quiz',
            ),
        ],
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
              onPressed: _loadDailyQuiz,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_dailyQuiz == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No Quiz Available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('There is no active quiz today. Check back later!'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDailyQuiz,
              child: const Text('Refresh'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _goToAdminPage,
              child: const Text('Generate New Quiz (Admin)'),
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
            'Daily Quiz',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Task',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildScoreboardButton(),
          const SizedBox(height: 20),
          _buildQuizCard(),
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

  Widget _buildQuizCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Day ${_dailyQuiz!.dayNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 20, color: Colors.black),
              children: [
                TextSpan(
                  text: '${_dailyQuiz!.title.split(':').first}: ',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: _dailyQuiz!.title.contains(':') 
                      ? _dailyQuiz!.title.split(':').last.trim()
                      : '',
                  style: TextStyle(
                    color: Colors.amber[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Score: $_userScore',
                style: TextStyle(
                  color: _hasCompletedQuiz ? Colors.green[700] : Colors.grey[700],
                  fontWeight: _hasCompletedQuiz ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              ElevatedButton(
                onPressed: _hasCompletedQuiz ? null : _startQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasCompletedQuiz ? Colors.green[100] : Colors.white,
                  foregroundColor: _hasCompletedQuiz ? Colors.green[800] : Colors.blue[800],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _hasCompletedQuiz ? 'Completed' : 'Quiz Start',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _hasCompletedQuiz ? Colors.green[800] : Colors.blue[800],
                      ),
                    ),
                    if (!_hasCompletedQuiz)
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.blue[800],
                        size: 16,
                      ),
                    if (_hasCompletedQuiz)
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[800],
                        size: 16,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 