import 'package:soundcloud_explode_dart/soundcloud_explode_dart.dart' as sc;
import '../../database/database_helper.dart';

class MusicService {
  final sc.SoundcloudClient _sc = sc.SoundcloudClient();

  // --- TÌM KIẾM ---
  Future<List<Song>> searchSongs(String query) async {
    try {
      // Tìm kiếm Tracks
      var builder = _sc.search(query, searchFilter: sc.SearchFilter.tracks);

      List<Song> songs = [];

      await for (var batch in builder) {
        for (var item in batch) {
          // Chỉ cần xử lý đúng loại TrackSearchResult
          if (item is sc.TrackSearchResult) {
            // Xử lý ảnh bìa
            String artwork = item.artworkUrl?.toString() ?? "";
            if (artwork.isNotEmpty) {
              artwork = artwork.replaceAll('large', 't500x500');
            } else {
              artwork = "https://i1.sndcdn.com/artworks-000000000000-000000-t500x500.jpg";
            }

            // Tạo đối tượng Song thủ công từ kết quả tìm kiếm
            songs.add(Song(
              id: item.id.toString(),
              title: item.title.toString(),
              artist: item.user.username.toString(),
              artUri: artwork,
              audioUrl: item.id.toString(),
            ));
          }
          // ĐÃ XÓA đoạn "else if (item is sc.Track)" vì nó gây ra lỗi
        }

        // Chỉ lấy lô kết quả đầu tiên (khoảng 10-20 bài)
        if (songs.isNotEmpty) break;
      }

      return songs;
    } catch (e) {
      print("Lỗi tìm kiếm SoundCloud: $e");
      return [];
    }
  }

  // --- LẤY LINK STREAM ---
  Future<String> getAudioStreamUrl(String trackId) async {
    try {
      final trackIdInt = int.parse(trackId);
      final streams = await _sc.tracks.getStreams(trackIdInt);

      // Lấy link stream đầu tiên tìm thấy
      if (streams.isNotEmpty) {
        final firstStream = streams.first;
        print("Stream URL: ${firstStream.url}");
        return firstStream.url.toString();
      }

      return "";
    } catch (e) {
      print("Lỗi lấy link stream ($trackId): $e");
      return "";
    }
  }

  void dispose() { }
}