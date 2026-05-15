import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a reply to a [ForumTopic].
class ForumReply {
  final String id;
  final String topicId;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  const ForumReply({
    required this.id,
    required this.topicId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });

  factory ForumReply.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ForumReply(
      id: doc.id,
      topicId: data['topicId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Unknown',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'topicId': topicId,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForumReply &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
