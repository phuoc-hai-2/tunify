import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tunify/logic/service.dart';
import 'package:tunify/database/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MusicProvider extends ChangeNotifier {
  final MusicService _service = MusicService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Song> _songs = [];
  List<Song> _originalQueue = [];
  List<Song> _playQueue = [];
  final Map<String, bool> _downloadingSongs = {};

  bool _isLoading = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;

  Song? _currentSong;
  int? _currentUserId;

  List<Song> get songs => _songs;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;
  Song? get currentSong => _currentSong;
  AudioPlayer get audioPlayer => _audioPlayer;
  bool get isLoggedIn => _currentUserId != null;
  bool isDownloading(String id) => _downloadingSongs[id] ?? false;

  MusicProvider() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.completed) {
        playNext();
      } else {
        _isPlaying = isPlaying;
      }
      notifyListeners();
    });
  }
  Future<bool> login(String u, String p) async {
    final uid = await DatabaseHelper.instance.loginUser(u, p);
    if (uid != null) {
      _currentUserId = uid;
      await fetchMusic("V-Pop Hits");
      return true;
    }
    return false;
  }
  Future<bool> register(String u, String p) => DatabaseHelper.instance.registerUser(u, p);
  void logout() {
    _currentUserId = null;
    _audioPlayer.stop();
    _currentSong = null;
    _songs.clear();
    _playQueue.clear();
    notifyListeners();
  }

  Future<void> fetchMusic(String query) async {
    _isLoading = true; notifyListeners();
    try {
      _songs = await _service.searchSongs(query);
      await _syncWithDatabase();
    } catch (e) {
      if (_currentUserId != null) {
        _songs = await DatabaseHelper.instance.getFavorites(_currentUserId!);
      }
    }
    _isLoading = false; notifyListeners();
  }

  Future<void> showFavorites() async {
    if (_currentUserId == null) return;
    _isLoading = true; notifyListeners();
    _songs = await DatabaseHelper.instance.getFavorites(_currentUserId!);
    _isLoading = false; notifyListeners();
  }

  Future<void> showDownloads() async {
    if (_currentUserId == null) return;
    _isLoading = true; notifyListeners();
    _songs = await DatabaseHelper.instance.getDownloads(_currentUserId!);
    _isLoading = false; notifyListeners();
  }

  Future<void> _syncWithDatabase() async {
    if (_currentUserId == null) return;
    for (var song in _songs) {
      final saved = await DatabaseHelper.instance.getSong(_currentUserId!, song.id);
      if (saved != null) {
        song.isFavorite = saved.isFavorite;
        if (saved.localPath != null && File(saved.localPath!).existsSync()) {
          song.localPath = saved.localPath;
        } else {
          song.localPath = null;
        }
      }
    }
  }

  Future<void> toggleFavorite(Song song) async {
    if (_currentUserId == null) return;
    song.isFavorite = !song.isFavorite;
    notifyListeners();
    if (song.isFavorite) {
      await DatabaseHelper.instance.saveOrUpdateSong(_currentUserId!, song);
    } else {
      if (song.localPath == null) {
        await DatabaseHelper.instance.removeFavorite(_currentUserId!, song.id);
      } else {
        await DatabaseHelper.instance.saveOrUpdateSong(_currentUserId!, song);
      }
    }
  }

  Future<void> downloadSong(Song song) async {
    if (_currentUserId == null || isDownloading(song.id)) return;
    _downloadingSongs[song.id] = true;
    notifyListeners();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${song.id}.mp3';
      final savePath = '${dir.path}/$fileName';
      bool success = await _service.downloadTrackToFile(song.id, savePath);
      if (success) {
        song.localPath = savePath;
        await DatabaseHelper.instance.saveOrUpdateSong(_currentUserId!, song);
      }
    } finally {
      _downloadingSongs[song.id] = false;
      notifyListeners();
    }
  }

  Future<void> deleteDownloadedSong(Song song) async {
    if (_currentUserId == null || song.localPath == null) return;
    try {
      final file = File(song.localPath!);
      if (await file.exists()) {
        await file.delete();
        print("Đã xóa file: ${song.localPath}");
      }
      song.localPath = null;
      notifyListeners();
      if (!song.isFavorite) {
        await DatabaseHelper.instance.removeFavorite(_currentUserId!, song.id);
      } else {
        await DatabaseHelper.instance.saveOrUpdateSong(_currentUserId!, song);
      }
    } catch (e) {
      print("Lỗi xóa nhạc: $e");
    }
  }

  Future<void> playSong(Song song) async {
    if (!_playQueue.contains(song)) {
      _originalQueue = List.from(_songs);
      _playQueue = _isShuffle ? (List.from(_songs)..shuffle()) : List.from(_songs);
    }
    if (_currentSong?.id != song.id) {
      _currentSong = song;
      _isBuffering = true;
      notifyListeners();
      try {
        if (song.localPath != null && File(song.localPath!).existsSync()) {
          print("Phát Offline");
          await _audioPlayer.setFilePath(song.localPath!);
        } else {
          print("Phát Online");
          String url = await _service.getAudioStreamUrl(song.id);
          if (url.isNotEmpty) await _audioPlayer.setUrl(url);
          else playNext();
        }
        _audioPlayer.play();
      } catch (e) {
        print("Lỗi phát: $e");
        playNext();
      }
      _isBuffering = false;
      notifyListeners();
    } else {
      resume();
    }
  }

  void pause() { _audioPlayer.pause(); notifyListeners(); }
  void resume() { _audioPlayer.play(); notifyListeners(); }
  void seek(Duration pos) => _audioPlayer.seek(pos);
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    if (_isShuffle) _playQueue.shuffle(); else _playQueue = List.from(_originalQueue);
    notifyListeners();
  }
  void toggleRepeat() {
    _loopMode = _loopMode == LoopMode.off ? LoopMode.all : (_loopMode == LoopMode.all ? LoopMode.one : LoopMode.off);
    _audioPlayer.setLoopMode(_loopMode == LoopMode.one ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }
  void playNext() {
    if (_playQueue.isEmpty || _currentSong == null) return;
    int idx = _playQueue.indexWhere((s) => s.id == _currentSong!.id);
    if (idx < _playQueue.length - 1) playSong(_playQueue[idx + 1]);
    else if (_loopMode == LoopMode.all) playSong(_playQueue[0]);
  }
  void playPrevious() {
    if (_playQueue.isEmpty || _currentSong == null) return;
    if (_audioPlayer.position.inSeconds > 3) { _audioPlayer.seek(Duration.zero); return; }
    int idx = _playQueue.indexWhere((s) => s.id == _currentSong!.id);
    if (idx > 0) playSong(_playQueue[idx - 1]);
    else _audioPlayer.seek(Duration.zero);
  }
  @override
  void dispose() {
    _audioPlayer.dispose();
    _service.dispose();
    super.dispose();
  }
}