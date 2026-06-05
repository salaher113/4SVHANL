import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://vidlink.pro/api/movie/27205';
  try {
    final res = await http.get(Uri.parse(url), headers: {'Referer': 'https://vidlink.pro/'});
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      print(jsonEncode(json));
    } else {
      print('Failed: ${res.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
