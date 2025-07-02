import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pocketed/pages/auth_pages/resetPassword_page.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get user email
  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  // Get user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  // Save username in profiles table
  Future<void> saveUsername(String username) async {
    final userId = getCurrentUserId();
    final email = getCurrentUserEmail();

    if (userId == null) throw Exception('User not logged in');

    await _supabase.from('profiles').upsert({
      'id': userId,
      'username': username,
      'email': email,
    });
  }

  // Get current username
  Future<String?> getCurrentUsername() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    final response = await _supabase
        .from('profiles')
        .select('username')
        .eq('id', userId)
        .single();

    return response['username'] as String?;
  }

  // Password reset
  requestResetPassword() {
    _supabase.auth.resetPasswordForEmail(
      'atharvashewale265@gmail.com',
      redirectTo: 'code://password-reset',
    );
  }

  // Deep link config
  void ConfigDeepLink(BuildContext context) {
    final applinks = AppLinks();
    applinks.uriLinkStream.listen((uri) {
      if (uri.host == 'password-reset') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ResetpasswordPage()),
        );
      }
    });
  }

  // Reset password
  Future<void> resetPassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
