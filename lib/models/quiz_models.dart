class Quiz {
  final int id;
  final String title;
  final String description;
  final int dayNumber;
  final int pointsPerQuestion;
  final DateTime createdAt;
  final bool isActive;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.dayNumber,
    required this.pointsPerQuestion,
    required this.createdAt,
    required this.isActive,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dayNumber: json['day_number'],
      pointsPerQuestion: json['points_per_question'],
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'day_number': dayNumber,
      'points_per_question': pointsPerQuestion,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}

class QuizQuestion {
  final int id;
  final int quizId;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final int points;
  final DateTime createdAt;

  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    required this.points,
    required this.createdAt,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      quizId: json['quiz_id'],
      questionText: json['question_text'],
      optionA: json['option_a'],
      optionB: json['option_b'],
      optionC: json['option_c'],
      optionD: json['option_d'],
      correctOption: json['correct_option'],
      points: json['points'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': correctOption,
      'points': points,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class QuizAttempt {
  final int id;
  final String userId;
  final int quizId;
  final int score;
  final bool completed;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Quiz? quiz;

  QuizAttempt({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.score,
    required this.completed,
    required this.startedAt,
    this.completedAt,
    this.quiz,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      userId: json['user_id'],
      quizId: json['quiz_id'],
      score: json['score'],
      completed: json['completed'],
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      quiz: json['quizzes'] != null ? Quiz.fromJson(json['quizzes']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'quiz_id': quizId,
      'score': score,
      'completed': completed,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

class QuizAnswer {
  final int id;
  final int attemptId;
  final int questionId;
  final String selectedOption;
  final bool isCorrect;
  final int pointsEarned;
  final DateTime createdAt;
  final QuizQuestion? question;

  QuizAnswer({
    required this.id,
    required this.attemptId,
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
    required this.pointsEarned,
    required this.createdAt,
    this.question,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      id: json['id'],
      attemptId: json['attempt_id'],
      questionId: json['question_id'],
      selectedOption: json['selected_option'],
      isCorrect: json['is_correct'],
      pointsEarned: json['points_earned'],
      createdAt: DateTime.parse(json['created_at']),
      question: json['quiz_questions'] != null ? QuizQuestion.fromJson(json['quiz_questions']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'question_id': questionId,
      'selected_option': selectedOption,
      'is_correct': isCorrect,
      'points_earned': pointsEarned,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class QuizLeaderboardEntry {
  final int id;
  final String userId;
  final int totalScore;
  final int quizzesCompleted;
  final DateTime? lastQuizDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile? profile;

  QuizLeaderboardEntry({
    required this.id,
    required this.userId,
    required this.totalScore,
    required this.quizzesCompleted,
    this.lastQuizDate,
    required this.createdAt,
    required this.updatedAt,
    this.profile,
  });

  factory QuizLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return QuizLeaderboardEntry(
      id: json['id'],
      userId: json['user_id'],
      totalScore: json['total_score'],
      quizzesCompleted: json['quizzes_completed'],
      lastQuizDate: json['last_quiz_date'] != null ? DateTime.parse(json['last_quiz_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      profile: json['profiles'] != null ? UserProfile.fromJson(json['profiles']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_score': totalScore,
      'quizzes_completed': quizzesCompleted,
      'last_quiz_date': lastQuizDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class UserProfile {
  final String username;
  final String? avatarUrl;

  UserProfile({
    required this.username,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] ?? 'Anonymous',
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'avatar_url': avatarUrl,
    };
  }
} 