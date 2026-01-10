class Note {
  final String id;
  final String itemId;
  final String text;

  const Note({
    required this.id,
    required this.itemId,
    required this.text,
  });

  Note copyWith({
    String? id,
    String? itemId,
    String? text,
  }) {
    return Note(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      text: text ?? this.text,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'text': text,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      itemId: map['item_id'] as String? ?? map['itemId'] as String,
      text: map['text'] as String,
    );
  }
}

