import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:soundcloud_explode_dart/soundcloud_explode_dart.dart';

// ===================== MODEL SONG =====================
class Song {
  final String id;
  final String title;
  final String artist;
  final String artUri;
  final String audioUrl;
  // Thêm biến để check xem bài này có phải yêu thích không (dùng cho UI)
  bool isFavorite;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.artUri,
    required this.audioUrl,
    this.isFavorite = false,
  });

  factory Song.fromSoundCloud(Track track) {
    String artwork = track.artworkUrl?.toString() ?? "";
    if (artwork.isNotEmpty) {
      artwork = artwork.replaceAll('large', 't500x500');
    } else {
      artwork = "https://i1.sndcdn.com/artworks-000000000000-000000-t500x500.jpg";
    }

    return Song(
      id: track.id.toString(),
      title: track.title.toString(),
      artist: track.user.username.toString(),
      artUri: artwork,
      audioUrl: track.id.toString(),
    );
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      artUri: map['artUri'],
      audioUrl: map['audioUrl'],
      isFavorite: true, // Nếu lấy từ bảng favorites ra thì mặc định là true
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artUri': artUri,
      'audioUrl': audioUrl,
    };
  }
}

// ===================== DATABASE HELPER =====================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tunify_final_v1.db'); // Đổi tên DB mới
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tạo bảng yêu thích
    await db.execute('''
    CREATE TABLE favorites (
      id TEXT PRIMARY KEY,
      title TEXT,
      artist TEXT,
      artUri TEXT,
      audioUrl TEXT
    )
    ''');
  }

  // --- CRUD FAVORITES ---
  Future<void> addFavorite(Song song) async {
    final db = await instance.database;
    await db.insert('favorites', song.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFavorite(String id) async {
    final db = await instance.database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Song>> getFavorites() async {
    final db = await instance.database;
    final result = await db.query('favorites');
    return result.map((json) => Song.fromMap(json)).toList();
  }

  Future<bool> isFavorite(String id) async {
    final db = await instance.database;
    final result = await db.query('favorites', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty;
  }
}