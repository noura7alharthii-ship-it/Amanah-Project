import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showError(BuildContext context, Object error) async {
  final msg = error is AuthException ? error.message : error.toString();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  );
}

String displayNameOrFallback(User? user) {
  if (user == null) return '';
  final meta = user.userMetadata ?? {};
  final fullName = (meta['full_name'] ?? meta['name'] ?? '').toString().trim();
  if (fullName.isNotEmpty) return fullName;
  final email = user.email ?? '';
  if (email.contains('@')) return email.split('@').first;
  return email;
}
