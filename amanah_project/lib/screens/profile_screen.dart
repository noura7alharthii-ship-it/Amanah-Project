import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';
import '../widgets/amanah_logo.dart';
import 'post_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<List<PostModel>> _fetchMyPosts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final data = await Supabase.instance.client
        .from('posts')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map((e) => PostModel.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Row(
                children: [
                  const AmanahLogo(size: 30),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            AppColors.sand.withValues(alpha: 0.2),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.navy,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.email ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Member of Amanah',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.mutedText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'My Reports',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: FutureBuilder<List<PostModel>>(
                  future: _fetchMyPosts(),
                  builder: (context, snap) {
                    if (snap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final posts = snap.data ?? [];

                    if (posts.isEmpty) {
                      return Center(
                        child: Text(
                          'You have not added any reports yet.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: AppColors.mutedText),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: posts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final p = posts[i];

                        return Card(
                          child: ListTile(
                            title: Text(
                              p.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(p.location),
                            trailing: const Icon(
                                Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PostDetailsScreen(post: p),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.offWhite,
                ),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
