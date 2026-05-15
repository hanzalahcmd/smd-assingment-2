import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_module/models/forum_reply.dart';

// ──────────────────────────────────────────────
// Abstract contract
// ──────────────────────────────────────────────

abstract class IReplyRepository {
  /// Real-time stream of replies for a given topic.
  Stream<List<ForumReply>> watchReplies(String topicId);

  /// Adds a reply. Returns the new document id.
  Future<String> addReply(ForumReply reply);
}

// ──────────────────────────────────────────────
// Firestore implementation
// ──────────────────────────────────────────────

class ReplyRepository implements IReplyRepository {
  ReplyRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _collection = 'replies';

  CollectionReference<Map<String, dynamic>> get _replies =>
      _db.collection(_collection);

  @override
  Stream<List<ForumReply>> watchReplies(String topicId) => _replies
      .where('topicId', isEqualTo: topicId)
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs.map(ForumReply.fromFirestore).toList());

  @override
  Future<String> addReply(ForumReply reply) async {
    try {
      final ref = await _replies.add(reply.toFirestore());
      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception('Failed to post reply: ${e.message}');
    }
  }
}
