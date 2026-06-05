import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Inception IMDB: tt1375666
  final url = 'https://rest.opensubtitles.org/search/imdbid-1375666/sublanguageid-ara';
  try {
    final res = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'TemporaryUserAgent', // OpenSubtitles requires a User-Agent
    });
    print(res.statusCode);
    if (res.statusCode == 200) {
      final jsonList = jsonDecode(res.body) as List;
      if (jsonList.isNotEmpty) {
        print(jsonList.first['SubDownloadLink']);
      }
    } else {
      print(res.body);
    }
  } catch (e) {
    print('Error: $e');
  }
}
