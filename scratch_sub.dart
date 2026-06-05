import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Deadpool & Wolverine TMDB ID: 533535
  final url = Uri.parse('https://sub.wyzie.io/search?id=533535&language=en&key=wyzie-3b6280cfbd23705ecceac9edbef3a797');
  
  try {
    final response = await http.get(url, headers: {
      'User-Agent': 'Mozilla/5.0',
    }).timeout(const Duration(seconds: 15));
    
    print('Status: ${response.statusCode}');
    if (response.body.length > 500) {
      print('Response: ${response.body.substring(0, 500)}...');
    } else {
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
