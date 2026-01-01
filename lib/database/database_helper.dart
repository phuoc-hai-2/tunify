import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:soundcloud_explode_dart/soundcloud_explode_dart.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String artUri;
  final String audioUrl;
  bool isFavorite;
  String? localPath;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.artUri,
    required this.audioUrl,
    this.isFavorite = false,
    this.localPath,
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
      title: track.title,
      artist: track.user.username,
      artUri: artwork,
      audioUrl: track.id.toString(),
    );
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['songId'],
      title: map['title'],
      artist: map['artist'],
      artUri: map['artUri'],
      audioUrl: map['audioUrl'],
      isFavorite: map['isFavorite'] == 1,
      localPath: map['localPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'songId': id,
      'title': title,
      'artist': artist,
      'artUri': artUri,
      'audioUrl': audioUrl,
      'localPath': localPath,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tunify.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE,
      password TEXT
    )
    ''');
    await db.execute('''
    CREATE TABLE favorites (
      user_id INTEGER,
      songId TEXT,
      title TEXT,
      artist TEXT,
      artUri TEXT,
      audioUrl TEXT,
      localPath TEXT,
      isFavorite INTEGER,
      PRIMARY KEY (user_id, songId)
    )
    ''');
  }
  Future<bool> registerUser(String username, String password) async {
    final db = await instance.database;
    try {
      await db.insert('users', {'username': username, 'password': password});
      return true;
    } catch (e) { return false; }
  }

  Future<int?> loginUser(String username, String password) async {
    final db = await instance.database;
    final result = await db.query('users', columns: ['id'], where: 'username = ? AND password = ?', whereArgs: [username, password]);
    if (result.isNotEmpty) return result.first['id'] as int;
    return null;
  }

  Future<void> saveOrUpdateSong(int userId, Song song) async {
    final db = await instance.database;
    final map = song.toMap();
    map['user_id'] = userId;
    await db.insert('favorites', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFavorite(int userId, String songId) async {
    final db = await instance.database;
    await db.delete('favorites', where: 'user_id = ? AND songId = ?', whereArgs: [userId, songId]);
  }

  Future<List<Song>> getFavorites(int userId) async {
    final db = await instance.database;
    final result = await db.query('favorites', where: 'user_id = ? AND isFavorite = 1', whereArgs: [userId]);
    return result.map((json) => Song.fromMap(json)).toList();
  }

  Future<List<Song>> getDownloads(int userId) async {
    final db = await instance.database;
    final result = await db.query('favorites', where: 'user_id = ? AND localPath IS NOT NULL', whereArgs: [userId]);
    return result.map((json) => Song.fromMap(json)).toList();
  }

  Future<Song?> getSong(int userId, String songId) async {
    final db = await instance.database;
    final result = await db.query('favorites', where: 'user_id = ? AND songId = ?', whereArgs: [userId, songId]);
    if (result.isNotEmpty) return Song.fromMap(result.first);
    return null;
  }
}