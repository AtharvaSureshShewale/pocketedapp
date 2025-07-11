import 'package:flutter/material.dart';
import 'package:pocketed/models/quiz_models.dart';
import 'package:pocketed/services/quiz_service.dart';

class QuizQuestionPage extends StatefulWidget {
  final Quiz quiz;

  const QuizQuestionPage({
    super.key,
    required this.quiz,
  });

  @override
  State<QuizQuestionPage> createState() => _QuizQuestionPageState();
}

class _QuizQuestionPageState extends State<QuizQuestionPage> {
  bool _isLoading = true;
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _attemptId = -1;
  int _totalScore = 0;
  final Map<int, String> _userAnswers = {};
  bool _answerSelected = false;
  String? _selectedOption;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load questions
      final questions = await fetchQuizQuestions(widget.quiz.id);
      
      // Create a new attempt
      final attemptId = await createQuizAttempt(widget.quiz.id);

      setState(() {
        _questions = questions;
        _attemptId = attemptId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load quiz questions: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(String option) {
    if (_answerSelected) return;

    setState(() {
      _selectedOption = option;
      _answerSelected = true;
    });

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = option == currentQuestion.correctOption;
    final pointsEarned = isCorrect ? currentQuestion.points : 0;

    // Save the answer
    _userAnswers[_currentQuestionIndex] = option;
    
    // Update total score
    if (isCorrect) {
      setState(() {
        _totalScore += pointsEarned;
      });
    }

    // Save answer to database
    saveQuizAnswer(
      attemptId: _attemptId,
      questionId: currentQuestion.id,
      selectedOption: option,
      isCorrect: isCorrect,
      pointsEarned: pointsEarned,
    );

    // Wait a moment to show the result before moving to next question
    Future.delayed(const Duration(seconds: 1), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _answerSelected = false;
          _selectedOption = null;
        });
      } else {
        _finishQuiz();
      }
    });
  }

  Future<void> _finishQuiz() async {
    try {
      await completeQuizAttempt(_attemptId, _totalScore);
      
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/quiz/results',
          arguments: {'attemptId': _attemptId},
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to complete quiz: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.quiz.title}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Future<void> _showExitConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context);
    }
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
              onPressed: _loadQuestions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_questions.isEmpty) {
      return const Center(
        child: Text('No questions available for this quiz.'),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    
    return Column(
      children: [
        _buildProgressBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuestionText(currentQuestion),
                const SizedBox(height: 24),
                _buildOptions(currentQuestion),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Score: $_totalScore',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionText(QuizQuestion question) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        question.questionText,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOptions(QuizQuestion question) {
    final options = [
      {'label': 'A', 'text': question.optionA},
      {'label': 'B', 'text': question.optionB},
      {'label': 'C', 'text': question.optionC},
      {'label': 'D', 'text': question.optionD},
    ];

    return Column(
      children: options.map((option) {
        final optionLabel = option['label'] as String;
        final optionText = option['text'] as String;
        final isSelected = _selectedOption == optionLabel;
        final isCorrect = question.correctOption == optionLabel;
        
        Color backgroundColor;
        Color borderColor;
        Color textColor;
        
        if (_answerSelected) {
          if (isSelected && isCorrect) {
            // Correct answer selected
            backgroundColor = Colors.green[50]!;
            borderColor = Colors.green;
            textColor = Colors.green[800]!;
          } else if (isSelected && !isCorrect) {
            // Wrong answer selected
            backgroundColor = Colors.red[50]!;
            borderColor = Colors.red;
            textColor = Colors.red[800]!;
          } else if (!isSelected && isCorrect) {
            // Correct answer not selected
            backgroundColor = Colors.green[50]!;
            borderColor = Colors.green;
            textColor = Colors.green[800]!;
          } else {
            // Not selected and not correct
            backgroundColor = Colors.white;
            borderColor = Colors.grey[300]!;
            textColor = Colors.black87;
          }
        } else {
          // Not answered yet
          backgroundColor = isSelected ? Colors.blue[50]! : Colors.white;
          borderColor = isSelected ? Colors.blue : Colors.grey[300]!;
          textColor = isSelected ? Colors.blue[800]! : Colors.black87;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: _answerSelected ? null : () => _selectAnswer(optionLabel),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _answerSelected && (isSelected || isCorrect)
                          ? borderColor
                          : Colors.grey[200],
                    ),
                    child: Text(
                      optionLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _answerSelected && (isSelected || isCorrect)
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      optionText,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (_answerSelected) 
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
} 