import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../models/streamengine/stream_models.dart';
import '../utils/log_util.dart';

class SubtitleFetcherService {
  static const String _tag = 'SubtitleFetcher';
  static const String _subdlApiKey = 'EjyOg8QVC4w0e0xOzgTwclt2FxZT-g1-';

  static Future<List<VideoSourceSubtitle>> fetchArabicSubtitles(String tmdbId, {int? season, int? episode}) async {
    if (tmdbId.isEmpty) return [];

    final wyzieFuture = _fetchWyzie(tmdbId, season: season, episode: episode);
    final subdlFuture = _fetchSubdl(tmdbId, season: season, episode: episode);

    final results = await Future.wait([wyzieFuture, subdlFuture]);
    
    // Merge results: Wyzie first, then Subdl
    return [...results[0], ...results[1]];
  }

  static Future<List<VideoSourceSubtitle>> _fetchWyzie(String tmdbId, {int? season, int? episode}) async {
    String url = 'https://sub.wyzie.io/search?id=$tmdbId&language=ar&key=wyzie-3b6280cfbd23705ecceac9edbef3a797';
    if (season != null && episode != null) {
      url += '&s=$season&e=$episode';
    }
    
    List<VideoSourceSubtitle> results = [];
    try {
      final res = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      }).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          final validList = data.where((e) {
            final u = e['url'] ?? e['file'] ?? e['link'];
            return u != null && u.toString().isNotEmpty;
          }).take(4).toList(); // Take top 4 from Wyzie
          
          for (var i = 0; i < validList.length; i++) {
            final e = validList[i];
            final subUrl = e['url'] ?? e['file'] ?? e['link'];
            results.add(VideoSourceSubtitle(
              label: 'Wyzie: Arabic ${i + 1}',
              file: subUrl,
            ));
          }
        }
      }
    } catch (e) {
      logE('Failed to fetch Wyzie Arabic subtitles', tag: _tag, error: e);
    }
    return results;
  }

  static Future<List<VideoSourceSubtitle>> _fetchSubdl(String tmdbId, {int? season, int? episode}) async {
    String url = 'https://api.subdl.com/api/v1/subtitles?api_key=$_subdlApiKey&tmdb_id=$tmdbId&languages=ar';
    if (season != null && episode != null) {
      url += '&type=tv&season_number=$season&episode_number=$episode';
    } else {
      url += '&type=movie';
    }
    
    List<VideoSourceSubtitle> results = [];
    try {
      final res = await http.get(Uri.parse(url), headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true && data['subtitles'] != null) {
          final List subtitlesList = data['subtitles'];
          final validList = subtitlesList.where((e) => e['url'] != null).take(4).toList(); // Take top 4 from Subdl
          final tempDir = await getTemporaryDirectory();
          
          for (var i = 0; i < validList.length; i++) {
            final subObj = validList[i];
            final subZipUrl = 'https://dl.subdl.com/subtitle/${subObj['url']}';
            final releaseName = subObj['release_name'] ?? 'Arabic ${i + 1}';
            
            try {
              final zipRes = await http.get(Uri.parse(subZipUrl)).timeout(const Duration(seconds: 15));
              if (zipRes.statusCode == 200) {
                final archive = ZipDecoder().decodeBytes(zipRes.bodyBytes);
                ArchiveFile? subtitleFile;
                for (final file in archive) {
                  if (file.isFile && (file.name.toLowerCase().endsWith('.srt') || file.name.toLowerCase().endsWith('.vtt'))) {
                    subtitleFile = file;
                    break;
                  }
                }
                
                if (subtitleFile != null) {
                  final extractedPath = '${tempDir.path}/subdl_${DateTime.now().millisecondsSinceEpoch}_${subtitleFile.name}';
                  final file = File(extractedPath);
                  await file.writeAsBytes(subtitleFile.content as List<int>);
                  results.add(VideoSourceSubtitle(
                    label: 'Subdl: $releaseName',
                    file: 'file://$extractedPath',
                  ));
                }
              }
            } catch (e) {
              logE('Error downloading/extracting zip from $subZipUrl', tag: _tag, error: e);
            }
          }
        }
      }
    } catch (e) {
      logE('Failed to fetch Subdl Arabic subtitles', tag: _tag, error: e);
    }
    return results;
  }
}

