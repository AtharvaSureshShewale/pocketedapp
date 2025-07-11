import 'package:flutter/material.dart';
import 'package:pocketed/models/quiz_models.dart';
import 'package:pocketed/services/quiz_service.dart';
import 'package:pocketed/widgets/shared_scaffold.dart';

class QuizResultsPage extends StatefulWidget {
  final int attemptId;

  const QuizResultsPage({
    super.key,
    required this.attemptId,
  });

  @override
  State<QuizResultsPage> createState() => _QuizResultsPageState();
}

class _QuizResultsPageState extends State<QuizResultsPage> {
  bool _isLoading = true;
  QuizAttempt? _attempt;
  List<QuizAnswer> _answers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await getQuizResults(widget.attemptId);
      
      setState(() {
        _attempt = results['attempt'] as QuizAttempt;
        _answers = results['answers'] as List<QuizAnswer>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load quiz results: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _goToScoreboard() {
    Navigator.pushReplacementNamed(context, '/quiz/scoreboard');
  }

  void _goToHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/quiz',
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SharedScaffold(
      currentRoute: '/quiz/results',
      appBar: AppBar(
        title: const Text('Quiz Results'),
      ),
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
              onPressed: _loadResults,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_attempt == null || _attempt!.quiz == null) {
      return const Center(
        child: Text('No results available.'),
      );
    }

    final correctAnswers = _answers.where((answer) => answer.isCorrect).length;
    final totalQuestions = _answers.length;
    final percentage = totalQuestions > 0 
        ? (correctAnswers / totalQuestions * 100).round() 
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildResultSummary(correctAnswers, totalQuestions, percentage),
          const SizedBox(height: 24),
          _buildQuestionsList(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildResultSummary(int correct, int total, int percentage) {
    Color resultColor;
    String resultText;
    
    if (percentage >= 80) {
      resultColor = Colors.green;
      resultText = 'Excellent!';
    } else if (percentage >= 60) {
      resultColor = Colors.blue;
      resultText = 'Good Job!';
    } else if (percentage >= 40) {
      resultColor = Colors.orange;
      resultText = 'Not Bad!';
    } else {
      resultColor = Colors.red;
      resultText = 'Try Again!';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              resultText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(resultColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Score: ${_attempt!.score}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem(
                  Icons.check_circle,
                  Colors.green,
                  correct.toString(),
                  'Correct',
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  Icons.cancel,
                  Colors.red,
                  (total - correct).toString(),
                  'Wrong',
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  Icons.question_answer,
                  Colors.blue,
                  total.toString(),
                  'Total',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Questions Review',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_answers.length, (index) {
          final answer = _answers[index];
          final question = answer.question;
          
          if (question == null) {
            return const SizedBox.shrink();
          }
          
          return _buildQuestionItem(index, question, answer);
        }),
      ],
    );
  }

  Widget _buildQuestionItem(int index, QuizQuestion question, QuizAnswer answer) {
    final isCorrect = answer.isCorrect;
    final selectedOption = answer.selectedOption;
    final correctOption = question.correctOption;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCorrect ? Colors.green[300]! : Colors.red[300]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: isCorrect ? Colors.green[700] : Colors.red[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCorrect ? 'Correct' : 'Wrong',
                        style: TextStyle(
                          color: isCorrect ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Question ${index + 1}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAnswerOption('A', question.optionA, selectedOption, correctOption),
            _buildAnswerOption('B', question.optionB, selectedOption, correctOption),
            _buildAnswerOption('C', question.optionC, selectedOption, correctOption),
            _buildAnswerOption('D', question.optionD, selectedOption, correctOption),
            if (!isCorrect) ...[
              const SizedBox(height: 12),
              Text(
                'Correct answer: $correctOption',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Points: ${answer.pointsEarned}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOption(
    String label,
    String text,
    String selectedOption,
    String correctOption,
  ) {
    final isSelected = selectedOption == label;
    final isCorrect = correctOption == label;
    
    Color backgroundColor;
    Color borderColor;
    IconData? icon;
    Color? iconColor;
    
    if (isSelected && isCorrect) {
      backgroundColor = Colors.green[50]!;
      borderColor = Colors.green;
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (isSelected && !isCorrect) {
      backgroundColor = Colors.red[50]!;
      borderColor = Colors.red;
      icon = Icons.cancel;
      iconColor = Colors.red;
    } else if (!isSelected && isCorrect) {
      backgroundColor = Colors.green[50]!;
      borderColor = Colors.green;
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else {
      backgroundColor = Colors.white;
      borderColor = Colors.grey[300]!;
      icon = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected || isCorrect ? borderColor : Colors.grey[200],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected || isCorrect ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected || isCorrect 
                    ? borderColor 
                    : Colors.black87,
              ),
            ),
          ),
          if (icon != null)
            Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _goToHome,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.blue[700]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Back to Quizzes',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _goToScoreboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'View Scoreboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 