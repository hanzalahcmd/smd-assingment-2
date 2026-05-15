part of 'reply_bloc.dart';

abstract class ReplyEvent extends Equatable {
  const ReplyEvent();
  @override
  List<Object?> get props => [];
}

class ReplySubscriptionRequested extends ReplyEvent {
  const ReplySubscriptionRequested({required this.topicId});
  final String topicId;
  @override
  List<Object?> get props => [topicId];
}

class ReplyAddRequested extends ReplyEvent {
  const ReplyAddRequested({
    required this.topicId,
    required this.content,
    required this.authorId,
    required this.authorName,
  });
  final String topicId;
  final String content;
  final String authorId;
  final String authorName;
  @override
  List<Object?> get props => [topicId, content, authorId];
}
