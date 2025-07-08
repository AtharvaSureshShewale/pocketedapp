import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pocketed/widgets/shared_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MentorTalksScreen extends StatefulWidget {
  const MentorTalksScreen({Key? key}) : super(key: key);

  @override
  State<MentorTalksScreen> createState() => _MentorTalksScreenState();
}

class _MentorTalksScreenState extends State<MentorTalksScreen> {
  List<dynamic> mentors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMentors();
  }

  Future<void> fetchMentors() async {
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('mentors')
        .select()
        .order('name', ascending: true);

    setState(() {
      mentors = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SharedScaffold(
      currentRoute: '/mentor',
      showNavbar: true,
      appBar: AppBar(
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mentors.length,
              itemBuilder: (context, index) {
                final mentor = mentors[index];
                return MentorCard(
                  name: mentor['name'] ?? 'Unknown',
                  title: mentor['title'] ?? '',
                  quote: mentor['quote'] ?? '',
                  imagePath: mentor['image_url'] ?? '',
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
              backgroundImage: imagePath.isNotEmpty
                  ? NetworkImage(imagePath)
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(quote, style: const TextStyle(fontSize: 12, color: Colors.black87)),
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
