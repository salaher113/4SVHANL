import 'package:http/http.dart' as http;
void main() async {
  final urls = [
    'https://vidsrc.rip/embed/movie/299534',
    'https://vidsrc.pro/embed/movie/299534',
    'https://vidsrc.in/embed/movie/299534',
    'https://vidsrc.pm/embed/movie/299534',
    'https://embed.smashystream.com/playere.php?tmdb=299534',
    'https://multiembed.mov/?video_id=299534&tmdb=1'
  ];
  for (var url in urls) {
    try {
      print("Testing $url");
      final res = await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
      print("Status: ${res.statusCode}");
      if (res.body.contains('cloudflare') || res.body.contains('Just a moment')) {
        print("Cloudflare detected");
      } else {
        print("Success! Body length: ${res.body.length}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}
