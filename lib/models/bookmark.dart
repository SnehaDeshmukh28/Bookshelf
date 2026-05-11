class Bookmark {
  final String id;
  final String bookId;
  final int pageNumber;
  final String label;
  final DateTime createdDate;

  Bookmark({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    required this.label,
    DateTime? createdDate,
  }) : createdDate = createdDate ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'book_id': bookId,
        'page_number': pageNumber,
        'label': label,
        'created_date': createdDate.millisecondsSinceEpoch,
      };

  factory Bookmark.fromMap(Map<String, dynamic> map) => Bookmark(
        id: map['id'] as String,
        bookId: map['book_id'] as String,
        pageNumber: map['page_number'] as int,
        label: map['label'] as String,
        createdDate:
            DateTime.fromMillisecondsSinceEpoch(map['created_date'] as int),
      );
}
