import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../logic/service.dart';
import '../database/database_helper.dart';

class MusicProvider extends ChangeNotifier {
  final MusicService _service = MusicService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- TRẠNG THÁI ---
  List<Song> _songs = [];
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Song? _currentSong;

  // --- GETTERS ---
  List<Song> get songs => _songs;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Song? get currentSong => _currentSong;
  AudioPlayer get audioPlayer => _audioPlayer;

  // --- INIT ---
  MusicProvider() {
    _initAudioPlayer();
    // Mặc định tìm nhạc Chill khi mở app
    fetchMusic("Lofi Chill");
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.completed) {
        _isPlaying = false;
        _audioPlayer.pause();
        _audioPlayer.seek(Duration.zero);
        notifyListeners();
      } else {
        _isPlaying = isPlaying;
      }
      notifyListeners();
    });
  }

  // --- TÌM KIẾM ---
  Future<void> fetchMusic(String query) async {
    _isLoading = true;
    _songs = [];
    notifyListeners();

    try {
      _songs = await _service.searchSongs(query);
    } catch (e) {
      print("Provider Error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- PHÁT NHẠC ---
  Future<void> playSong(Song song) async {
    // Nếu chọn bài mới
    if (_currentSong?.id != song.id) {
      _currentSong = song;
      _isBuffering = true;
      notifyListeners();

      try {
        // Lấy link từ SoundCloud Service
        String streamUrl = await _service.getAudioStreamUrl(song.id);

        if (streamUrl.isNotEmpty) {
          await _audioPlayer.setUrl(streamUrl);
          _audioPlayer.play();
        } else {
          print("Không lấy được link stream.");
        }
      } catch (e) {
        print("Play Error: $e");
      }

      _isBuffering = false;
      notifyListeners();
    }
    // Nếu bấm lại bài đang phát -> Toggle Pause/Play
    else {
      if (_isPlaying) {
        pause();
      } else {
        resume();
      }
    }
  }

  // --- ĐIỀU KHIỂN ---
  void pause() {
    _audioPlayer.pause();
    notifyListeners();
  }

  void resume() {
    _audioPlayer.play();
    notifyListeners();
  }

  void seek(Duration pos) => _audioPlayer.seek(pos);

  @override
  void dispose() {
    _audioPlayer.dispose();
    _service.dispose();
    super.dispose();
  }
}