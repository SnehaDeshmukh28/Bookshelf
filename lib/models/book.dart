class Book {
  final String id;
  final String title;
  final String filePath;
  final DateTime addedDate;
  DateTime lastRead;
  int currentPage;
  int totalPages;
  String? coverPath;

  Book({
    required this.id,
    required this.title,
    required this.filePath,
    required this.addedDate,
    DateTime? lastRead,
    this.currentPage = 1,
    this.totalPages = 0,
    this.coverPath,
  }) : lastRead = lastRead ?? addedDate;

  double get progress =>
      totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'file_path': filePath,
        'added_date': addedDate.millisecondsSinceEpoch,
        'last_read': lastRead.millisecondsSinceEpoch,
        'current_page': currentPage,
        'total_pages': totalPages,
        'cover_path': coverPath,
      };

  factory Book.fromMap(Map<String, dynamic> map) => Book(
        id: map['id'] as String,
        title: map['title'] as String,
        filePath: map['file_path'] as String,
        addedDate: DateTime.fromMillisecondsSinceEpoch(map['added_date'] as int),
        lastRead: DateTime.fromMillisecondsSinceEpoch(map['last_read'] as int),
        currentPage: map['current_page'] as int? ?? 1,
        totalPages: map['total_pages'] as int? ?? 0,
        coverPath: map['cover_path'] as String?,
      );

  Book copyWith({
    int? currentPage,
    int? totalPages,
    DateTime? lastRead,
    String? coverPath,
  }) =>
      Book(
        id: id,
        title: title,
        filePath: filePath,
        addedDate: addedDate,
        lastRead: lastRead ?? this.lastRead,
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        coverPath: coverPath ?? this.coverPath,
      );
}
