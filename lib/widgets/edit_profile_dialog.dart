import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sub_profile.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

class EditProfileDialog extends StatefulWidget {
  final SubProfile profile;
  final VoidCallback onProfileUpdated;
  final VoidCallback? onProfileDeleted;

  const EditProfileDialog({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
    this.onProfileDeleted,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isLoading = true;
      });

      try {
        final bytes = await _selectedImage!.readAsBytes();
        final fileExt = pickedFile.path.split('.').last;
        final fileName = '${widget.profile.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        // Upload to Supabase Storage
        final supabase = Supabase.instance.client;
        await supabase.storage.from('avatars').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );

        final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

        // Update profile in database
        await ProfileService.updateProfile(widget.profile.id, _nameController.text.trim(), avatarUrl: imageUrl);
        
        final updatedProfile = widget.profile.copyWith(
          name: _nameController.text.trim(),
          avatarUrl: imageUrl,
        );
        ProfileService.setActiveProfile(updatedProfile);
        
        widget.onProfileUpdated();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    await ProfileService.updateProfile(widget.profile.id, name, avatarUrl: widget.profile.avatarUrl);
    
    final updatedProfile = widget.profile.copyWith(name: name);
    ProfileService.setActiveProfile(updatedProfile);
    
    widget.onProfileUpdated();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _isLoading ? null : _pickAndUploadImage,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.primaries[
                      (widget.profile.name.length) % Colors.primaries.length].withOpacity(0.8),
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (widget.profile.avatarUrl != null
                          ? NetworkImage(widget.profile.avatarUrl!) as ImageProvider
                          : null),
                  child: _selectedImage == null && widget.profile.avatarUrl == null
                      ? Text(
                          widget.profile.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                if (_isLoading)
                  const CircularProgressIndicator(color: AppTheme.primaryColor)
                else
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Profile Name',
              hintStyle: TextStyle(color: Colors.white54),
            ),
            enabled: !_isLoading,
          ),
        ],
      ),
      actions: [
        if (widget.onProfileDeleted != null)
          TextButton(
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() => _isLoading = true);
                    await ProfileService.deleteProfile(widget.profile.id);
                    widget.onProfileDeleted!();
                    if (mounted) Navigator.pop(context);
                  },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          onPressed: _isLoading ? null : _saveProfile,
          child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
