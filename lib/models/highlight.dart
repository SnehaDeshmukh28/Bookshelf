import 'package:flutter/material.dart';

class Highlight {
  final String id;
  final String bookId;
  final int pageNumber;
  final String text;
  final int colorValue;
  final DateTime createdDate;

  Highlight({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    required this.text,
    required this.colorValue,
    DateTime? createdDate,
  }) : createdDate = createdDate ?? DateTime.now();

  Color get color => Color(colorValue);

  static const Map<String, int> highlightColors = {
    'Yellow': 0xFFFFEB3B,
    'Green': 0xFF66BB6A,
    'Blue': 0xFF42A5F5,
    'Pink': 0xFFF48FB1,
    'Orange': 0xFFFFB74D,
  };

  Map<String, dynamic> toMap() => {
        'id': id,
        'book_id': bookId,
        'page_number': pageNumber,
        'text': text,
        'color': colorValue,
        'created_date': createdDate.millisecondsSinceEpoch,
      };

  factory Highlight.fromMap(Map<String, dynamic> map) => Highlight(
        id: map['id'] as String,
        bookId: map['book_id'] as String,
        pageNumber: map['page_number'] as int,
        text: map['text'] as String,
        colorValue: map['color'] as int,
        createdDate:
            DateTime.fromMillisecondsSinceEpoch(map['created_date'] as int),
      );
}
