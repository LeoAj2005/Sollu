import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../data/models/song_with_lyrics.dart';
import '../../core/constants/constants.dart';

class StorageService {
  static const _table = 'lyrics';
  
  late Database _db;
  bool _isInitialized = false;
  
  Future<void> init() async {
    if (_isInitialized) return;
    
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);
    
    _db = await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            lyrics TEXT,
            syncedLyrics TEXT,
            lyricsType TEXT NOT NULL,
            fetchedAt TEXT NOT NULL
          )
        ''');
      },
    );
    _isInitialized = true;
  }
  
  Future<void> insertLyrics(SongWithLyrics lyrics) async {
    await init();
    await _db.insert(
      _table,
      lyrics.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<SongWithLyrics?> getLyrics(String id) async {
    await init();
    final maps = await _db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return SongWithLyrics.fromJson(maps.first);
  }
  
  Future<List<SongWithLyrics>> getAllLyrics() async {
    await init();
    final maps = await _db.query(_table, orderBy: 'fetchedAt DESC');
    return maps.map((map) => SongWithLyrics.fromJson(map)).toList();
  }
  
  Future<void> deleteLyrics(String id) async {
    await init();
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}