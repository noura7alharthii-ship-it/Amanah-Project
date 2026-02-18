import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post_model.dart';
import '../services/auth_helpers.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';
import '../widgets/amanah_logo.dart';

import 'add_post_screen.dart';
import 'dashboard_screen.dart';
import 'post_details_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0; // 0 = Lost, 1 = Found
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<PostModel>> _fetchPosts() async {
    final type = _tab == 0 ? 'lost' : 'found';
    final q = _search.text.trim().toLowerCase();

    final list = await PostService.getPosts(type: type);

    // Search filter
    List<PostModel> filtered = list;
    if (q.isNotEmpty) {
      bool contains(String v) => v.toLowerCase().contains(q);
      filtered = list.where((p) {
        return contains(p.title) ||
            contains(p.description) ||
            contains(p.location);
      }).toList();
    }

    // ✅ open فوق و resolved تحت
    filtered.sort((a, b) {
      final sa = (a.status ?? 'open');
      final sb = (b.status ?? 'open');
      if (sa == sb) return b.createdAt.compareTo(a.createdAt);
      if (sa == 'open') return -1;
      return 1;
    });

    return filtered;
  }

  /// Small badge (Lost/Found)
  Widget _badge(String type) {
    final isLost = type == 'lost';
    final bg = isLost ? AppColors.navy.withAlpha(20) : AppColors.sand.withAlpha(64);
    final fg = AppColors.navy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLost ? Icons.help_outline : Icons.inventory_2_outlined,
            size: 16,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            isLost ? 'Lost' : 'Found',
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  /// Status badge (Open/Resolved)
  Widget _statusBadge(String status) {
    final isResolved = status == 'resolved';
    final bg = isResolved ? Colors.green.withAlpha(24) : AppColors.navy.withAlpha(14);
    final fg = isResolved ? Colors.green.shade800 : AppColors.navy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        isResolved ? 'Resolved' : 'Open',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: fg,
          fontSize: 12,
        ),
      ),
    );
  }

  // ✅ صورة الكارد (كبيرة وواضحة)
  Widget _imageHeader(PostModel p) {
    final url = p.imageUrl;
    final has = url != null && url.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: has
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(p),
                ),
              )
            : _imagePlaceholder(p),
      ),
    );
  }

  Widget _imagePlaceholder(PostModel p) {
    final isLost = p.type == 'lost';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.sand.withAlpha(31),
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Center(
        child: Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            isLost ? Icons.help_outline : Icons.inventory_2_outlined,
            size: 30,
            color: AppColors.navy,
          ),
        ),
      ),
    );
  }

  Widget _postCard(BuildContext context, PostModel p) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailsScreen(post: p)),
          );
          if (res == true) setState(() {});
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageHeader(p),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + badges
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _badge(p.type),
                          const SizedBox(width: 8),
                          _statusBadge(p.status ?? 'open'),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 18, color: AppColors.mutedText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.mutedText),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Description preview
                  Text(
                    p.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedText,
                          height: 1.35,
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

  Widget _header(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = displayNameOrFallback(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AmanahLogo(size: 34),
            const Spacer(),

            // ✅ Profile
            IconButton(
              tooltip: 'Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              icon: const Icon(Icons.person_outline),
            ),

            // Dashboard
            IconButton(
              tooltip: 'Dashboard',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
              icon: const Icon(Icons.bar_chart_rounded),
            ),

            // Refresh
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
            ),

            // Sign out
            IconButton(
              tooltip: 'Sign out',
              onPressed: () async => Supabase.instance.client.auth.signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Welcome, $name',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search title, location, or description',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 18),

              _searchBar(),
              const SizedBox(height: 14),

              _Segmented(
                value: _tab,
                onChanged: (v) => setState(() => _tab = v),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: FutureBuilder<List<PostModel>>(
                  future: _fetchPosts(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snap.hasError) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Center(
                            child: Text(
                              'Error: ${snap.error}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.mutedText),
                            ),
                          ),
                        ),
                      );
                    }

                    final posts = snap.data ?? [];
                    if (posts.isEmpty) {
                      return _EmptyState(
                        tab: _tab,
                        onAdd: () async {
                          final initType = _tab == 0 ? 'lost' : 'found';
                          final didAdd = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddPostScreen(initialType: initType),
                            ),
                          );
                          if (didAdd == true) setState(() {});
                        },
                        onRefresh: () => setState(() {}),
                      );
                    }

                    return ListView.separated(
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) => _postCard(context, posts[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.offWhite,
        onPressed: () async {
          final initType = _tab == 0 ? 'lost' : 'found';
          final didAdd = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddPostScreen(initialType: initType)),
          );
          if (didAdd == true) setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final int tab;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.tab,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 74,
                width: 74,
                decoration: BoxDecoration(
                  color: AppColors.sand.withAlpha(46),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  tab == 0 ? Icons.help_outline : Icons.inventory_2_outlined,
                  color: AppColors.navy,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                tab == 0 ? 'No lost reports yet' : 'No found reports yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                tab == 0
                    ? 'Add a lost report to help others find the item.'
                    : 'Add a found report so the owner can identify it.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sand,
                      foregroundColor: AppColors.navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _Segmented({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegButton(
              active: value == 0,
              text: 'Lost',
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SegButton(
              active: value == 1,
              text: 'Found',
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  final bool active;
  final String text;
  final VoidCallback onTap;

  const _SegButton({
    required this.active,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.navy.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: active ? AppColors.navy : AppColors.mutedText,
          ),
        ),
      ),
    );
  }
}
