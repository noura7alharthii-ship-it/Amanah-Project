import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';
import '../widgets/amanah_logo.dart';

class PostDetailsScreen extends StatelessWidget {
  final PostModel post;
  const PostDetailsScreen({super.key, required this.post});

  bool _isEmail(String s) => RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s.trim());

  String _cleanPhone(String s) {
    // removes spaces, keeps + and digits
    return s.trim().replaceAll(' ', '');
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied ✅')),
    );
  }

  Future<void> _launchOrSnack(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open: ${uri.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.imageUrl;
    final contact = (post.contactEmail ?? '').trim();

    final isOwner = Supabase.instance.client.auth.currentUser?.id == post.userId;

    final status = post.status ?? 'open';
    final isResolved = status == 'resolved';

    final hasContact = contact.isNotEmpty;
    final isEmail = hasContact && _isEmail(contact);
    final phone = hasContact ? _cleanPhone(contact) : '';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const AmanahLogo(size: 30),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Image
              if (imageUrl != null && imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'Image failed to load',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.mutedText),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Title
              Text(
                post.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                    ),
              ),
              const SizedBox(height: 10),

              // Chips + Status badge
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Chip(
                    text: post.type.toUpperCase(),
                    icon: post.type == 'lost'
                        ? Icons.help_outline
                        : Icons.inventory_2_outlined,
                  ),
                  _Chip(text: post.location, icon: Icons.location_on_outlined),
                  _StatusChip(status: status),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    post.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Contact section
              if (hasContact)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          contact,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                        ),
                        const SizedBox(height: 12),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _copy(context, contact),
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy'),
                              ),
                            ),
                            const SizedBox(width: 10),

                            if (isEmail) ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final uri = Uri(
                                      scheme: 'mailto',
                                      path: contact,
                                      query: Uri.encodeQueryComponent('subject=Amanah: About your post'),
                                    );
                                    _launchOrSnack(context, uri);
                                  },
                                  icon: const Icon(Icons.email_outlined),
                                  label: const Text('Email'),
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final uri = Uri(scheme: 'tel', path: phone);
                                    _launchOrSnack(context, uri);
                                  },
                                  icon: const Icon(Icons.call_outlined),
                                  label: const Text('Call'),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // WhatsApp (only for phone)
                        if (!isEmail) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // whatsapp deep link
                                final wa = Uri.parse('https://wa.me/$phone');
                                _launchOrSnack(context, wa);
                              },
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('WhatsApp'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Status button (Owner only)
              if (isOwner) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isResolved ? AppColors.sand : Colors.green.shade600,
                      foregroundColor:
                          isResolved ? AppColors.navy : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      try {
                        await PostService.setPostStatus(
                          postId: post.id,
                          status: isResolved ? 'open' : 'resolved',
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context, true); // refresh list
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    icon: Icon(
                        isResolved ? Icons.undo : Icons.check_circle_outline),
                    label: Text(isResolved ? 'Re-open' : 'Mark as resolved'),
                  ),
                ),
              ],

              const Spacer(),

              // Delete (Owner only)
              if (isOwner)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete post?'),
                          content: const Text(
                            'Are you sure you want to delete this post?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      try {
                        await PostService.deletePost(
                          postId: post.id,
                          imageUrl: post.imageUrl,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context, true);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete this post'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Chip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.navy),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status; // open | resolved
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isResolved = status == 'resolved';
    final bg = isResolved ? Colors.green.withAlpha(24) : AppColors.navy.withAlpha(14);
    final fg = isResolved ? Colors.green.shade800 : AppColors.navy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        isResolved ? 'Resolved' : 'Open',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}
