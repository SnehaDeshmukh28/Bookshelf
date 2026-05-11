import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';
import '../models/highlight.dart';
import '../models/bookmark.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'bookshelf.db'),
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL,
        added_date INTEGER NOT NULL,
        last_read INTEGER NOT NULL,
        current_page INTEGER DEFAULT 1,
        total_pages INTEGER DEFAULT 0,
        cover_path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE highlights (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        text TEXT NOT NULL,
        color INTEGER NOT NULL,
        created_date INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        label TEXT NOT NULL,
        created_date INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_highlights_book ON highlights(book_id)');
    await db.execute('CREATE INDEX idx_bookmarks_book ON bookmarks(book_id)');
    await _createAiCacheTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createAiCacheTable(db);
  }

  Future<void> _createAiCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_cache (
        query_key TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        response TEXT NOT NULL,
        source TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ai_cache ON ai_cache(book_id, page_number)');
  }

  // ── Books ──────────────────────────────────────────────────────────────────

  Future<void> insertBook(Book book) async {
    final db = await database;
    await db.insert('books', book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Book>> getAllBooks() async {
    final db = await database;
    final maps = await db.query('books', orderBy: 'last_read DESC');
    return maps.map(Book.fromMap).toList();
  }

  Future<void> updateBook(Book book) async {
    final db = await database;
    await db.update('books', book.toMap(),
        where: 'id = ?', whereArgs: [book.id]);
  }

  Future<void> deleteBook(String bookId) async {
    final db = await database;
    await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
    await db.delete('highlights', where: 'book_id = ?', whereArgs: [bookId]);
    await db.delete('bookmarks', where: 'book_id = ?', whereArgs: [bookId]);
  }

  // ── Highlights ─────────────────────────────────────────────────────────────

  Future<void> insertHighlight(Highlight highlight) async {
    final db = await database;
    await db.insert('highlights', highlight.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Highlight>> getHighlightsForBook(String bookId) async {
    final db = await database;
    final maps = await db.query('highlights',
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'page_number ASC, created_date ASC');
    return maps.map(Highlight.fromMap).toList();
  }

  Future<List<Highlight>> getHighlightsForPage(
      String bookId, int pageNumber) async {
    final db = await database;
    final maps = await db.query('highlights',
        where: 'book_id = ? AND page_number = ?',
        whereArgs: [bookId, pageNumber]);
    return maps.map(Highlight.fromMap).toList();
  }

  Future<void> deleteHighlight(String highlightId) async {
    final db = await database;
    await db.delete('highlights', where: 'id = ?', whereArgs: [highlightId]);
  }

  // ── Bookmarks ──────────────────────────────────────────────────────────────

  Future<void> insertBookmark(Bookmark bookmark) async {
    final db = await database;
    await db.insert('bookmarks', bookmark.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Bookmark>> getBookmarksForBook(String bookId) async {
    final db = await database;
    final maps = await db.query('bookmarks',
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'page_number ASC');
    return maps.map(Bookmark.fromMap).toList();
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    final db = await database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [bookmarkId]);
  }

  Future<bool> isPageBookmarked(String bookId, int pageNumber) async {
    final db = await database;
    final result = await db.query('bookmarks',
        where: 'book_id = ? AND page_number = ?',
        whereArgs: [bookId, pageNumber],
        limit: 1);
    return result.isNotEmpty;
  }

  // ── AI Cache ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getAiCache(String queryKey) async {
    final db = await database;
    final rows = await db.query('ai_cache',
        where: 'query_key = ?', whereArgs: [queryKey], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> setAiCache({
    required String queryKey,
    required String bookId,
    required int pageNumber,
    required String response,
    required String source,
  }) async {
    final db = await database;
    await db.insert(
      'ai_cache',
      {
        'query_key': queryKey,
        'book_id': bookId,
        'page_number': pageNumber,
        'response': response,
        'source': source,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearAiCache(String bookId) async {
    final db = await database;
    await db.delete('ai_cache', where: 'book_id = ?', whereArgs: [bookId]);
  }
}
