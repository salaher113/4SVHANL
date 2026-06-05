import 'package:flutter/material.dart';
import '../../models/iptv_channel.dart';
import '../../theme/app_theme.dart';
import 'package:dpad/dpad.dart';
import '../../screens/search_screen.dart';
import '../../services/profile_service.dart';
import '../../screens/profile_selection_screen.dart';
import '../../models/sub_profile.dart';
import '../edit_profile_dialog.dart';

class HomeHeader extends StatelessWidget {
  final bool isMobile;
  final int navIndex;
  final List<IPTVPlaylistSource> sources;
  final String? selectedSourceId;
  final VoidCallback onSourcePick;
  final double hPad;

  const HomeHeader({
    super.key,
    required this.isMobile,
    required this.navIndex,
    required this.sources,
    required this.selectedSourceId,
    required this.onSourcePick,
    required this.hPad,
  });

  @override
  Widget build(BuildContext context) {
    final titles = ['Movies', 'Series', 'Live TV', 'Favorites', 'Settings'];
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, isMobile ? 54 : 36, hPad, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isMobile) ...[
            Image.asset(
              'assets/الوجو الذي يوجد في الصفحة الرئيسة.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 24,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(width: 16),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (navIndex == 0 || navIndex == 1) ...[
                Image.asset('assets/HOMELOGO.png', height: 28, fit: BoxFit.contain),
                const SizedBox(height: 4),
              ],
              Text(
                navIndex < titles.length ? titles[navIndex] : '',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (navIndex == 2 && sources.isNotEmpty)
            _SourcePill(
              label: sources.firstWhere(
                (s) => s.id == selectedSourceId,
                orElse: () => sources.first,
              ).name,
              onTap: onSourcePick,
            ),
          if (navIndex == 0 || navIndex == 1)
            DpadFocusable(
              onSelect: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(type: navIndex == 0 ? 'movie' : 'series')));
              },
              builder: (context, isFocused, child) {
                return IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: isFocused ? AppTheme.primaryColor : Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen(type: navIndex == 0 ? 'movie' : 'series')));
                  },
                );
              },
            ),
          const SizedBox(width: 12),
          _ProfileDropdownMenu(),
        ],
      ),
    );
  }
}

class _ProfileDropdownMenu extends StatefulWidget {
  @override
  State<_ProfileDropdownMenu> createState() => _ProfileDropdownMenuState();
}

class _ProfileDropdownMenuState extends State<_ProfileDropdownMenu> {
  @override
  Widget build(BuildContext context) {
    final activeProfile = ProfileService.activeProfile;
    final initial = activeProfile?.name.isNotEmpty == true 
        ? activeProfile!.name.substring(0, 1).toUpperCase() 
        : 'U';

    return PopupMenuButton<String>(
      color: AppTheme.surfaceColor,
      offset: const Offset(0, 48),
      onSelected: (value) async {
        if (value == 'edit') {
          _showEditProfileDialog();
        } else if (value == 'switch') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
            (route) => false,
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: const [
              Icon(Icons.edit, color: Colors.white70, size: 20),
              SizedBox(width: 12),
              Text('Edit Profile', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'switch',
          child: Row(
            children: const [
              Icon(Icons.switch_account, color: Colors.white70, size: 20),
              SizedBox(width: 12),
              Text('Switch Profile', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.primaries[
            (activeProfile?.name.length ?? 0) % Colors.primaries.length].withOpacity(0.8),
        child: Text(
          initial,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final activeProfile = ProfileService.activeProfile;
    if (activeProfile == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => EditProfileDialog(
        profile: activeProfile,
        onProfileUpdated: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SourcePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      onSelect: onTap,
      builder: (context, isFocused, child) {
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isFocused
                  ? AppTheme.primaryColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFocused
                    ? AppTheme.primaryColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: isFocused ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.playlist_play_rounded,
                    size: 16,
                    color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isFocused ? FontWeight.w600 : FontWeight.w400,
                      color: isFocused
                          ? AppTheme.primaryColor
                          : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: isFocused
                        ? AppTheme.primaryColor.withOpacity(0.8)
                        : Colors.white.withOpacity(0.5)),
              ],
            ),
          ),
        );
      },
    );
  }
}