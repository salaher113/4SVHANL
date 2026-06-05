import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sub_profile.dart';
import '../widgets/edit_profile_dialog.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  List<SubProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    final profiles = await ProfileService.getProfiles();
    setState(() {
      _profiles = profiles;
      _isLoading = false;
    });
  }

  void _selectProfile(SubProfile profile) {
    ProfileService.setActiveProfile(profile);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showAddProfileDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Add Profile', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Profile Name',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogContext);
                setState(() => _isLoading = true);
                try {
                  final newProfile = await ProfileService.createProfile(name);
                  if (newProfile != null && mounted) {
                    _selectProfile(newProfile);
                  } else {
                    throw 'فشل في إنشاء البروفايل أو بيانات غير صالحة';
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ: $e'),
                        backgroundColor: Colors.redAccent,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    await _loadProfiles();
                  }
                }
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(SubProfile profile) {
    showDialog(
      context: context,
      builder: (dialogContext) => EditProfileDialog(
        profile: profile,
        onProfileUpdated: _loadProfiles,
        onProfileDeleted: _loadProfiles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: AppTheme.primaryColor)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Who's watching?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: [
                      ..._profiles.map((p) => _buildProfileCard(p)),
                      if (_profiles.length < 5) _buildAddProfileButton(),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileCard(SubProfile profile) {
    return GestureDetector(
      onTap: () => _selectProfile(profile),
      onLongPress: () => _showEditProfileDialog(profile),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.primaries[profile.name.length % Colors.primaries.length].withOpacity(0.8),
              border: Border.all(color: Colors.transparent, width: 2),
              image: profile.avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(profile.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profile.avatarUrl == null
                ? Center(
                    child: Text(
                      profile.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProfileButton() {
    return GestureDetector(
      onTap: _showAddProfileDialog,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add Profile',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
