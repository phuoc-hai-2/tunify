import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../database/database_helper.dart';

class MusicService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<List<Song>> searchSongs(String query) async {
    try {
      final result = await _yt.search.search(query);
      return result.map((video) => Song.fromYoutube(video)).toList();
    } catch (e) {
      print("Lỗi tìm kiếm: $e");
      return [];
    }
  }

  // --- ĐÃ SỬA LẠI HÀM NÀY ĐỂ FIX LỖI KHÔNG NGHE ĐƯỢC ---
  Future<String> getAudioStreamUrl(String videoId) async {
    try {
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // FIX: Ưu tiên lấy định dạng MP4 (AAC) để dễ chạy trên mọi máy
      var audioStream = manifest.audioOnly.firstWhere(
              (stream) => stream.container == StreamContainer.mp4,
          // Nếu không có MP4 thì lấy luồng audio bất kỳ có bitrate cao nhất
          orElse: () => manifest.audioOnly.withHighestBitrate()
      );

      print("Đã lấy được Link nhạc: ${audioStream.url}"); // In ra để debug
      return audioStream.url.toString();
    } catch (e) {
      print("Lỗi lấy link stream: $e");
      return "";
    }
  }

  void dispose() {
    _yt.close();
  }
}
