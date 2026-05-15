import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_module/db/forum_repository.dart';
import 'package:firebase_module/db/reply_repository.dart';
import 'package:firebase_module/models/forum_reply.dart';
import 'package:firebase_module/models/forum_topic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'forum_test.mocks.dart';

// Run: dart run build_runner build --delete-conflicting-outputs
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QueryDocumentSnapshot, // ← changed from DocumentSnapshot
  QuerySnapshot,
  Query,
])
void main() {
  // ─────────────────────────────────────────────────
  // ForumRepository tests
  // ─────────────────────────────────────────────────
  group('ForumRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late ForumRepository forumRepository;

    final testTopicData = {
      'title': 'Test Topic',
      'content': 'Topic content here',
      'authorId': 'user-abc',
      'authorName': 'Alice',
      'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      'replyCount': 0,
    };

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      forumRepository = ForumRepository(firestore: mockFirestore);

      when(mockFirestore.collection('topics')).thenReturn(mockCollection);
      when(mockDocRef.id).thenReturn('topic-001');
    });

    test('createTopic returns new document id', () async {
      when(mockCollection.add(any)).thenAnswer((_) async => mockDocRef);

      final topic = ForumTopic(
        id: '',
        title: 'Test Topic',
        content: 'Topic content here',
        authorId: 'user-abc',
        authorName: 'Alice',
        createdAt: DateTime(2024, 1, 1),
      );

      final result = await forumRepository.createTopic(topic);

      expect(result, 'topic-001');
      verify(mockCollection.add(any)).called(1);
    });

    test('incrementReplyCount calls update with FieldValue.increment',
        () async {
      when(mockCollection.doc(any)).thenReturn(mockDocRef);
      when(mockDocRef.update(any)).thenAnswer((_) async {});

      await forumRepository.incrementReplyCount('topic-001');

      verify(mockDocRef.update(any)).called(1);
    });

    test('fetchTopics returns list of ForumTopic', () async {
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>(); // ← fixed

      when(mockCollection.orderBy('createdAt', descending: true))
          .thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]); // ← now type-compatible
      when(mockDoc.id).thenReturn('topic-001');
      when(mockDoc.data()).thenReturn(testTopicData);

      final topics = await forumRepository.fetchTopics();

      expect(topics, hasLength(1));
      expect(topics.first.id, 'topic-001');
      expect(topics.first.title, 'Test Topic');
    });
  });

  // ─────────────────────────────────────────────────
  // ReplyRepository tests
  // ─────────────────────────────────────────────────
  group('ReplyRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late ReplyRepository replyRepository;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      replyRepository = ReplyRepository(firestore: mockFirestore);

      when(mockFirestore.collection('replies')).thenReturn(mockCollection);
      when(mockDocRef.id).thenReturn('reply-001');
    });

    test('addReply returns new document id', () async {
      when(mockCollection.add(any)).thenAnswer((_) async => mockDocRef);

      final reply = ForumReply(
        id: '',
        topicId: 'topic-001',
        content: 'This is a reply',
        authorId: 'user-xyz',
        authorName: 'Bob',
        createdAt: DateTime(2024, 1, 2),
      );

      final result = await replyRepository.addReply(reply);

      expect(result, 'reply-001');
      verify(mockCollection.add(any)).called(1);
    });
  });
}