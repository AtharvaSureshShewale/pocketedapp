import 'package:flutter/material.dart';
import 'package:pocketed/auth/auth_gate.dart';
import 'package:pocketed/pages/assitive_pages/assitive_page.dart';
import 'package:pocketed/pages/auth_pages/home_page.dart';
import 'package:pocketed/pages/auth_pages/login_page.dart'; // ✅ Add this
import 'package:pocketed/pages/auth_pages/resetPassword_page.dart';
import 'package:pocketed/pages/blogs/blog_page.dart';
import 'package:pocketed/pages/courses/course_display_page.dart';
import 'package:pocketed/utils/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppText.AppBaseUrl,
    anonKey: AppText.AppAnonKey,
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    final Session? session = data.session;

    if (event == AuthChangeEvent.passwordRecovery && session != null) {
      navigatorKey.currentState?.pushNamed('/reset');
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Pocketed',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(), // 👈 Entry point for auth
      routes: {
        '/auth': (context) => const LoginPage(), // ✅ Add missing auth route
        '/home': (context) => const HomePage(),
        '/blog': (context) => const BlogPage(),
        '/reset': (context) => const ResetpasswordPage(),
        '/assistive': (context) => const AssistivePage(),
        '/courses': (context) => const CourseDisplayPage(),
      },
    );
  }
}
