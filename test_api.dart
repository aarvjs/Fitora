import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'AIzaSyCQyptZlxqfhOIplBnv3KxW3VkbFfyMz0U';
  final url = Uri.parse('https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=1&q=workout&key=$apiKey');
  
  print('Fetching YouTube API...');
  try {
    final res = await http.get(url);
    print('STATUS CODE: ${res.statusCode}');
    if (res.statusCode != 200) {
      print('ERROR BODY: ${res.body}');
    } else {
      print('SUCCESS! Response length: ${res.body.length}');
      final data = json.decode(res.body);
      final items = data['items'] as List;
      print('Found ${items.length} items.');
    }
  } catch(e) {
    print('EXCEPTION: $e');
  }
}
