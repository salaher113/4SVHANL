import 'package:http/http.dart' as http;
void main() async {
  try {
    final res = await http.get(Uri.parse('https://vidsrc.rip/embed/movie/299534'));
    print(res.body);
  } catch(e) {}
}
