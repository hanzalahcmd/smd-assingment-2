part of 'reply_bloc.dart';

enum ReplyStatus { initial, loading, success, failure, posting }

class ReplyState extends Equatable {
  const ReplyState({
    this.status = ReplyStatus.initial,
    this.replies = const [],
    this.errorMessage,
  });

  final ReplyStatus status;
  final List<ForumReply> replies;
  final String? errorMessage;

  bool get isLoading => status == ReplyStatus.loading;
  bool get isPosting => status == ReplyStatus.posting;

  ReplyState copyWith({
    ReplyStatus? status,
    List<ForumReply>? replies,
    String? errorMessage,
  }) =>
      ReplyState(
        status: status ?? this.status,
        replies: replies ?? this.replies,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, replies, errorMessage];
}
