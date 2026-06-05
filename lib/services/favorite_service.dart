import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favorite_item.dart';
import 'profile_service.dart';

class FavoriteService {
  static final _supabase = Supabase.instance.client;

  static Future<List<FavoriteItem>> getFavorites() async {
    final profileId = ProfileService.activeProfile?.id;
    if (profileId == null) return [];

    try {
      final response = await _supabase
          .from('favorites')
          .select()
          .eq('sub_profile_id', profileId)
          .order('created_at', ascending: false);

      final data = response as List;
      return data.map((e) => FavoriteItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> isFavorite(String itemId) async {
    final profileId = ProfileService.activeProfile?.id;
    if (profileId == null) return false;

    try {
      final response = await _supabase
          .from('favorites')
          .select()
          .eq('sub_profile_id', profileId)
          .eq('item_id', itemId);

      final data = response as List;
      return data.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> toggleFavorite({
    required String itemId,
    required String itemType,
    required String title,
    String? posterPath,
  }) async {
    final profileId = ProfileService.activeProfile?.id;
    if (profileId == null) return false;

    try {
      final isFav = await isFavorite(itemId);
      if (isFav) {
        await _supabase
            .from('favorites')
            .delete()
            .eq('sub_profile_id', profileId)
            .eq('item_id', itemId);
        return false;
      } else {
        await _supabase.from('favorites').insert({
          'sub_profile_id': profileId,
          'item_id': itemId,
          'item_type': itemType,
          'title': title,
          'poster_path': posterPath,
        });
        return true;
      }
    } catch (e) {
      return false;
    }
  }
}
