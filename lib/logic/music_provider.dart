import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math';
import '../logic/service.dart';
import '../database/database_helper.dart';

class MusicProvider extends ChangeNotifier {
  final MusicService _service = MusicService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- DATA ---
  List<Song> _songs = [];          // Danh sách bài hát đang hiển thị (Search hoặc Favorites)
  List<Song> _originalQueue = [];  // Hàng đợi gốc (dùng khi tắt shuffle)
  List<Song> _playQueue = [];      // Hàng đợi thực tế đang phát (có thể đã shuffle)

  // --- STATE ---
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isShuffle = false;      // Chế độ Xáo trộn
  LoopMode _loopMode = LoopMode.off; // Chế độ Lặp (off, one, all)

  Song? _currentSong;

  // --- GETTERS ---
  List<Song> get songs => _songs;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;
  Song? get currentSong => _currentSong;
  AudioPlayer get audioPlayer => _audioPlayer;

  // --- INIT ---
  MusicProvider() {
    _initAudioPlayer();
    loadFavorites(); // Tải danh sách yêu thích lúc mở app để check trái tim
    fetchMusic("V-Pop Hits");
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.completed) {
        // TỰ ĐỘNG NEXT BÀI
        playNext();
      } else {
        _isPlaying = isPlaying;
      }
      notifyListeners();
    });
  }

  // --- QUẢN LÝ DANH SÁCH & TÌM KIẾM ---
  Future<void> fetchMusic(String query) async {
    _isLoading = true;
    notifyListeners();
    try {
      _songs = await _service.searchSongs(query);
      // Kiểm tra xem các bài hát này có trong yêu thích không
      await _checkFavoritesStatus();
    } catch (e) {
      print("Provider Error: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  // Chuyển sang xem danh sách yêu thích
  Future<void> showFavorites() async {
    _isLoading = true;
    notifyListeners();
    _songs = await DatabaseHelper.instance.getFavorites();
    _checkFavoritesStatus(); // Đánh dấu true cho tất cả
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _checkFavoritesStatus() async {
    for (var song in _songs) {
      song.isFavorite = await DatabaseHelper.instance.isFavorite(song.id);
    }
  }

  // --- LOGIC YÊU THÍCH (TIM) ---
  Future<void> toggleFavorite(Song song) async {
    if (song.isFavorite) {
      await DatabaseHelper.instance.removeFavorite(song.id);
      song.isFavorite = false;
    } else {
      await DatabaseHelper.instance.addFavorite(song);
      song.isFavorite = true;
    }

    // Nếu đang ở màn hình Favorites thì reload lại list để bài hát biến mất ngay
    // (Tuỳ logic, ở đây ta chỉ notify để cập nhật icon)
    notifyListeners();
  }

  // --- PHÁT NHẠC & ĐIỀU KHIỂN ---

  Future<void> playSong(Song song) async {
    // Cập nhật Queue mỗi khi chọn bài từ danh sách mới
    if (!_playQueue.contains(song)) {
      _originalQueue = List.from(_songs); // Lưu danh sách gốc
      if (_isShuffle) {
        _playQueue = List.from(_songs)..shuffle();
      } else {
        _playQueue = List.from(_songs);
      }
    }

    if (_currentSong?.id != song.id) {
      _currentSong = song;
      _isBuffering = true;
      notifyListeners();

      try {
        String streamUrl = await _service.getAudioStreamUrl(song.id);
        if (streamUrl.isNotEmpty) {
          await _audioPlayer.setUrl(streamUrl);
          _audioPlayer.play();
        }
      } catch (e) {
        print("Play Error: $e");
        playNext(); // Lỗi thì tự qua bài
      }

      _isBuffering = false;
      notifyListeners();
    } else {
      resume();
    }
  }

  void pause() {
    _audioPlayer.pause();
    notifyListeners();
  }

  void resume() {
    _audioPlayer.play();
    notifyListeners();
  }

  void seek(Duration pos) => _audioPlayer.seek(pos);

  // --- LOGIC NEXT / PREVIOUS / SHUFFLE / REPEAT ---

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    if (_isShuffle) {
      // Bật Shuffle: Xáo trộn danh sách phát
      _playQueue.shuffle();
    } else {
      // Tắt Shuffle: Quay về thứ tự gốc
      _playQueue = List.from(_originalQueue);
    }
    notifyListeners();
  }

  void toggleRepeat() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.all; // Lặp danh sách
    } else if (_loopMode == LoopMode.all) {
      _loopMode = LoopMode.one; // Lặp 1 bài
    } else {
      _loopMode = LoopMode.off; // Tắt lặp
    }
    // JustAudio hỗ trợ loopOne natived, nhưng loopAll ta tự xử lý ở Next
    if (_loopMode == LoopMode.one) {
      _audioPlayer.setLoopMode(LoopMode.one);
    } else {
      _audioPlayer.setLoopMode(LoopMode.off);
    }
    notifyListeners();
  }

  void playNext() {
    if (_playQueue.isEmpty || _currentSong == null) return;

    int currentIndex = _playQueue.indexWhere((s) => s.id == _currentSong!.id);

    // Logic Next
    if (currentIndex < _playQueue.length - 1) {
      playSong(_playQueue[currentIndex + 1]);
    } else {
      // Đã hết danh sách
      if (_loopMode == LoopMode.all) {
        // Nếu Loop All -> Quay lại bài đầu
        playSong(_playQueue[0]);
      } else {
        // Dừng lại
        _audioPlayer.pause();
        _audioPlayer.seek(Duration.zero);
      }
    }
  }

  void playPrevious() {
    if (_playQueue.isEmpty || _currentSong == null) return;

    // Nếu đã phát được hơn 3s thì prev sẽ tua lại đầu bài
    if (_audioPlayer.position.inSeconds > 3) {
      _audioPlayer.seek(Duration.zero);
      return;
    }

    int currentIndex = _playQueue.indexWhere((s) => s.id == _currentSong!.id);
    if (currentIndex > 0) {
      playSong(_playQueue[currentIndex - 1]);
    } else {
      // Đang ở bài đầu tiên -> Về lại đầu bài
      _audioPlayer.seek(Duration.zero);
    }
  }

  // Hàm phụ để load tim khi mở app
  Future<void> loadFavorites() async {
    // Chỉ chạy ngầm để cache
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _service.dispose();
    super.dispose();
  }
}