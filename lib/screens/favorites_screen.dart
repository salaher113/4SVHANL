import 'package:flutter/material.dart';
import '../models/favorite_item.dart';
import '../services/favorite_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common/status_widgets.dart';
import 'content_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final bool isMobile;
  final double hPad;

  const FavoritesScreen({
    super.key,
    required this.isMobile,
    required this.hPad,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<FavoriteItem> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final favs = await FavoriteService.getFavorites();
    if (mounted) {
      setState(() {
        _favorites = favs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_favorites.isEmpty) {
      return const Center(
        child: Text(
          'No favorites yet.\nStart adding movies and series!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: widget.isMobile ? 110 : 100),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.hPad, vertical: 10),
          child: Text(
            'My Favorites',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(widget.hPad, 10, widget.hPad, 30),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.isMobile ? 3 : 5,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
              final fav = _favorites[index];
              return _buildFavoriteCard(fav);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteCard(FavoriteItem fav) {
    return GestureDetector(
      onTap: () async {
        if (fav.itemType == 'movie' || fav.itemType == 'tv') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContentDetailScreen(
                contentId: fav.itemId,
                isMovie: fav.itemType == 'movie',
              ),
            ),
          );
          _loadFavorites(); // Refresh on back
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withOpacity(0.05),
          image: fav.posterPath != null
              ? DecorationImage(
                  image: NetworkImage(fav.posterPath!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        alignment: Alignment.bottomLeft,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Text(
            fav.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
