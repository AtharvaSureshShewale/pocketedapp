import 'package:flutter/material.dart';
import 'package:pocketed/services/leaderboard_service.dart';

class LeaderboardCard extends StatelessWidget {
  final MainLeaderboardEntry entry;
  final int position;
  final bool showDetails;

  const LeaderboardCard({
    super.key,
    required this.entry,
    required this.position,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Position
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: position == 1
                  ? Colors.amber[400]
                  : position == 2
                      ? Colors.grey[300]
                      : position == 3
                          ? Colors.brown[300]
                          : Colors.blue[700],
            ),
            child: Center(
              child: Text(
                '$position',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[200],
            child: entry.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      entry.avatarUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          entry.username.isNotEmpty 
                              ? entry.username[0].toUpperCase() 
                              : 'A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    entry.username.isNotEmpty 
                        ? entry.username[0].toUpperCase() 
                        : 'A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          
          // Username and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (showDetails) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${entry.profilePoints} profile + ${entry.quizScore} quiz',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  if (entry.quizzesCompleted > 0)
                    Text(
                      '${entry.quizzesCompleted} quizzes completed',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                ],
              ],
            ),
          ),
          
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalScore}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
              Text(
                'pts',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 