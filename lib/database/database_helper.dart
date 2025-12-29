// lib/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// Import thư viện SoundCloud (không cần 'as sc' ở đây nếu không dùng Container)
import 'package:soundcloud_explode_dart/soundcloud_explode_dart.dart';

// ... (Phần còn lại giữ nguyên như code cũ tôi đã gửi)

// ===================== MODEL SONG =====================
class Song {
  final String id;
  final String title;
  final String artist;
  final String artUri;
  final String audioUrl;
  final String? localPath;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.artUri,
    required this.audioUrl,
    this.localPath,
  });

  // --- LOGIC MỚI: Đã thêm .toString() để sửa lỗi Object -> String ---
  factory Song.fromSoundCloud(Track track) {
    // 1. Xử lý ảnh bìa an toàn (chấp nhận cả String hoặc Uri)
    String artwork = track.artworkUrl?.toString() ?? "";

    if (artwork.isNotEmpty) {
      artwork = artwork.replaceAll('large', 't500x500');
    } else {
      // Ảnh mặc định
      artwork = "https://i1.sndcdn.com/artworks-000000000000-000000-t500x500.jpg";
    }

    return Song(
      id: track.id.toString(),
      // 2. Thêm .toString() để đảm bảo không bị lỗi kiểu dữ liệu
      title: track.title.toString(),
      artist: track.user.username.toString(),
      artUri: artwork,
      audioUrl: track.id.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artUri': artUri,
      'audioUrl': audioUrl,
      'localPath': localPath,
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
    _database = await _initDB('tunify_sc_v2.db'); // Đổi tên DB để tránh cache cũ
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE songs (
      id TEXT PRIMARY KEY,
      title TEXT,
      artist TEXT,
      artUri TEXT,
      audioUrl TEXT,
      localPath TEXT
    )
    ''');
  }
}