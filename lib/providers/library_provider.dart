import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../models/book.dart';
import '../models/highlight.dart';
import '../models/bookmark.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

enum LibraryStatus { idle, loading, error }

class LibraryProvider extends ChangeNotifier {
  final _db = DatabaseService();
  final _storage = StorageService();
  final _uuid = const Uuid();

  List<Book> _books = [];
  LibraryStatus _status = LibraryStatus.idle;
  String? _errorMessage;

  List<Book> get books => _books;
  LibraryStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == LibraryStatus.loading;

  Future<void> loadBooks() async {
    _status = LibraryStatus.loading;
    notifyListeners();
    try {
      _books = await _db.getAllBooks();
      // Remove books whose files have been deleted externally
      final valid = <Book>[];
      for (final book in _books) {
        if (await _storage.fileExists(book.filePath)) {
          valid.add(book);
        } else {
          await _db.deleteBook(book.id);
        }
      }
      _books = valid;
      _status = LibraryStatus.idle;
    } catch (e) {
      _errorMessage = e.toString();
      _status = LibraryStatus.error;
    }
    notifyListeners();
  }

  /// Opens the system file picker, copies the PDF into app storage, and saves.
  Future<Book?> importPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final sourcePath = file.path;
    if (sourcePath == null) return null;

    _status = LibraryStatus.loading;
    notifyListeners();

    try {
      final id = _uuid.v4();
      final storedPath = await _storage.savePdf(sourcePath, id);
      final title = p.basenameWithoutExtension(file.name);

      final book = Book(
        id: id,
        title: title,
        filePath: storedPath,
        addedDate: DateTime.now(),
      );
      await _db.insertBook(book);
      _books.insert(0, book);
      _status = LibraryStatus.idle;
      notifyListeners();
      return book;
    } catch (e) {
      _errorMessage = e.toString();
      _status = LibraryStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<void> updateReadingProgress(
      String bookId, int page, int totalPages) async {
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx == -1) return;
    final updated = _books[idx].copyWith(
      currentPage: page,
      totalPages: totalPages,
      lastRead: DateTime.now(),
    );
    _books[idx] = updated;
    await _db.updateBook(updated);
    notifyListeners();
  }

  Future<void> deleteBook(String bookId) async {
    final book = _books.firstWhere((b) => b.id == bookId);
    await _storage.deleteBook(bookId, book.filePath);
    await _db.deleteBook(bookId);
    _books.removeWhere((b) => b.id == bookId);
    notifyListeners();
  }

  Future<void> renameBook(String bookId, String newTitle) async {
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx == -1) return;
    final updated = Book(
      id: _books[idx].id,
      title: newTitle,
      filePath: _books[idx].filePath,
      addedDate: _books[idx].addedDate,
      lastRead: _books[idx].lastRead,
      currentPage: _books[idx].currentPage,
      totalPages: _books[idx].totalPages,
      coverPath: _books[idx].coverPath,
    );
    _books[idx] = updated;
    await _db.updateBook(updated);
    notifyListeners();
  }

  // ── Highlights ─────────────────────────────────────────────────────────────

  Future<List<Highlight>> getHighlights(String bookId) =>
      _db.getHighlightsForBook(bookId);

  Future<Highlight> addHighlight({
    required String bookId,
    required int pageNumber,
    required String text,
    required int colorValue,
  }) async {
    final h = Highlight(
      id: _uuid.v4(),
      bookId: bookId,
      pageNumber: pageNumber,
      text: text,
      colorValue: colorValue,
    );
    await _db.insertHighlight(h);
    return h;
  }

  Future<void> deleteHighlight(String highlightId) =>
      _db.deleteHighlight(highlightId);

  // ── Bookmarks ──────────────────────────────────────────────────────────────

  Future<List<Bookmark>> getBookmarks(String bookId) =>
      _db.getBookmarksForBook(bookId);

  Future<Bookmark> addBookmark({
    required String bookId,
    required int pageNumber,
    required String label,
  }) async {
    final b = Bookmark(
      id: _uuid.v4(),
      bookId: bookId,
      pageNumber: pageNumber,
      label: label,
    );
    await _db.insertBookmark(b);
    return b;
  }

  Future<void> deleteBookmark(String bookmarkId) =>
      _db.deleteBookmark(bookmarkId);

  Future<bool> isPageBookmarked(String bookId, int page) =>
      _db.isPageBookmarked(bookId, page);
}
