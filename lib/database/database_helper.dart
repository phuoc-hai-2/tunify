import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// ===================== MODEL SONG =====================
class Song {
  final String id;
  final String title;
  final String artist;
  final String artUri;
  final String audioUrl; // Lưu ý: Đây là VideoID của YouTube
  final String? localPath;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.artUri,
    required this.audioUrl,
    this.localPath,
  });

  // Chuyển dữ liệu từ Video YouTube sang Song
  factory Song.fromYoutube(Video video) {
    return Song(
      id: video.id.value,
      title: video.title,
      artist: video.author,
      // Lấy ảnh thumbnail chất lượng cao nhất
      artUri: video.thumbnails.highResUrl,
      audioUrl: video.id.value,
    );
  }

  // Để lưu vào SQLite (nếu cần sau này)
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
    _database = await _initDB('tunify_youtube.db');
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