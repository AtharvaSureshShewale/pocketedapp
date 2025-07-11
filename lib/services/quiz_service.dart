import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pocketed/utils/constant.dart';
import 'package:pocketed/models/quiz_models.dart';

final supabase = Supabase.instance.client;

/*
Database Schema for Quiz Feature:

1. quizzes Table:
   - id (primary key, auto-increment)
   - title (text, not null)
   - description (text)
   - day_number (integer, not null)
   - points_per_question (integer, not null)
   - created_at (timestamp with timezone, default: now())
   - is_active (boolean, default: true)

2. quiz_questions Table:
   - id (primary key, auto-increment)
   - quiz_id (foreign key references quizzes.id)
   - question_text (text, not null)
   - option_a (text, not null)
   - option_b (text, not null)
   - option_c (text, not null)
   - option_d (text, not null)
   - correct_option (text, not null) - stores 'A', 'B', 'C', or 'D'
   - points (integer, default: 10)
   - created_at (timestamp with timezone, default: now())

3. user_quiz_attempts Table:
   - id (primary key, auto-increment)
   - user_id (foreign key references auth.users.id)
   - quiz_id (foreign key references quizzes.id)
   - score (integer, default: 0)
   - completed (boolean, default: false)
   - started_at (timestamp with timezone, default: now())
   - completed_at (timestamp with timezone, nullable)

4. user_quiz_answers Table:
   - id (primary key, auto-increment)
   - attempt_id (foreign key references user_quiz_attempts.id)
   - question_id (foreign key references quiz_questions.id)
   - selected_option (text) - stores 'A', 'B', 'C', or 'D'
   - is_correct (boolean)
   - points_earned (integer)
   - created_at (timestamp with timezone, default: now())

5. quiz_leaderboard Table:
   - id (primary key, auto-increment)
   - user_id (foreign key references auth.users.id)
   - total_score (integer, default: 0)
   - quizzes_completed (integer, default: 0)
   - last_quiz_date (timestamp with timezone, nullable)
   - created_at (timestamp with timezone, default: now())
   - updated_at (timestamp with timezone, default: now())
*/

/// Fetch active daily quiz
Future<Quiz?> fetchDailyQuiz() async {
  try {
    // Get the most recent active quiz
    final response = await supabase
        .from('quizzes')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1);
    
    if (response.isEmpty) {
      return null;
    }
    
    return Quiz.fromJson(response.first);
  } catch (e) {
    print('Error fetching daily quiz: $e');
    return null;
  }
}

/// Fetch questions for a specific quiz
Future<List<QuizQuestion>> fetchQuizQuestions(int quizId) async {
  final response = await supabase
      .from('quiz_questions')
      .select()
      .eq('quiz_id', quizId)
      .order('id');
  
  return List<Map<String, dynamic>>.from(response)
      .map((json) => QuizQuestion.fromJson(json))
      .toList();
}

/// Create a new quiz attempt
Future<int> createQuizAttempt(int quizId) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('User not authenticated');
  
  final response = await supabase
      .from('user_quiz_attempts')
      .insert({
        'user_id': userId,
        'quiz_id': quizId,
        'started_at': DateTime.now().toIso8601String(),
      })
      .select('id')
      .single();
  
  return response['id'];
}

/// Save user's answer to a quiz question
Future<void> saveQuizAnswer({
  required int attemptId,
  required int questionId,
  required String selectedOption,
  required bool isCorrect,
  required int pointsEarned,
}) async {
  await supabase.from('user_quiz_answers').insert({
    'attempt_id': attemptId,
    'question_id': questionId,
    'selected_option': selectedOption,
    'is_correct': isCorrect,
    'points_earned': pointsEarned,
  });
}

/// Complete a quiz attempt and update score
Future<void> completeQuizAttempt(int attemptId, int totalScore) async {
  await supabase.from('user_quiz_attempts').update({
    'completed': true,
    'score': totalScore,
    'completed_at': DateTime.now().toIso8601String(),
  }).eq('id', attemptId);
  
  // Update leaderboard
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;
  
  // Check if user exists in leaderboard
  final existingUser = await supabase
      .from('quiz_leaderboard')
      .select()
      .eq('user_id', userId)
      .maybeSingle();
  
  if (existingUser != null) {
    // Update existing record
    await supabase.from('quiz_leaderboard').update({
      'total_score': existingUser['total_score'] + totalScore,
      'quizzes_completed': existingUser['quizzes_completed'] + 1,
      'last_quiz_date': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  } else {
    // Create new record
    await supabase.from('quiz_leaderboard').insert({
      'user_id': userId,
      'total_score': totalScore,
      'quizzes_completed': 1,
      'last_quiz_date': DateTime.now().toIso8601String(),
    });
  }
}

/// Get quiz results for an attempt
Future<Map<String, dynamic>> getQuizResults(int attemptId) async {
  final attemptResponse = await supabase
      .from('user_quiz_attempts')
      .select('*, quizzes(*)')
      .eq('id', attemptId)
      .single();
  
  final answersResponse = await supabase
      .from('user_quiz_answers')
      .select('*, quiz_questions(*)')
      .eq('attempt_id', attemptId);
  
  final attempt = QuizAttempt.fromJson(attemptResponse);
  final answers = List<Map<String, dynamic>>.from(answersResponse)
      .map((json) => QuizAnswer.fromJson(json))
      .toList();
  
  return {
    'attempt': attempt,
    'answers': answers,
  };
}

/// Fetch quiz leaderboard
Future<List<QuizLeaderboardEntry>> fetchQuizLeaderboard() async {
  try {
    // First get the leaderboard entries
    final leaderboardResponse = await supabase
        .from('quiz_leaderboard')
        .select()
        .order('total_score', ascending: false)
        .limit(100);
    
    // Create a list to store the enriched entries
    final enrichedEntries = <QuizLeaderboardEntry>[];
    
    // For each leaderboard entry, fetch the corresponding profile
    for (var entry in leaderboardResponse) {
      final userId = entry['user_id'];
      
      // Fetch the profile separately
      final profileResponse = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      // Add the profile to the entry
      final enrichedEntry = {
        ...entry,
        'profiles': profileResponse,
      };
      
      // Convert to model and add to list
      enrichedEntries.add(QuizLeaderboardEntry.fromJson(enrichedEntry));
    }
    
    return enrichedEntries;
  } catch (e) {
    // If there's an error, return an empty list rather than crashing
    print('Error fetching leaderboard: $e');
    return [];
  }
}

/// Extract JSON from a string that might contain markdown or other text
Map<String, dynamic> _extractJsonFromText(String text) {
  // Try to find JSON in the text
  final jsonPattern = RegExp(r'```(?:json)?\s*({[\s\S]*?})\s*```');
  final jsonMatch = jsonPattern.firstMatch(text);
  
  if (jsonMatch != null && jsonMatch.groupCount >= 1) {
    // Extract JSON from code block
    final jsonString = jsonMatch.group(1);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString);
      } catch (e) {
        // If parsing fails, fall back to other methods
      }
    }
  }
  
  // Try to find JSON without code blocks
  final jsonStartIndex = text.indexOf('{');
  final jsonEndIndex = text.lastIndexOf('}') + 1;
  
  if (jsonStartIndex != -1 && jsonEndIndex > jsonStartIndex) {
    final jsonString = text.substring(jsonStartIndex, jsonEndIndex);
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      // If parsing fails, return a default structure
      return {
        'title': 'Failed to parse quiz',
        'description': 'The AI generated an invalid response format.',
        'questions': [],
      };
    }
  }
  
  // If no JSON found, return default structure
  return {
    'title': 'Failed to parse quiz',
    'description': 'The AI generated an invalid response format.',
    'questions': [],
  };
}

/// Generate a new daily quiz using Gemini AI
Future<Map<String, dynamic>> generateDailyQuiz(String topic) async {
  // Initialize Gemini API
  final apiKey = AppText.GeminiApiKey;
  
  // If API key is not set or empty, return a mock quiz for testing
  if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') {
    return {
      'success': true,
      'message': 'Using mock quiz (no API key provided)',
      'data': _getMockQuiz(topic),
    };
  }
  
  try {
    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
    );
    
    // Create prompt for quiz generation - always focus on finance regardless of input topic
    final prompt = '''
    Generate a finance quiz with the following specifications:
    - Topic: Finance${topic.toLowerCase().contains('finance') ? ' - $topic' : ''}
    - Number of questions: 10
    - Format: Multiple choice with 4 options (A, B, C, D)
    - Each question should have only one correct answer
    - Include a brief description for the quiz
    
    The quiz MUST be focused on financial concepts, terminology, markets, investing, banking, or personal finance.
    
    Return the response in the following JSON format:
    ```json
    {
      "title": "Finance Quiz: [Specific Finance Topic]",
      "description": "Brief description of the finance quiz",
      "questions": [
        {
          "question_text": "Question 1 about finance",
          "option_a": "Option A",
          "option_b": "Option B",
          "option_c": "Option C",
          "option_d": "Option D",
          "correct_option": "A"
        },
        // more questions...
      ]
    }
    ```
    
    IMPORTANT: Make sure to return ONLY valid JSON in the format above. Do not include any explanatory text outside the JSON.
    ''';

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    final responseText = response.text;
    
    if (responseText == null || responseText.isEmpty) {
      throw Exception('Empty response from API');
    }
    
    // Extract and parse JSON from the response
    final quizData = _extractJsonFromText(responseText);
    
    // Validate the quiz data
    if (!_validateQuizData(quizData)) {
      throw Exception('Generated quiz data is invalid or incomplete');
    }
    
    return {
      'success': true,
      'message': 'Finance quiz generated successfully',
      'data': quizData,
    };
  } catch (e) {
    // Check for quota exceeded error
    final errorMessage = e.toString().toLowerCase();
    if (errorMessage.contains('quota') || 
        errorMessage.contains('exceeded') || 
        errorMessage.contains('limit') ||
        errorMessage.contains('rate')) {
      // Return mock quiz as fallback with clear message about rate limit
      return {
        'success': true,
        'message': 'API quota exceeded. Using mock finance quiz instead.',
        'data': _getMockQuiz(topic),
      };
    }
    
    // For other errors, also use mock quiz but with different message
    return {
      'success': true,
      'message': 'API error: ${e.toString()}. Using mock finance quiz instead.',
      'data': _getMockQuiz(topic),
    };
  }
}

/// Validate the quiz data structure
bool _validateQuizData(Map<String, dynamic> quizData) {
  if (!quizData.containsKey('title') || 
      !quizData.containsKey('description') || 
      !quizData.containsKey('questions')) {
    return false;
  }
  
  final questions = quizData['questions'];
  if (questions is! List || questions.isEmpty) {
    return false;
  }
  
  for (var question in questions) {
    if (question is! Map<String, dynamic> ||
        !question.containsKey('question_text') ||
        !question.containsKey('option_a') ||
        !question.containsKey('option_b') ||
        !question.containsKey('option_c') ||
        !question.containsKey('option_d') ||
        !question.containsKey('correct_option')) {
      return false;
    }
    
    final correctOption = question['correct_option'];
    if (correctOption is! String || 
        !['A', 'B', 'C', 'D'].contains(correctOption)) {
      return false;
    }
  }
  
  return true;
}

/// Get a mock quiz for testing when API key is not set
Map<String, dynamic> _getMockQuiz(String topic) {
  // Always return finance-related questions regardless of the topic
  return {
    'title': 'Finance Quiz',
    'description': 'Test your knowledge of financial concepts and terminology.',
    'questions': [
      {
        'question_text': 'What does ROI stand for in finance?',
        'option_a': 'Return On Investment',
        'option_b': 'Rate Of Inflation',
        'option_c': 'Risk Of Insolvency',
        'option_d': 'Revenue Over Income',
        'correct_option': 'A'
      },
      {
        'question_text': 'Which of the following is NOT a type of financial market?',
        'option_a': 'Stock Market',
        'option_b': 'Bond Market',
        'option_c': 'Commodity Market',
        'option_d': 'Velocity Market',
        'correct_option': 'D'
      },
      {
        'question_text': 'What is the term for the gradual decrease in the value of an asset?',
        'option_a': 'Appreciation',
        'option_b': 'Depreciation',
        'option_c': 'Inflation',
        'option_d': 'Amortization',
        'correct_option': 'B'
      },
      {
        'question_text': 'What is a bull market?',
        'option_a': 'A market where prices are falling',
        'option_b': 'A market where prices are rising',
        'option_c': 'A market with high volatility',
        'option_d': 'A market dominated by agricultural commodities',
        'correct_option': 'B'
      },
      {
        'question_text': 'What is the primary purpose of a 401(k) plan?',
        'option_a': 'Short-term savings',
        'option_b': 'Education funding',
        'option_c': 'Retirement savings',
        'option_d': 'Emergency fund',
        'correct_option': 'C'
      },
      {
        'question_text': 'What does P/E ratio stand for in stock valuation?',
        'option_a': 'Profit/Earnings',
        'option_b': 'Price/Earnings',
        'option_c': 'Potential/Equity',
        'option_d': 'Performance/Efficiency',
        'correct_option': 'B'
      },
      {
        'question_text': 'Which of these is considered a liability?',
        'option_a': 'Cash',
        'option_b': 'Inventory',
        'option_c': 'Mortgage',
        'option_d': 'Accounts Receivable',
        'correct_option': 'C'
      },
      {
        'question_text': 'What is diversification in investing?',
        'option_a': 'Buying only blue-chip stocks',
        'option_b': 'Spreading investments across various assets',
        'option_c': 'Investing only in government bonds',
        'option_d': 'Focusing on a single industry',
        'correct_option': 'B'
      },
      {
        'question_text': 'What is the term for money borrowed that must be repaid with interest?',
        'option_a': 'Equity',
        'option_b': 'Revenue',
        'option_c': 'Debt',
        'option_d': 'Dividend',
        'correct_option': 'C'
      },
      {
        'question_text': 'What is compound interest?',
        'option_a': 'Interest calculated only on the principal amount',
        'option_b': 'Interest calculated on both principal and accumulated interest',
        'option_c': 'Interest paid at a fixed rate regardless of market conditions',
        'option_d': 'Interest that decreases over time',
        'correct_option': 'B'
      }
    ]
  };
}

/// Save a generated quiz to the database
Future<int> saveGeneratedQuiz(Map<String, dynamic> quizData) async {
  // Extract quiz data
  final title = quizData['title'];
  final description = quizData['description'];
  final questions = quizData['questions'] as List;
  
  // Get the latest day number
  final latestQuiz = await supabase
      .from('quizzes')
      .select('day_number')
      .order('day_number', ascending: false)
      .limit(1)
      .maybeSingle();
  
  final dayNumber = latestQuiz != null ? latestQuiz['day_number'] + 1 : 1;
  
  // Deactivate all existing quizzes to ensure only one is active
  await supabase
      .from('quizzes')
      .update({'is_active': false})
      .eq('is_active', true);
  
  // Insert quiz
  final quizResponse = await supabase
      .from('quizzes')
      .insert({
        'title': title,
        'description': description,
        'day_number': dayNumber,
        'points_per_question': 10,
        'is_active': true,
      })
      .select('id')
      .single();
  
  final quizId = quizResponse['id'];
  
  // Insert questions
  for (var question in questions) {
    await supabase.from('quiz_questions').insert({
      'quiz_id': quizId,
      'question_text': question['question_text'],
      'option_a': question['option_a'],
      'option_b': question['option_b'],
      'option_c': question['option_c'],
      'option_d': question['option_d'],
      'correct_option': question['correct_option'],
      'points': 10,
    });
  }
  
  return quizId;
} 