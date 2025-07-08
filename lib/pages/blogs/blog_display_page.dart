import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pocketed/pages/blogs/blogs_section.dart';
import 'package:pocketed/widgets/shared_scaffold.dart'; // Your shared scaffold

class BlogDisplayPage extends StatefulWidget {
  const BlogDisplayPage({super.key});

  @override
  State<BlogDisplayPage> createState() => _BlogDisplayPageState();
}

class _BlogDisplayPageState extends State<BlogDisplayPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> blogs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBlogs();
  }

  Future<void> fetchBlogs() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('blogs')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        blogs = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching blogs: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedScaffold(
      currentRoute: '/blogDisplay',
      showNavbar: true,
      appBar: AppBar(title: const Text('Blogs')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : blogs.isEmpty
              ? const Center(child: Text('No blogs found.'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: BlogSection(
                    blogPosts: blogs,
                    isHorizontal: false,
                    onCardTap: (blog) async {
                      Navigator.pushNamed(context, '/blogDetails', arguments: blog);
                      setState(() {
                        final index = blogs.indexWhere((b) => b['id'] == blog['id']);
                        if (index != -1) blogs[index]['isRead'] = true;
                      });
                    },
                  ),
                ),
    );
  }
}
