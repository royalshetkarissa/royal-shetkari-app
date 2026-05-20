import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'api_service.dart';

class OfflineQueueService {
  static Database? _database;
  final ApiService _api = ApiService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'offline_queue.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            endpoint TEXT,
            method TEXT,
            body TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  /**
   * Add a request to the offline queue.
   */
  Future<void> enqueueRequest(String endpoint, String method, Map<String, dynamic> body) async {
    final db = await database;
    await db.insert('queue', {
      'endpoint': endpoint,
      'method': method,
      'body': jsonEncode(body),
    });
    print('📦 Request queued offline: $endpoint');
  }

  /**
   * Sync all queued requests when back online.
   */
  Future<void> syncQueue() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('queue', orderBy: 'timestamp ASC');

    if (maps.isEmpty) return;

    print('🔄 Syncing ${maps.length} offline requests...');

    for (var item in maps) {
      try {
        // This is a simplified sync logic. In a real app, you'd handle
        // specific endpoints and methods via your ApiService.
        // await _api.performRequest(item['endpoint'], item['method'], jsonDecode(item['body']));
        
        // Remove from queue after success
        await db.delete('queue', where: 'id = ?', whereArgs: [item['id']]);
      } catch (e) {
        print('❌ Sync failed for ${item['endpoint']}: $e');
        // Keep in queue for next retry
      }
    }
  }
}
