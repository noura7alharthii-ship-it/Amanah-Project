import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';

class PostService {
  static final SupabaseClient _client = Supabase.instance.client;

  static const String tableName = 'posts';
  static const String bucketName = 'post_images';

  static String _contentType(String ext) {
    final e = ext.toLowerCase();
    if (e == 'png') return 'image/png';
    if (e == 'webp') return 'image/webp';
    return 'image/jpeg';
  }

  static Future<String?> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String ext, // jpg/png/webp
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'You must be logged in';

    final safeExt = ext.toLowerCase();
    final path = '${user.id}/$fileName.$safeExt';

    await _client.storage.from(bucketName).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentType(safeExt),
          ),
        );

    return _client.storage.from(bucketName).getPublicUrl(path);
  }

  static Future<void> addPost({
    required String type,
    required String title,
    required String description,
    required String location,
    String? imageUrl,
    required String contactEmail, // ✅ يدوي
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'You must be logged in';

    final contact = (contactEmail ?? '').trim();
    await _client.from(tableName).insert({
      'type': type,
      'title': title.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'image_url': imageUrl,
      'user_id': user.id,
      'contact_email': contact .trim(), // ✅
      'status': 'open',
    });
  }

  static Future<List<PostModel>> getPosts({required String type}) async {
    final data = await _client
        .from(tableName)
        // ✅ صريح عشان ما يضيع عمود الكونتاكت
        .select('id,user_id,title,description,location,type,status,image_url,contact_email,created_at')
        .eq('type', type)
        .order('created_at', ascending: false);

    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map(PostModel.fromJson).toList();
  }

  static Future<void> setPostStatus({
    required String postId,
    required String status, // 'open' | 'resolved'
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'You must be logged in';

    await _client.from(tableName).update({'status': status}).eq('id', postId);
  }

  static Future<void> deletePost({
    required String postId,
    String? imageUrl,
  }) async {
    final client = Supabase.instance.client;

    // 1) delete DB
    await client.from(tableName).delete().eq('id', postId);

    // 2) delete image (optional)
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      try {
        final url = imageUrl.trim();

        String? filePath;
        const publicKey = '/object/public/post_images/';
        const signKey = '/object/sign/post_images/';

        if (url.contains(publicKey)) {
          filePath = url.split(publicKey).last.split('?').first;
        } else if (url.contains(signKey)) {
          filePath = url.split(signKey).last.split('?').first;
        } else if (url.contains('post_images/')) {
          filePath = url.split('post_images/').last.split('?').first;
        }

        if (filePath != null && filePath.isNotEmpty) {
          await client.storage.from(bucketName).remove([filePath]);
        }
      } catch (_) {}
    }
  }
    // ✅ Recent posts (all types)
  static Future<List<PostModel>> getRecentPosts({int limit = 5}) async {
    final data = await _client
        .from(tableName)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map(PostModel.fromJson).toList();
  }

  // ✅ My posts (current user)
  static Future<List<PostModel>> getMyPosts({int limit = 12}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'You must be logged in';

    final data = await _client
        .from(tableName)
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map(PostModel.fromJson).toList();
  }

  // ✅ Stats for dashboard (fetch limited then count in app - stable & simple)
  static Future<Map<String, int>> getDashboardStats({int sampleLimit = 300}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw 'You must be logged in';

    final data = await _client
        .from(tableName)
        .select('type,status,user_id')
        .order('created_at', ascending: false)
        .limit(sampleLimit);

    final list = (data as List).cast<Map<String, dynamic>>();

    int total = list.length;
    int lost = 0, found = 0, resolved = 0;
    int myTotal = 0, myResolved = 0;

    for (final r in list) {
      final type = (r['type'] ?? '').toString();
      final status = (r['status'] ?? 'open').toString();
      final uid = (r['user_id'] ?? '').toString();

      if (type == 'lost') lost++;
      if (type == 'found') found++;
      if (status == 'resolved') resolved++;

      if (uid == user.id) {
        myTotal++;
        if (status == 'resolved') myResolved++;
      }
    }

    return {
      'total': total,
      'lost': lost,
      'found': found,
      'resolved': resolved,
      'myTotal': myTotal,
      'myResolved': myResolved,
    };
  }

}
