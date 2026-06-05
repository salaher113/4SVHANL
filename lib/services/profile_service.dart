import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sub_profile.dart';

class ProfileService {
  static final _supabase = Supabase.instance.client;

  /// Fetch all profiles for the current user
  static Future<List<SubProfile>> getProfiles() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('sub_profiles')
          .select()
          .eq('user_id', userId)
          .order('created_at');
          
      final data = response as List;
      return data.map((e) => SubProfile.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching profiles: $e');
      return [];
    }
  }

  /// Create a new profile
  static Future<SubProfile?> createProfile(String name, {String? avatarUrl}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw 'User is not logged in. ID is null.';

    try {
      final response = await _supabase.from('sub_profiles').insert({
        'user_id': userId,
        'name': name,
        'avatar_url': avatarUrl,
      }).select().single();

      return SubProfile.fromJson(response);
    } catch (e) {
      print('Error creating profile: $e');
      throw e.toString();
    }
  }

  /// Update an existing profile
  static Future<bool> updateProfile(String id, String name, {String? avatarUrl}) async {
    try {
      await _supabase.from('sub_profiles').update({
        'name': name,
        'avatar_url': avatarUrl,
      }).eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a profile
  static Future<bool> deleteProfile(String id) async {
    try {
      await _supabase.from('sub_profiles').delete().eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Active Profile State Management
  static SubProfile? _activeProfile;
  static SubProfile? get activeProfile => _activeProfile;

  static void setActiveProfile(SubProfile profile) {
    _activeProfile = profile;
  }
}
