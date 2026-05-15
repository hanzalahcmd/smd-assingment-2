part of 'forum_bloc.dart';

abstract class ForumEvent extends Equatable {
  const ForumEvent();
  @override
  List<Object?> get props => [];
}

class ForumSubscriptionRequested extends ForumEvent {
  const ForumSubscriptionRequested();
}

class ForumTopicCreateRequested extends ForumEvent {
  const ForumTopicCreateRequested({
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
  });
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  @override
  List<Object?> get props => [title, content, authorId];
}
