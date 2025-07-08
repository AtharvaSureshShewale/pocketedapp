import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pocketed/widgets/shared_scaffold.dart';

class MentorTalksScreen extends StatelessWidget {
  const MentorTalksScreen({Key? key}) : super(key: key);

  final mentors = const [
    {
      'name': 'Jared Deul',
      'title': 'Finance Professor',
      'quote': 'Leadership is action, not position',
      'image': 'assets/images/jared.png',
    },
    {
      'name': 'Raul Fernandes',
      'title': 'Finance Professor',
      'quote': 'An investment in Knowledge pays the best interest',
      'image': 'assets/images/raul.png',
    },
    {
      'name': "Jaden D'souza",
      'title': 'Finance Professor',
      'quote': "Believe you can and you're halfway there",
      'image': 'assets/images/jaden.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SharedScaffold(
      currentRoute: '/mentor',
      showNavbar: true,
      appBar: AppBar(
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.black),
        //   onPressed: () => Navigator.pop(context),
        // ),
        title: Center(
          child: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Mentor ',
                  style: TextStyle(color: Colors.blue, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: 'Talks',
                  style: TextStyle(color: Colors.yellow, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mentors.length,
        itemBuilder: (context, index) {
          final mentor = mentors[index];
          return MentorCard(
            name: mentor['name']!,
            title: mentor['title']!,
            quote: mentor['quote']!,
            imagePath: mentor['image']!,
          );
        },
      ),
    );
  }
}

class MentorCard extends StatelessWidget {
  final String name;
  final String title;
  final String quote;
  final String imagePath;

  const MentorCard({
    Key? key,
    required this.name,
    required this.title,
    required this.quote,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.orange,
            child: CircleAvatar(
              radius: 32,
              backgroundImage: AssetImage(imagePath),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(quote,
                    style: const TextStyle(fontSize: 12, color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    SocialIcon(icon: FontAwesomeIcons.linkedin, color: Colors.blue),
                    SizedBox(width: 8),
                    SocialIcon(icon: FontAwesomeIcons.xTwitter, color: Colors.black),
                    SizedBox(width: 8),
                    SocialIcon(icon: FontAwesomeIcons.instagram, color: Colors.pink),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const SocialIcon({Key? key, required this.icon, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.white,
      child: Icon(icon, color: color, size: 16),
    );
  }
}
