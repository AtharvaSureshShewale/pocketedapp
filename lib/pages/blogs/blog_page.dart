import 'package:flutter/material.dart';
import 'package:pocketed/widgets/shared_scaffold.dart';

class BlogPage extends StatelessWidget {
  const BlogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SharedScaffold(
      currentRoute: '/blog',
      showNavbar: true,
      appBar: AppBar(title: const Text('Blog Page')),
      body: const Center(child: Text('Blog Page')),
    );
  }
}
