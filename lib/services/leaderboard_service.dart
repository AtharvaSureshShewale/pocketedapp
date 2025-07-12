import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class MainLeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int profilePoints;
  final int quizScore;
  final int totalScore;
  final int quizzesCompleted;
  final DateTime? lastQuizDate;

  MainLeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.profilePoints,
    required this.quizScore,
    required this.totalScore,
    required this.quizzesCompleted,
    this.lastQuizDate,
  });

  factory MainLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return MainLeaderboardEntry(
      userId: json['user_id'],
      username: json['username'] ?? 'Anonymous',
      avatarUrl: json['avatar_url'],
      profilePoints: json['profile_points'] ?? 0,
      quizScore: json['quiz_score'] ?? 0,
      totalScore: json['total_score'] ?? 0,
      quizzesCompleted: json['quizzes_completed'] ?? 0,
      lastQuizDate: json['last_quiz_date'] != null 
          ? DateTime.parse(json['last_quiz_date']) 
          : null,
    );
  }
}

/// Fetch main leaderboard from the leaderboard table
Future<List<MainLeaderboardEntry>> fetchMainLeaderboard() async {
  try {
    print('🔍 Fetching main leaderboard data...');
    
    // First, sync the leaderboard data to ensure it's up to date
    await syncLeaderboardData();
    
    // Get leaderboard entries with profile information using a join
    // Use distinct to avoid duplicates
    final leaderboardResponse = await supabase
        .from('leaderboard')
        .select('''
          profile_id, 
          score, 
          created_at,
          profiles!inner(id, username, points)
        ''')
        .order('score', ascending: false);

    print('🏆 Found ${leaderboardResponse.length} leaderboard entries');
    
    // Get quiz data for additional info
    final quizLeaderboardResponse = await supabase
        .from('quiz_leaderboard')
        .select('user_id, total_score, quizzes_completed, last_quiz_date');

    final quizScoresMap = <String, Map<String, dynamic>>{};
    for (var entry in quizLeaderboardResponse) {
      quizScoresMap[entry['user_id']] = entry;
    }

    final combinedEntries = <MainLeaderboardEntry>[];
    final seenUsers = <String>{};
    
    for (var entry in leaderboardResponse) {
      final userId = entry['profile_id'];
      
      // Skip if we've already seen this user
      if (seenUsers.contains(userId)) {
        print('⚠️ Skipping duplicate user: $userId');
        continue;
      }
      
      seenUsers.add(userId);
      
      final totalScore = entry['score'] ?? 0;
      final profile = entry['profiles'];
      final profilePoints = profile?['points'] ?? 0;
      final quizData = quizScoresMap[userId];
      
      final quizScore = quizData?['total_score'] ?? 0;
      final quizzesCompleted = quizData?['quizzes_completed'] ?? 0;
      final lastQuizDate = quizData?['last_quiz_date'];
      
      print('👤 User $userId: Total=$totalScore, Profile=$profilePoints, Quiz=$quizScore');
      
      combinedEntries.add(MainLeaderboardEntry(
        userId: userId,
        username: profile?['username'] ?? 'Anonymous',
        avatarUrl: null, // We'll get this from profiles table if needed
        profilePoints: profilePoints,
        quizScore: quizScore,
        totalScore: totalScore,
        quizzesCompleted: quizzesCompleted,
        lastQuizDate: lastQuizDate != null ? DateTime.parse(lastQuizDate) : null,
      ));
    }
    
    print('🏆 Final leaderboard entries: ${combinedEntries.length}');
    for (var entry in combinedEntries) {
      print('🏆 ${entry.username}: ${entry.totalScore} pts (${entry.profilePoints} profile + ${entry.quizScore} quiz)');
    }
    
    return combinedEntries;
  } catch (e) {
    print('❌ Error fetching main leaderboard: $e');
    print('❌ Stack trace: ${StackTrace.current}');
    return [];
  }
}

/// Get current user's leaderboard position
Future<int?> getCurrentUserPosition() async {
  try {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final leaderboard = await fetchMainLeaderboard();
    
    for (int i = 0; i < leaderboard.length; i++) {
      if (leaderboard[i].userId == userId) {
        return i + 1; // Return 1-based position
      }
    }
    
    return null; // User not found in leaderboard
  } catch (e) {
    print('Error getting user position: $e');
    return null;
  }
}

/// Get current user's leaderboard entry
Future<MainLeaderboardEntry?> getCurrentUserEntry() async {
  try {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final leaderboard = await fetchMainLeaderboard();
    
    for (var entry in leaderboard) {
      if (entry.userId == userId) {
        return entry;
      }
    }
    
    return null; // User not found in leaderboard
  } catch (e) {
    print('Error getting user entry: $e');
    return null;
  }
}

/// Debug function to check database state
Future<void> debugDatabaseState() async {
  try {
    print('🔍 === DATABASE DEBUG START ===');
    
    // Check profiles table
    final profiles = await supabase.from('profiles').select('*');
    print('📊 Profiles table has ${profiles.length} entries');
    for (var profile in profiles) {
      print('  👤 ${profile['username'] ?? 'No username'}: ${profile['points'] ?? 0} points');
    }
    
    // Check quiz_leaderboard table
    final quizLeaderboard = await supabase.from('quiz_leaderboard').select('*');
    print('🎯 Quiz leaderboard table has ${quizLeaderboard.length} entries');
    for (var entry in quizLeaderboard) {
      print('  🎯 User ${entry['user_id']}: ${entry['total_score'] ?? 0} quiz points');
    }
    
    // Check main leaderboard table
    final mainLeaderboard = await supabase.from('leaderboard').select('*');
    print('🏆 Main leaderboard table has ${mainLeaderboard.length} entries');
    for (var entry in mainLeaderboard) {
      print('  🏆 User ${entry['profile_id']}: ${entry['score'] ?? 0} total points');
    }
    
    // Check blog_reads table
    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      final blogReads = await supabase
          .from('blog_reads')
          .select('*')
          .eq('user_id', currentUser.id);
      print('📖 Blog reads table has ${blogReads.length} entries for current user');
      for (var read in blogReads) {
        print('  📖 Blog ${read['blog_id']}: read at ${read['read_at'] ?? 'no timestamp'}');
      }
    }
    
    // Check current user
    print('🔑 Current user: ${currentUser?.id} (${currentUser?.email})');
    
    print('🔍 === DATABASE DEBUG END ===');
  } catch (e) {
    print('❌ Debug error: $e');
  }
}

/// Add test data to the database (for debugging)
Future<void> addTestData() async {
  try {
    print('🧪 Adding test data...');
    
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      print('❌ No current user');
      return;
    }
    
    // Add some points to current user's profile
    await supabase.rpc('increment_user_points', params: {
      'p_user_id': currentUser.id,
      'p_points': 100,
    });
    
    // Add quiz leaderboard entry for current user
    await supabase.from('quiz_leaderboard').upsert({
      'user_id': currentUser.id,
      'total_score': 50,
      'quizzes_completed': 2,
      'last_quiz_date': DateTime.now().toIso8601String(),
    });
    
    print('✅ Test data added successfully');
    print('  - Added 100 points to profile');
    print('  - Added 50 quiz points');
    print('  - Total should be 150 points');
    
  } catch (e) {
    print('❌ Error adding test data: $e');
  }
}

/// Initialize database schema (add points column if missing)
Future<void> initializeDatabase() async {
  try {
    print('🔧 Initializing database schema...');
    
    // Try to add points column to profiles table
    await supabase.rpc('exec_sql', params: {
      'sql': 'ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS points INTEGER DEFAULT 0;'
    });
    
    // Update existing profiles to have 0 points if they don't have any
    await supabase.rpc('exec_sql', params: {
      'sql': 'UPDATE public.profiles SET points = 0 WHERE points IS NULL;'
    });
    
    print('✅ Database schema initialized');
    
  } catch (e) {
    print('❌ Error initializing database: $e');
    print('⚠️ You may need to manually run the SQL commands in your Supabase dashboard');
  }
}

/// Sync all users' data to the leaderboard table
Future<void> syncLeaderboardData() async {
  try {
    print('🔄 Syncing leaderboard data...');
    
    // Get all profiles
    final profiles = await supabase.from('profiles').select('id, username, points');
    print('📊 Found ${profiles.length} profiles to sync');
    
    for (var profile in profiles) {
      final userId = profile['id'];
      final profilePoints = profile['points'] ?? 0;
      
      // Get quiz score for this user - use select() instead of maybeSingle()
      final quizResponse = await supabase
          .from('quiz_leaderboard')
          .select('total_score, quizzes_completed, last_quiz_date')
          .eq('user_id', userId);
      
      final quizData = quizResponse.isNotEmpty ? quizResponse.first : null;
      final quizScore = quizData?['total_score'] ?? 0;
      final quizzesCompleted = quizData?['quizzes_completed'] ?? 0;
      final lastQuizDate = quizData?['last_quiz_date'];
      final totalScore = profilePoints + quizScore;
      
      print('👤 Syncing user $userId: Profile=$profilePoints, Quiz=$quizScore, Total=$totalScore');
      
      // Upsert to leaderboard table
      await supabase.from('leaderboard').upsert({
        'profile_id': userId,
        'score': totalScore,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    
    print('✅ Leaderboard data synced successfully');
    
  } catch (e) {
    print('❌ Error syncing leaderboard data: $e');
  }
}

/// Update current user's leaderboard entry
Future<void> updateCurrentUserLeaderboard() async {
  try {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;
    
    final userId = currentUser.id;
    
    // Get user's profile points
    final profileResponse = await supabase
        .from('profiles')
        .select('points')
        .eq('id', userId);
    
    final profile = profileResponse.isNotEmpty ? profileResponse.first : null;
    final profilePoints = profile?['points'] ?? 0;
    
    // Get user's quiz score
    final quizResponse = await supabase
        .from('quiz_leaderboard')
        .select('total_score')
        .eq('user_id', userId);
    
    final quizData = quizResponse.isNotEmpty ? quizResponse.first : null;
    final quizScore = quizData?['total_score'] ?? 0;
    final totalScore = profilePoints + quizScore;
    
    print('🔄 Updating current user leaderboard: Profile=$profilePoints, Quiz=$quizScore, Total=$totalScore');
    
    // Upsert to leaderboard table
    await supabase.from('leaderboard').upsert({
      'profile_id': userId,
      'score': totalScore,
      'created_at': DateTime.now().toIso8601String(),
    });
    
  } catch (e) {
    print('❌ Error updating current user leaderboard: $e');
  }
}

/// Clean up duplicate entries in the leaderboard table
Future<void> cleanupDuplicateLeaderboardEntries() async {
  try {
    print('🧹 Cleaning up duplicate leaderboard entries...');
    
    // Get all leaderboard entries
    final allEntries = await supabase.from('leaderboard').select('*');
    print('📊 Found ${allEntries.length} total leaderboard entries');
    
    // Group by profile_id and keep only the latest entry for each user
    final userEntries = <String, Map<String, dynamic>>{};
    for (var entry in allEntries) {
      final userId = entry['profile_id'];
      final createdAt = entry['created_at'];
      
      if (!userEntries.containsKey(userId) || 
          DateTime.parse(createdAt).isAfter(DateTime.parse(userEntries[userId]!['created_at']))) {
        userEntries[userId] = entry;
      }
    }
    
    print('📊 Found ${userEntries.length} unique users');
    
    // Delete all entries and re-insert only the latest ones
    await supabase.from('leaderboard').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    
    for (var entry in userEntries.values) {
      await supabase.from('leaderboard').insert({
        'profile_id': entry['profile_id'],
        'score': entry['score'],
        'created_at': entry['created_at'],
      });
    }
    
    print('✅ Cleaned up duplicate entries');
    
  } catch (e) {
    print('❌ Error cleaning up duplicates: $e');
  }
}

/// Clean up duplicate blog reads
Future<void> cleanupDuplicateBlogReads() async {
  try {
    print('🧹 Cleaning up duplicate blog reads...');
    
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      print('❌ No current user');
      return;
    }
    
    // Get all blog reads for current user
    final allReads = await supabase
        .from('blog_reads')
        .select('*')
        .eq('user_id', currentUser.id);
    
    print('📖 Found ${allReads.length} total blog reads');
    
    // Group by blog_id and keep only the first read for each blog
    final uniqueReads = <String, Map<String, dynamic>>{};
    for (var read in allReads) {
      final blogId = read['blog_id'];
      final readAt = read['read_at'];
      
      if (!uniqueReads.containsKey(blogId)) {
        uniqueReads[blogId] = read;
      } else {
        // Keep the earliest read
        final existingReadAt = uniqueReads[blogId]!['read_at'];
        if (readAt != null && (existingReadAt == null || readAt.compareTo(existingReadAt) < 0)) {
          uniqueReads[blogId] = read;
        }
      }
    }
    
    print('📖 Found ${uniqueReads.length} unique blog reads');
    
    // Delete all reads and re-insert only the unique ones
    await supabase
        .from('blog_reads')
        .delete()
        .eq('user_id', currentUser.id);
    
    for (var read in uniqueReads.values) {
      await supabase.from('blog_reads').insert({
        'user_id': read['user_id'],
        'blog_id': read['blog_id'],
        'read_at': read['read_at'],
      });
    }
    
    print('✅ Cleaned up duplicate blog reads');
    
  } catch (e) {
    print('❌ Error cleaning up blog reads: $e');
  }
} 