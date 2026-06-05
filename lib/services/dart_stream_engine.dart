import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/streamengine/stream_models.dart';
import '../utils/log_util.dart';

class DartStreamEngine {
  static const _apiKey = 'd291fe8f037ef9810820029059b1dfe2';
  static const _baseUrl = 'https://api.themoviedb.org/3';
  static const _imageBase = 'https://image.tmdb.org/t/p/';

  static Future<Map<String, dynamic>> _get(String endpoint, {Map<String, String>? params}) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: {
      'api_key': _apiKey,
      ...?params,
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('TMDB API Error: ${response.statusCode} - ${response.body}');
    }
  }

  static String? _img(String? path, [String size = 'w500']) {
    if (path == null || path.isEmpty) return null;
    return '$_imageBase$size$path';
  }

  static Map<String, dynamic>? _mapMultiItem(Map<String, dynamic> item) {
    final mediaType = item['media_type'];
    if (mediaType == 'movie' || item.containsKey('title')) {
      return {
        'id': item['id']?.toString(),
        'title': item['title'],
        'overview': item['overview'],
        'released': item['release_date'],
        'rating': item['vote_average'],
        'poster': _img(item['poster_path']),
        'banner': _img(item['backdrop_path'], 'original'),
      };
    } else if (mediaType == 'tv' || item.containsKey('name')) {
      return {
        'id': item['id']?.toString(),
        'title': item['name'],
        'overview': item['overview'],
        'released': item['first_air_date'],
        'rating': item['vote_average'],
        'poster': _img(item['poster_path']),
        'banner': _img(item['backdrop_path'], 'original'),
        'seasons': [],
      };
    }
    return null;
  }

  static Future<List<StreamItem>> getTmdbList(String endpoint, {int page = 1, String language = 'en'}) async {
    try {
      final sanitized = endpoint.startsWith('/') ? endpoint : '/$endpoint';
      final res = await _get(sanitized, params: {
        'language': language,
        'page': page.toString(),
      });
      final results = res['results'] as List?;
      if (results == null) return [];
      
      return results.map((e) {
        final mapped = _mapMultiItem(e as Map<String, dynamic>);
        if (mapped == null) return null;
        return StreamItem.fromJson(mapped);
      }).whereType<StreamItem>().toList();
    } catch (e, st) {
      logE('DartTmdb getTmdbList failed', tag: 'DartStreamEngine', error: e, stackTrace: st);
      return [];
    }
  }

  static Future<List<StreamCategory>> getHome({String? language, String? section}) async {
    return [];
  }

  static Future<List<StreamItem>> discover({
    required String type,
    required Map<String, String> params,
    int page = 1,
    String language = 'en',
  }) async {
    try {
      final endpoint = type == 'movie' ? '/discover/movie' : '/discover/tv';
      final res = await _get(endpoint, params: {
        'language': language,
        'page': page.toString(),
        ...params,
      });
      final results = res['results'] as List?;
      if (results == null) return [];
      
      return results.map((e) {
        final mapped = _mapMultiItem(e as Map<String, dynamic>);
        if (mapped == null) return null;
        return StreamItem.fromJson(mapped);
      }).whereType<StreamItem>().toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<StreamItem>> search(String query, {String language = 'en', int page = 1}) async {
    try {
      if (query.isEmpty) return [];
      final res = await _get('/search/multi', params: {
        'query': query,
        'language': language,
        'page': page.toString(),
      });
      final results = res['results'] as List?;
      if (results == null) return [];
      
      return results.map((e) {
        final mapped = _mapMultiItem(e as Map<String, dynamic>);
        if (mapped == null) return null;
        return StreamItem.fromJson(mapped);
      }).whereType<StreamItem>().toList();
    } catch (e) {
      return [];
    }
  }

  static Future<StreamMovie?> getMovieDetails(String id, {String language = 'en'}) async {
    try {
      final res = await _get('/movie/$id', params: {
        'language': language,
        'append_to_response': 'credits,recommendations,videos,external_ids',
      });
      
      String? trailerUrl;
      final videos = res['videos']?['results'] as List?;
      if (videos != null) {
        final yt = videos.firstWhere((v) => v['site'] == 'YouTube', orElse: () => null);
        if (yt != null) trailerUrl = 'https://www.youtube.com/watch?v=${yt['key']}';
      }

      final mapped = {
        'id': res['id']?.toString(),
        'title': res['title'],
        'overview': res['overview'],
        'released': res['release_date'],
        'rating': res['vote_average'],
        'poster': _img(res['poster_path']),
        'banner': _img(res['backdrop_path'], 'original'),
        'runtime': res['runtime'],
        'trailer': trailerUrl,
        'imdbId': res['external_ids']?['imdb_id'],
        'cast': (res['credits']?['cast'] as List?)?.map((c) => {
          'id': c['id']?.toString(),
          'name': c['name'],
          'image': _img(c['profile_path']),
        }).toList(),
        'recommendations': (res['recommendations']?['results'] as List?)?.map((r) => _mapMultiItem(r as Map<String, dynamic>)).toList(),
      };
      
      return StreamMovie.fromJson(mapped);
    } catch (e) {
      return null;
    }
  }

  static Future<StreamTvShow?> getTvShowDetails(String id, {String language = 'en'}) async {
    try {
      final res = await _get('/tv/$id', params: {
        'language': language,
        'append_to_response': 'credits,recommendations,videos,external_ids',
      });
      
      String? trailerUrl;
      final videos = res['videos']?['results'] as List?;
      if (videos != null) {
        final yt = videos.firstWhere((v) => v['site'] == 'YouTube', orElse: () => null);
        if (yt != null) trailerUrl = 'https://www.youtube.com/watch?v=${yt['key']}';
      }

      final mapped = {
        'id': res['id']?.toString(),
        'title': res['name'],
        'overview': res['overview'],
        'released': res['first_air_date'],
        'rating': res['vote_average'],
        'poster': _img(res['poster_path']),
        'banner': _img(res['backdrop_path'], 'original'),
        'trailer': trailerUrl,
        'imdbId': res['external_ids']?['imdb_id'],
        'seasons': (res['seasons'] as List?)?.map((s) => {
          'id': '${res['id']}-${s['season_number']}',
          'number': s['season_number'],
          'title': s['name'],
          'poster': _img(s['poster_path']),
        }).toList(),
        'cast': (res['credits']?['cast'] as List?)?.map((c) => {
          'id': c['id']?.toString(),
          'name': c['name'],
          'image': _img(c['profile_path']),
        }).toList(),
        'recommendations': (res['recommendations']?['results'] as List?)?.map((r) => _mapMultiItem(r as Map<String, dynamic>)).toList(),
      };
      
      return StreamTvShow.fromJson(mapped);
    } catch (e) {
      return null;
    }
  }

  static Future<List<StreamEpisode>> getEpisodes(String seasonId, {String language = 'en'}) async {
    try {
      final parts = seasonId.split('-');
      if (parts.length != 2) return [];
      final tvId = parts[0];
      final sNum = parts[1];

      final res = await _get('/tv/$tvId/season/$sNum', params: {
        'language': language,
      });

      final eps = res['episodes'] as List?;
      if (eps == null) return [];

      return eps.map((e) => StreamEpisode.fromJson({
        'id': e['id']?.toString(),
        'number': e['episode_number'],
        'title': e['name'],
        'overview': e['overview'],
        'released': e['air_date'],
        'poster': _img(e['still_path']),
      })).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<StreamGenre?> getGenre(String id, {int page = 1, String language = 'en'}) async {
    return null;
  }

  static Future<StreamPeople?> getPeople(String id, {int page = 1, String language = 'en'}) async {
    return null;
  }

  static Future<List<VideoServer>> getServers(
    String id, {
    required String type,
    String language = 'en',
    String? tvShowId,
    int? seasonNumber,
    int? episodeNumber,
    String? episodeId,
  }) async {
    final serverId = 'vidlink_$id';
    final serverName = 'VidLink (Global)';
    
    String srcUrl = '';
    if (type == 'movie') {
      srcUrl = 'https://vidlink.pro/movie/$id';
    } else {
      srcUrl = 'https://vidlink.pro/tv/${tvShowId ?? id}/$seasonNumber/$episodeNumber';
    }

    return [
      VideoServer.fromJson({
        'id': serverId,
        'name': serverName,
        'src': srcUrl,
      })
    ];
  }

  static Future<VideoSource?> extractVideo(VideoServer server, {String language = 'en'}) async {
    if (server.src.contains('vidlink')) {
      final parts = server.src.split('/');
      final isMovie = server.src.contains('/movie/');
      if (isMovie) {
        final tmdbId = parts.last;
        return _extractVidlink(tmdbId);
      } else {
        final tmdbId = parts[parts.length - 3];
        final sNum = parts[parts.length - 2];
        final eNum = parts.last;
        return _extractVidlink(tmdbId, season: sNum, episode: eNum);
      }
    }
    return null;
  }

  static Future<VideoSource?> _extractVidlink(String tmdbId, {String? season, String? episode}) async {
    try {
      final url = season != null && episode != null
          ? 'https://vidlink.pro/api/tv/$tmdbId/$season/$episode'
          : 'https://vidlink.pro/api/movie/$tmdbId';
      
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final streamData = json['stream'];
        if (streamData != null && streamData['multi'] != null) {
          final mainUrl = streamData['multi']['main']?['url'];
          if (mainUrl != null) {
            return VideoSource.fromJson({
              'source': mainUrl,
              'headers': {'Referer': 'https://vidlink.pro/'},
            });
          }
        }
      }
    } catch (e) {
      logE('VidLink extract failed', tag: 'DartStreamEngine', error: e);
    }
    return null;
  }
}
