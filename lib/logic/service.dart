import 'dart:io';
import 'package:soundcloud_explode_dart/soundcloud_explode_dart.dart';
import 'package:tunify/database/database_helper.dart';
import 'package:http/http.dart' as http;

class MusicService {
  final SoundcloudClient _sc = SoundcloudClient();
  Future<List<Song>> searchSongs(String query) async {
    try {
      var builder = _sc.search(query, searchFilter: SearchFilter.tracks);
      List<Song> songs = [];
      await for (var batch in builder) {
        for (var item in batch) {
          if (item is TrackSearchResult) {
            String artwork = item.artworkUrl?.toString() ?? "";
            if (artwork.isNotEmpty) {
              artwork = artwork.replaceAll('large', 't500x500');
            } else {
              artwork = "https://i1.sndcdn.com/artworks-000000000000-000000-t500x500.jpg";
            }
            songs.add(Song(
              id: item.id.toString(),
              title: item.title,
              artist: item.user.username,
              artUri: artwork,
              audioUrl: item.id.toString(),
            ));
          }
        }
        if (songs.length >= 20) break;
      }
      return songs;
    } catch (e) {
      print("Lỗi tìm kiếm: $e");
      return [];
    }
  }
  Future<String> getAudioStreamUrl(String trackId) async {
    try {
      var id = int.parse(trackId);
      var streams = await _sc.tracks.getStreams(id);
      var stream = streams.firstWhere(
              (s) => !s.url.contains('.m3u8'),
          orElse: () => streams.first
      );
      return stream.url;
    } catch (e) {
      print("Lỗi lấy link stream: $e");
      return "";
    }
  }
  Future<bool> downloadTrackToFile(String trackId, String savePath) async {
    try {
      var id = int.parse(trackId);
      var streams = await _sc.tracks.getStreams(id);
      var stream = streams.firstWhere(
              (s) => !s.url.contains('.m3u8'),
          orElse: () => throw Exception("Chỉ tìm thấy HLS Stream (m3u8), không thể tải file.")
      );
      print("Đang tải từ: ${stream.url}");
      var response = await http.get(Uri.parse(stream.url));
      if (response.statusCode == 200) {
        var file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return true;
      } else {
        print("Tải thất bại: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Lỗi tải nhạc: $e");
      final file = File(savePath);
      if (await file.exists()) await file.delete();
      return false;
    }
  }
  void dispose() {
  }
}