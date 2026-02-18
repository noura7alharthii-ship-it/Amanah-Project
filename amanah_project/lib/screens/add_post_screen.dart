import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/post_service.dart';
import '../theme/app_theme.dart';
import '../widgets/amanah_logo.dart';

class AddPostScreen extends StatefulWidget {
  final String initialType; 
  const AddPostScreen({super.key, required this.initialType});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _type; 
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();

  
  final _contact = TextEditingController();

  bool _loading = false;

  Uint8List? _imageBytes;
  String _ext = 'jpg';
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType == 'found' ? 'found' : 'lost';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final name = file.name.toLowerCase();

    String ext = 'jpg';
    if (name.endsWith('.png')) ext = 'png';
    if (name.endsWith('.webp')) ext = 'webp';
    if (name.endsWith('.jpeg') || name.endsWith('.jpg')) ext = 'jpg';

    setState(() {
      _imageBytes = bytes;
      _ext = ext;
    });
  }

  bool _isEmail(String s) =>
      RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s.trim());

  bool _isPhone(String s) {
    final cleaned = s.replaceAll(' ', '');
    return RegExp(r'^\+?\d{9,15}$').hasMatch(cleaned);
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);
    try {
      String? imageUrl;

      if (_imageBytes != null) {
        final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}';
        imageUrl = await PostService.uploadImage(
          bytes: _imageBytes!,
          fileName: fileName,
          ext: _ext,
        );
      }

      await PostService.addPost(
        type: _type,
        title: _title.text,
        description: _description.text,
        location: _location.text,
        imageUrl: imageUrl,
        contactEmail: _contact.text, 
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,

      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 22,
        title: const AmanahLogo(size: 28),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  'Add post',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fill the details below to publish a lost/found report.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedText,
                      ),
                ),
                const SizedBox(height: 16),

                // Type Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        _TypeToggle(
                          value: _type,
                          onChanged: (v) => setState(() => _type = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _title,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Title is required'
                              : null,
                          decoration: const InputDecoration(
                            hintText: 'Title (e.g., ID card, iPhone...)',
                            prefixIcon: Icon(Icons.title),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _location,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Location is required'
                              : null,
                          decoration: const InputDecoration(
                            hintText: 'Location (e.g., Mall, University...)',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),

                        
                        TextFormField(
                          controller: _contact,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return 'Contact is required';

                            if (!_isEmail(s) && !_isPhone(s)) {
                              return 'Enter a valid email or phone';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: 'Contact (email or phone)',
                            prefixIcon: Icon(Icons.contact_mail_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _description,
                          minLines: 3,
                          maxLines: 6,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Description is required'
                              : null,
                          decoration: const InputDecoration(
                            hintText: 'Description',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Image (optional)',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 10),

                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image_outlined),
                          label: Text(
                            _imageBytes == null
                                ? 'Choose image'
                                : 'Change image ✅',
                          ),
                        ),

                        if (_imageBytes != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.memory(
                              _imageBytes!,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Publish'),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String value; 
  final ValueChanged<String> onChanged;

  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isLost = value == 'lost';
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Seg(
              active: isLost,
              text: 'Lost',
              icon: Icons.help_outline,
              onTap: () => onChanged('lost'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _Seg(
              active: !isLost,
              text: 'Found',
              icon: Icons.inventory_2_outlined,
              onTap: () => onChanged('found'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final bool active;
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _Seg({
    required this.active,
    required this.text,
    required this.icon,
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
          
          color: active ? AppColors.navy.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? AppColors.navy : AppColors.mutedText,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: active ? AppColors.navy : AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
