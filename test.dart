import 'dart:io';

void main() async {
  var url = 'https://t0.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://www.disneyplus.com&size=128';
  try {
    var req = await HttpClient().getUrl(Uri.parse(url));
    var res = await req.close();
    print(res.statusCode);
  } catch(e) {
    print('ERROR: \$e');
  }
}
