// import 'package:flutter/material.dart';
// import 'package:pocketed/widgets/shared_scaffold.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:pocketed/pages/blogs/blog_detail_page.dart';
// import 'package:pocketed/pages/blogs/blog_card.dart';

// class BlogPage extends StatefulWidget {
//   const BlogPage({super.key});

//   @override
//   State<BlogPage> createState() => _BlogPageState();
// }

// class _BlogPageState extends State<BlogPage> {
//   final SupabaseClient supabase = Supabase.instance.client;

//   List<Map<String, dynamic>> _blogs = [];
//   Set<String> _readBlogIds = {};
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     loadData();
//   }

//   Future<void> loadData() async {
//     final userId = supabase.auth.currentUser?.id;
//     if (userId == null) return;

//     setState(() => _isLoading = true);

//     try {
//       final blogsResponse = await supabase
//           .from('blogs')
//           .select()
//           .eq('is_published', true)
//           .order('created_at', ascending: false) as List;

//       final readsResponse = await supabase
//           .from('blog_reads')
//           .select('blog_id')
//           .eq('user_id', userId) as List;

//       final readIds = readsResponse.map((r) => r['blog_id'] as String).toSet();

//       if (!mounted) return;

//       setState(() {
//         _blogs = List<Map<String, dynamic>>.from(blogsResponse);
//         _readBlogIds = readIds;
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading blogs: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SharedScaffold(
//       currentRoute: '/blog',
//       showNavbar: true,
//       appBar: AppBar(
//         title: const Text("All Blogs"),
//         centerTitle: true,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//               onRefresh: loadData,
//               child: _blogs.isEmpty
//                   ? const Center(child: Text("No blogs available."))
//                   : ListView.builder(
//                       padding: const EdgeInsets.all(16),
//                       itemCount: _blogs.length,
//                       itemBuilder: (context, index) {
//                         final blog = _blogs[index];
//                         final isRead = _readBlogIds.contains(blog['id']);

//                         return Stack(
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.only(bottom: 16),
//                               child: BlogCard(
//                                 title: blog['title'] ?? '',
//                                 coverImageUrl: blog['cover_image_url'] ?? '',
//                                 content: blog['description'] ?? '',
//                                 readTime: blog['read_time'] ?? '',
//                                 publishedAt:
//                                     blog['published_at'] ?? blog['created_at'],
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => BlogDetailPage(blog: blog),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                             if (isRead)
//                               Positioned(
//                                 top: 8,
//                                 right: 8,
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 8,
//                                     vertical: 4,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue,
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: const Text(
//                                     'Read',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         );
//                       },
//                     ),
//             ),
//     );
//   }
// }
