import 'package:supabase_flutter/supabase_flutter.dart';
class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static SupabaseClient get client => _client;

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static String displayNameOrEmail() {
    final user = _client.auth.currentUser;
    if (user == null) return '';
    final meta = user.userMetadata ?? {};
    final name = (meta['full_name'] ?? '').toString().trim();
    return name.isNotEmpty ? name : (user.email ?? '');
  }
}
