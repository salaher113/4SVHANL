import 'dart:io';
import 'dart:convert';
void main() async {
  var req = await HttpClient().getUrl(Uri.parse('https://api.themoviedb.org/3/watch/providers/tv?api_key=4544b6f120d2a452fcac20b9c3f2b404'));
  var res = await req.close();
  var str = await res.transform(utf8.decoder).join();
  var data = jsonDecode(str);
  var results = data['results'] as List;
  var ids = [8, 337, 1899, 2, 119, 15, 531, 283];
  for (var id in ids) {
    var p = results.firstWhere((p) => p['provider_id'] == id, orElse: () => null);
    if (p != null) print(p['provider_name'] + ': ' + p['logo_path']);
  }
}
