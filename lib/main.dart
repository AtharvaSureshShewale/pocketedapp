import 'package:flutter/material.dart';
import 'package:pocketed/auth/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://dxqibtfzunaxjpykmtnn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR4cWlidGZ6dW5heGpweWttdG5uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyMzA0NjIsImV4cCI6MjA2NTgwNjQ2Mn0.xtLoVJCPoBPiOUEsOATjfaFULo76O5y1VEfG8aD0RwQ',
    
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: AuthGate()
    );
  }
}
