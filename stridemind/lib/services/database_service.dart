import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stridemind/services/firestore_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final FirestoreService _firestoreService = FirestoreService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stridemind.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversation_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        log TEXT NOT NULL,
        feedback TEXT NOT NULL, -- Storing feedback JSON as a string
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<void> addConversationTurn(Map<String, dynamic> turn) async {
    final db = await database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'conversation_history',
      {
        'log': turn['log'],
        'feedback': jsonEncode(turn['feedback']), // Encode the whole feedback object
        'timestamp': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _trimHistory();

    // Sync to Firestore for cloud backup
    await _firestoreService.addConversationTurn(turn, timestamp);
  }

  Future<List<Map<String, dynamic>>> getConversationHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversation_history',
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return {
        'id': maps[i]['id'],
        'log': maps[i]['log'],
        'feedback': jsonDecode(maps[i]['feedback']), // Decode it back
        'timestamp': maps[i]['timestamp'],
      };
    });
  }

  Future<void> _trimHistory({int maxHistoryLength = 10}) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM conversation_history'));
    if (count != null && count > maxHistoryLength) {
      final toDeleteCount = count - maxHistoryLength;
      final oldestEntries = await db.query(
        'conversation_history',
        columns: ['id'],
        orderBy: 'timestamp ASC',
        limit: toDeleteCount,
      );
      final idsToDelete = oldestEntries.map((e) => e['id']).toList();
      if (idsToDelete.isNotEmpty) {
        await db.delete(
          'conversation_history',
          where: 'id IN (${idsToDelete.join(', ')})',
        );
      }
    }
  }
}