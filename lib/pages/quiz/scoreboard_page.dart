import 'package:flutter/material.dart';
import 'package:pocketed/models/quiz_models.dart';
import 'package:pocketed/services/quiz_service.dart';
import 'package:pocketed/widgets/shared_scaffold.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ScoreboardPage extends StatefulWidget {
  const ScoreboardPage({super.key});

  @override
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  bool _isLoading = true;
  List<QuizLeaderboardEntry> _leaderboard = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final leaderboard = await fetchQuizLeaderboard();
      
      setState(() {
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load leaderboard: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedScaffold(
      currentRoute: '/quiz/scoreboard',
      appBar: AppBar(
        title: const Text('Quiz Scoreboard'),
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
              onPressed: _loadLeaderboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'No Scores Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Be the first to complete a quiz and get on the leaderboard!'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/quiz'),
              child: const Text('Go to Quizzes'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildLeaderboardHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _leaderboard.length,
            itemBuilder: (context, index) {
              final entry = _leaderboard[index];
              return _buildLeaderboardItem(entry, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Top Performers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_leaderboard.length >= 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildTopThreeItem(_leaderboard[1], 1),
                _buildTopThreeItem(_leaderboard[0], 0),
                _buildTopThreeItem(_leaderboard[2], 2),
              ],
            )
          else if (_leaderboard.length == 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildTopThreeItem(_leaderboard[1], 1),
                _buildTopThreeItem(_leaderboard[0], 0),
              ],
            )
          else if (_leaderboard.length == 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildTopThreeItem(_leaderboard[0], 0),
              ],
            )
          else
            const Text(
              'No participants yet',
              style: TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopThreeItem(QuizLeaderboardEntry entry, int position) {
    final colors = [
      Colors.amber[400]!, // Gold for 1st
      Colors.grey[300]!, // Silver for 2nd
      Colors.brown[300]!, // Bronze for 3rd
    ];
    
    final sizes = [
      80.0, // Size for 1st
      70.0, // Size for 2nd
      60.0, // Size for 3rd
    ];
    
    final textSizes = [
      18.0, // Text size for 1st
      16.0, // Text size for 2nd
      14.0, // Text size for 3rd
    ];
    
    final icons = [
      FontAwesomeIcons.crown, // Icon for 1st
      FontAwesomeIcons.medal, // Icon for 2nd
      FontAwesomeIcons.award, // Icon for 3rd
    ];

    final username = entry.profile?.username ?? 'Anonymous';
    final avatarUrl = entry.profile?.avatarUrl;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(
            icons[position],
            color: colors[position],
            size: position == 0 ? 24 : 20,
          ),
          const SizedBox(height: 4),
          Container(
            width: sizes[position],
            height: sizes[position],
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: colors[position],
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[position].withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        avatarUrl,
                        width: sizes[position] - 6,
                        height: sizes[position] - 6,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildAvatarFallback(username, colors[position]);
                        },
                      ),
                    )
                  : _buildAvatarFallback(username, colors[position]),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            username,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: textSizes[position],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${entry.totalScore} pts',
            style: TextStyle(
              color: colors[position],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String username, Color color) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : 'A',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(QuizLeaderboardEntry entry, int index) {
    final username = entry.profile?.username ?? 'Anonymous';
    final avatarUrl = entry.profile?.avatarUrl;
    final position = index + 1;
    
    // Skip the top 3 in the list view
    if (position <= 3) {
      return const SizedBox.shrink();
    }

    Color? backgroundColor;
    if (position % 2 == 0) {
      backgroundColor = Colors.grey[50];
    }

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[700],
            ),
            child: Text(
              '$position',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            username.isNotEmpty ? username[0].toUpperCase() : 'A',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${entry.quizzesCompleted} quizzes completed',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.totalScore}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'pts',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 