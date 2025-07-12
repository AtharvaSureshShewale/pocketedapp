import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pocketed/services/leaderboard_service.dart';
import 'package:pocketed/widgets/shared_scaffold.dart';
import 'package:pocketed/widgets/leaderboard_card.dart';

class MainLeaderboardPage extends StatefulWidget {
  const MainLeaderboardPage({super.key});

  @override
  State<MainLeaderboardPage> createState() => _MainLeaderboardPageState();
}

class _MainLeaderboardPageState extends State<MainLeaderboardPage> {
  bool _isLoading = true;
  List<MainLeaderboardEntry> _leaderboard = [];
  String? _errorMessage;
  MainLeaderboardEntry? _currentUserEntry;
  int? _currentUserPosition;

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

      final leaderboard = await fetchMainLeaderboard();
      final currentUserEntry = await getCurrentUserEntry();
      final currentUserPosition = await getCurrentUserPosition();
      
      setState(() {
        _leaderboard = leaderboard;
        _currentUserEntry = currentUserEntry;
        _currentUserPosition = currentUserPosition;
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
      currentRoute: '/leaderboard',
      showNavbar: false,
      appBar: AppBar(
        title: const Text('🏆 Leaderboard'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
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
            const Text('Start earning points to get on the leaderboard!'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildLeaderboardHeader(),
        if (_currentUserEntry != null) _buildCurrentUserCard(),
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
            '🏆 Overall Champions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Profile Points + Quiz Scores',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
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

  Widget _buildTopThreeItem(MainLeaderboardEntry entry, int position) {
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

    final username = entry.username;
    final avatarUrl = entry.avatarUrl;
    
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

  Widget _buildCurrentUserCard() {
    if (_currentUserEntry == null || _currentUserPosition == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[700],
            ),
            child: Center(
              child: Text(
                '$_currentUserPosition',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
                  'Your Position',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _currentUserEntry!.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${_currentUserEntry!.profilePoints} profile + ${_currentUserEntry!.quizScore} quiz = ${_currentUserEntry!.totalScore} total',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_currentUserEntry!.totalScore}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blue,
                ),
              ),
              Text(
                'pts',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(MainLeaderboardEntry entry, int index) {
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
      child: LeaderboardCard(
        entry: entry,
        position: position,
        showDetails: true,
      ),
    );
  }
} 