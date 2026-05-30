import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:dio/dio.dart';
import './dio_client.dart';

class OfflineQueueService {
  static Database? _database;

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

    final dio = DioClient().instance;

    for (var item in maps) {
      try {
        final endpoint = item['endpoint'] as String;
        final method = item['method'] as String;
        final bodyJson = item['body'] as String;
        final body = jsonDecode(bodyJson);

        Response response;
        if (method.toUpperCase() == 'POST') {
          response = await dio.post(endpoint, data: body);
        } else if (method.toUpperCase() == 'PUT') {
          response = await dio.put(endpoint, data: body);
        } else if (method.toUpperCase() == 'DELETE') {
          response = await dio.delete(endpoint, data: body);
        } else {
          response = await dio.get(endpoint, queryParameters: body);
        }

        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          // Remove from queue after success
          await db.delete('queue', where: 'id = ?', whereArgs: [item['id']]);
          print('✅ Sync success for $endpoint');
        } else {
          print('⚠️ Sync returned non-2xx code for $endpoint: ${response.statusCode}');
          break; // Stop syncing to preserve order
        }
      } catch (e) {
        print('❌ Sync failed for ${item['endpoint']}: $e');
        break; // Keep in queue for next retry, stop sync to maintain order of operations
      }
    }
  }
}
