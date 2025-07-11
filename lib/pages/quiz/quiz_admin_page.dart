import 'package:flutter/material.dart';
import 'package:pocketed/services/quiz_service.dart';
import 'package:pocketed/widgets/shared_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizAdminPage extends StatefulWidget {
  const QuizAdminPage({super.key});

  @override
  State<QuizAdminPage> createState() => _QuizAdminPageState();
}

class _QuizAdminPageState extends State<QuizAdminPage> {
  final _topicController = TextEditingController();
  bool _isGenerating = false;
  String? _resultMessage;
  bool _isSuccess = false;
  bool _isWarning = false;
  bool _isDeletingQuizzes = false;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generateQuiz() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      setState(() {
        _resultMessage = 'Please enter a topic';
        _isSuccess = false;
        _isWarning = false;
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _resultMessage = 'Generating quiz for topic: $topic...';
      _isSuccess = false;
      _isWarning = false;
    });

    try {
      // Generate quiz using Gemini API
      final result = await generateDailyQuiz(topic);
      
      if (result['success'] == true && result['data'] != null) {
        // Check if this is a fallback mock quiz due to API error
        final bool isFallback = result['message'].toString().contains('mock quiz');
        
        // Save the generated quiz to the database
        final quizId = await saveGeneratedQuiz(result['data']);
        
        setState(() {
          _resultMessage = result['message'] + (isFallback ? '' : ' Quiz ID: $quizId');
          _isSuccess = true;
          _isWarning = isFallback; // Set warning flag if using fallback
          _isGenerating = false;
        });
      } else {
        setState(() {
          _resultMessage = 'Failed to generate quiz: ${result['message']}';
          _isSuccess = false;
          _isWarning = false;
          _isGenerating = false;
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Error: ${e.toString()}';
        _isSuccess = false;
        _isWarning = false;
        _isGenerating = false;
      });
    }
  }
  
  Future<void> _deleteAllQuizzes() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Quizzes'),
        content: const Text(
          'This will delete ALL quizzes and their related data. This action cannot be undone. Are you sure?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isDeletingQuizzes = true;
      _resultMessage = 'Deleting all quizzes...';
      _isSuccess = false;
      _isWarning = false;
    });
    
    try {
      // Delete all quizzes (cascade will delete questions, attempts, answers)
      await Supabase.instance.client.from('quizzes').delete().neq('id', 0);
      
      setState(() {
        _resultMessage = 'All quizzes deleted successfully';
        _isSuccess = true;
        _isDeletingQuizzes = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Error deleting quizzes: ${e.toString()}';
        _isSuccess = false;
        _isDeletingQuizzes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedScaffold(
      currentRoute: '/quiz/admin',
      appBar: AppBar(
        title: const Text('Quiz Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _isDeletingQuizzes ? null : _deleteAllQuizzes,
            tooltip: 'Delete All Quizzes',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Generate Daily Quiz',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Quiz Topic',
                hintText: 'Enter a topic for the quiz (e.g., "Finance", "Investing")',
                border: OutlineInputBorder(),
              ),
              enabled: !_isGenerating && !_isDeletingQuizzes,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_isGenerating || _isDeletingQuizzes) ? null : _generateQuiz,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: _isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Generating...'),
                      ],
                    )
                  : const Text('Generate Finance Quiz'),
            ),
            if (_resultMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess 
                      ? (_isWarning ? Colors.amber[50] : Colors.green[50])
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess 
                        ? (_isWarning ? Colors.amber : Colors.green)
                        : Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _resultMessage!,
                      style: TextStyle(
                        color: _isSuccess 
                            ? (_isWarning ? Colors.amber[800] : Colors.green[800])
                            : Colors.red[800],
                      ),
                    ),
                    if (_isWarning) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Note: A mock quiz was generated instead of using the AI. The quiz is still usable but contains generic questions.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Note: This page is for administrators only. It allows you to generate a new daily quiz using the Gemini AI API. The generated quiz will be automatically saved to the database and made available to users. If the API quota is exceeded, a mock quiz will be generated instead.',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 