import 'package:http/http.dart' as http;
import 'dart:convert';
void main() async {
  final urls = [
    'https://vidsrc.me/embed/movie?tmdb=299534',
    'https://vidsrc.to/embed/movie/299534',
    'https://autoembed.cc/movie/tmdb/299534'
  ];
  for (var url in urls) {
    try {
      print("Testing $url");
      final res = await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
      print("Status: ${res.statusCode}");
      if (res.body.contains('cloudflare') || res.body.contains('Just a moment')) {
        print("Cloudflare detected");
      } else {
        print("Success?");
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}
