import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';
import '../widgets/amanah_logo.dart';
import 'post_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<_DashData> _load() async {
    final stats = await PostService.getDashboardStats(sampleLimit: 400);
    final recent = await PostService.getRecentPosts(limit: 5);
    final mine = await PostService.getMyPosts(limit: 8);
    return _DashData(stats: stats, recent: recent, mine: mine);
  }

  Future<void> _openPost(PostModel p) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailsScreen(post: p)),
    );
    if (res == true && mounted) setState(() {});
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    Color? tint,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: (tint ?? AppColors.navy).withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postTile(PostModel p) {
    final url = p.imageUrl;
    final has = url != null && url.isNotEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openPost(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 52,
                  width: 52,
                  color: AppColors.sand.withOpacity(0.12),
                  child: has
                      ? Image.network(
                          url!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _miniIcon(p.type),
                        )
                      : _miniIcon(p.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniIcon(String type) {
    return Center(
      child: Icon(
        type == 'lost' ? Icons.help_outline : Icons.inventory_2_outlined,
        color: AppColors.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: FutureBuilder<_DashData>(
            future: _load(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                );
              }

              final data = snap.data!;
              final s = data.stats;

              final total = s['total'] ?? 0;
              final lost = s['lost'] ?? 0;
              final found = s['found'] ?? 0;
              final resolved = s['resolved'] ?? 0;

              final myTotal = s['myTotal'] ?? 0;
              final myResolved = s['myResolved'] ?? 0;

              // نسبة بسيطة (اختياري)
              final resolvedPct = total == 0 ? 0 : (resolved / total);

              return ListView(
                children: [
                  Row(
                    children: [
                      const AmanahLogo(size: 34),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: () => setState(() {}),
                        icon: const Icon(Icons.refresh),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Overview of reports and your activity.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedText,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ Stats grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: [
                      _statCard(
                        title: 'Total reports',
                        value: '$total',
                        icon: Icons.all_inbox_outlined,
                      ),
                      _statCard(
                        title: 'Resolved',
                        value: '$resolved',
                        icon: Icons.check_circle_outline,
                      ),
                      _statCard(
                        title: 'Lost',
                        value: '$lost',
                        icon: Icons.help_outline,
                      ),
                      _statCard(
                        title: 'Found',
                        value: '$found',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ✅ My summary card (wow)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My activity',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _pill('My posts', '$myTotal'),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _pill('My resolved', '$myResolved'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // progress bar بسيط
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: resolvedPct.toDouble(),
                              minHeight: 10,
                              backgroundColor: AppColors.border,
                              color: AppColors.sand, // olive / secondary
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Resolved rate: ${(resolvedPct * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ✅ Recent
                  Row(
                    children: [
                      const Text(
                        'Recent reports',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.text,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (data.recent.isEmpty)
                    const Text(
                      'No reports yet.',
                      style: TextStyle(color: AppColors.mutedText),
                    )
                  else
                    ...data.recent.map(_postTile),

                  const SizedBox(height: 18),

                  // ✅ My posts
                  const Text(
                    'My reports',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (data.mine.isEmpty)
                    const Text(
                      'You haven’t added any reports yet.',
                      style: TextStyle(color: AppColors.mutedText),
                    )
                  else
                    ...data.mine.map(_postTile),

                  const SizedBox(height: 18),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _pill(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashData {
  final Map<String, int> stats;
  final List<PostModel> recent;
  final List<PostModel> mine;

  _DashData({required this.stats, required this.recent, required this.mine});
}
