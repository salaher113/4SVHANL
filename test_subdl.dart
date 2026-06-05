import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Test TMDB ID for Inception (27205)
  final url = 'https://api.subdl.com/api/v1/subtitles?tmdb_id=27205';
  try {
    final res = await http.get(Uri.parse(url));
    print(res.statusCode);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      print(json['results']?.first);
    } else {
      print(res.body);
    }
  } catch (e) {
    print('Error: $e');
  }
}
