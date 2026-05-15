import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_module/models/forum_topic.dart';

// ──────────────────────────────────────────────
// Abstract contract
// ──────────────────────────────────────────────

abstract class IForumRepository {
  /// Real-time stream of all topics, newest first.
  Stream<List<ForumTopic>> watchTopics();

  /// Fetches topics once (for initial load / pull-to-refresh).
  Future<List<ForumTopic>> fetchTopics();

  /// Creates a new topic and returns its Firestore-assigned id.
  Future<String> createTopic(ForumTopic topic);

  /// Increments the reply counter on a topic (called after a reply is added).
  Future<void> incrementReplyCount(String topicId);
}

// ──────────────────────────────────────────────
// Firestore implementation
// ──────────────────────────────────────────────

class ForumRepository implements IForumRepository {
  ForumRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _collection = 'topics';

  CollectionReference<Map<String, dynamic>> get _topics =>
      _db.collection(_collection);

  @override
  Stream<List<ForumTopic>> watchTopics() => _topics
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ForumTopic.fromFirestore).toList());

  @override
  Future<List<ForumTopic>> fetchTopics() async {
    final snap =
        await _topics.orderBy('createdAt', descending: true).get();
    return snap.docs.map(ForumTopic.fromFirestore).toList();
  }

  @override
  Future<String> createTopic(ForumTopic topic) async {
    try {
      final ref = await _topics.add(topic.toFirestore());
      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception('Failed to create topic: ${e.message}');
    }
  }

  @override
  Future<void> incrementReplyCount(String topicId) async {
    try {
      await _topics
          .doc(topicId)
          .update({'replyCount': FieldValue.increment(1)});
    } on FirebaseException catch (e) {
      throw Exception('Failed to update reply count: ${e.message}');
    }
  }
}
