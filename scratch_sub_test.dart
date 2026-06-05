import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final urls = [
    'https://sub.wyzie.io/search?id=278&language=en&key=wyzie-3b6280cfbd23705ecceac9edbef3a797', // TMDB ID, EN
    'https://sub.wyzie.io/search?id=tt0111161&language=en&key=wyzie-3b6280cfbd23705ecceac9edbef3a797', // IMDB ID, EN
  ];
  
  for (final urlStr in urls) {
    final url = Uri.parse(urlStr);
    print('\nFetching: $url');
    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      }).timeout(const Duration(seconds: 15));
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
    } catch (e) {
      print('Error: $e');
    }
  }
}
