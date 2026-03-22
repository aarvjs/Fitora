import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitora/core/config/api_keys.dart';

class YouTubeMusicService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3/search';
  
  // In-memory cache to prevent redundant API queries
  final Map<String, List<Map<String, String>>> _cache = {};

  /// Searches for YouTube videos using the provided query.
  /// Returns a list of maps containing videoId, title, thumbnail, and channelTitle.
  Future<List<Map<String, String>>> searchVideos(String query) async {
    if (ApiKeys.youtubeApiKey == 'YOUR_YOUTUBE_API_KEY_HERE') {
      // Return dummy data or throw an error if the key isn't set.
      // For demonstration, we'll throw an exception so the UI knows to show an error,
      // but if you prefer fallback dummy data to prevent crashes while testing without a key, you could return it here.
      throw Exception('YouTube API Key is missing. Please add it to lib/core/config/api_keys.dart');
    }

    final queryKey = query.trim().toLowerCase();
    if (_cache.containsKey(queryKey)) {
      return _cache[queryKey]!;
    }

    try {
      final url = Uri.parse(
          '$_baseUrl?part=snippet&type=video&maxResults=15&q=${Uri.encodeComponent('$query workout music')}&key=${ApiKeys.youtubeApiKey}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        final parsedItems = items.map((item) {
          final snippet = item['snippet'];
          return {
            'videoId': item['id']['videoId']?.toString() ?? '',
            'title': snippet['title']?.toString() ?? 'Unknown Title',
            'channelTitle': snippet['channelTitle']?.toString() ?? 'Unknown Artist',
            'thumbnail': snippet['thumbnails']?['high']?['url']?.toString() ??
                snippet['thumbnails']?['medium']?['url']?.toString() ??
                snippet['thumbnails']?['default']?['url']?.toString() ??
                '',
          };
        }).cast<Map<String, String>>().toList();

        _cache[queryKey] = parsedItems;
        return parsedItems;
      } else {
        throw Exception('Failed to load music: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Returns some default curated workout music to show before searching.
  Future<List<Map<String, String>>> getDefaultWorkoutMusic() async {
    return searchVideos('Gym motivation workout songs');
  }
}
