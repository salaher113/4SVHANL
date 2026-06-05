import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://api.subdl.com/api/v1/subtitles?tmdb_id=27205&languages=ar';
  try {
    final res = await http.get(Uri.parse(url));
    print('Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      print(json['results']?.first);
      print(json['subtitles']?.first);
    } else {
      print(res.body);
    }
  } catch (e) {
    print('Error: $e');
  }
}
