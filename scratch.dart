import 'package:http/http.dart' as http;
void main() async {
  try {
    print("Fetching...");
    var res = await http.get(Uri.parse('https://vidlink.pro/api/movie/299534')).timeout(Duration(seconds: 10));
    print("Status: ${res.statusCode}");
    print("Body: ${res.body}");
  } catch (e) {
    print("Error: $e");
  }
}
