import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../logic/service.dart';
import '../database/database_helper.dart';

class MusicProvider extends ChangeNotifier {
  final MusicService _service = MusicService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- Biến trạng thái ---
  List<Song> _songs = [];
  bool _isLoading = false;      // Đang tìm kiếm
  bool _isPlaying = false;      // Đang phát nhạc
  bool _isBuffering = false;    // Đang tải link nhạc (quan trọng với YouTube)
  Song? _currentSong;

  // --- Getters ---
  List<Song> get songs => _songs;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Song? get currentSong => _currentSong;
  AudioPlayer get audioPlayer => _audioPlayer;

  // --- Khởi tạo ---
  MusicProvider() {
    _initAudioPlayer();
    // Tự động tìm nhạc hot khi mở app
    fetchMusic("V-Pop Hits");
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.completed) {
        _isPlaying = false;
        _audioPlayer.pause();
        _audioPlayer.seek(Duration.zero);
      } else {
        _isPlaying = isPlaying;
      }
      notifyListeners();
    });
  }

  // --- Tìm kiếm ---
  Future<void> fetchMusic(String query) async {
    _isLoading = true;
    _songs = [];
    notifyListeners();

    try {
      _songs = await _service.searchSongs(query);
    } catch (e) {
      print("Lỗi Provider: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Phát nhạc (Logic chính) ---
  Future<void> playSong(Song song) async {
    // Nếu chọn bài mới
    if (_currentSong?.id != song.id) {
      _currentSong = song;
      _isBuffering = true; // Bắt đầu xoay vòng loading ở MiniPlayer
      notifyListeners();

      try {
        // Bước 1: Lấy link stream thật từ YouTube (Mất 1-2s)
        final String streamUrl = await _service.getAudioStreamUrl(song.id);

        if (streamUrl.isNotEmpty) {
          // Bước 2: Load link và phát
          await _audioPlayer.setUrl(streamUrl);
          _audioPlayer.play();
        } else {
          print("Không lấy được link stream");
        }
      } catch (e) {
        print("Lỗi phát nhạc: $e");
      }

      _isBuffering = false; // Tắt vòng loading
      notifyListeners();
    } else {
      // Nếu bấm vào bài đang hát -> Toggle Play/Pause
      if (_isPlaying) {
        _audioPlayer.pause();
      } else {
        _audioPlayer.play();
      }
    }
  }

  void pause() => _audioPlayer.pause();
  void resume() => _audioPlayer.play();

  @override
  void dispose() {
    _audioPlayer.dispose();
    _service.dispose();
    super.dispose();
  }
}