import 'package:http/http.dart' as http;
void main() async {
  final urls = [
    'https://embed.su/embed/movie/299534',
    'https://vidsrc.cc/v2/embed/movie/299534',
    'https://vidsrc.xyz/embed/movie/299534',
    'https://vidsrc.net/embed/movie/299534'
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
        if (res.body.length > 500) print("First 200 chars: ${res.body.substring(0, 200)}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}
