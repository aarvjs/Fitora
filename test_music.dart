import 'package:fitora/services/youtube_music_service.dart';

void main() async {
  print('Initializing YouTubeMusicService...');
  final service = YouTubeMusicService();
  
  try {
    print('Calling getDefaultWorkoutMusic()...');
    final videos = await service.getDefaultWorkoutMusic();
    print('SUCCESS! Found ${videos.length} videos.');
    for (var v in videos) {
      print('- ${v['title']} (${v['videoId']})');
    }
  } catch (e) {
    print('CAUGHT EXCEPTION: $e');
  }
}
