import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a top-level forum discussion thread.
class ForumTopic {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int replyCount;

  const ForumTopic({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.replyCount = 0,
  });

  factory ForumTopic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ForumTopic(
      id: doc.id,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Unknown',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      replyCount: data['replyCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': Timestamp.fromDate(createdAt),
        'replyCount': replyCount,
      };

  ForumTopic copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    int? replyCount,
  }) =>
      ForumTopic(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        createdAt: createdAt ?? this.createdAt,
        replyCount: replyCount ?? this.replyCount,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForumTopic &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
