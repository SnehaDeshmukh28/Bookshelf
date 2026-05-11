import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<Directory> get _booksDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'books'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> get _coversDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'covers'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies a PDF from [sourcePath] into app storage and returns the new path.
  Future<String> savePdf(String sourcePath, String bookId) async {
    final booksDir = await _booksDir;
    final ext = p.extension(sourcePath);
    final dest = File(p.join(booksDir.path, '$bookId$ext'));
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  /// Returns the path where a cover image for [bookId] should be saved.
  Future<String> coverPath(String bookId) async {
    final coversDir = await _coversDir;
    return p.join(coversDir.path, '$bookId.png');
  }

  /// Deletes the PDF and cover for a book.
  Future<void> deleteBook(String bookId, String filePath) async {
    try {
      final pdf = File(filePath);
      if (await pdf.exists()) await pdf.delete();
      final cover = File(await coverPath(bookId));
      if (await cover.exists()) await cover.delete();
    } catch (_) {}
  }

  Future<bool> fileExists(String path) => File(path).exists();

  Future<int> totalStorageBytes() async {
    final booksDir = await _booksDir;
    int total = 0;
    await for (final entity in booksDir.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
