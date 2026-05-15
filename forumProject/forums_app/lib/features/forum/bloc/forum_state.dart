part of 'forum_bloc.dart';

enum ForumStatus { initial, loading, success, failure, creating }

class ForumState extends Equatable {
  const ForumState({
    this.status = ForumStatus.initial,
    this.topics = const [],
    this.errorMessage,
  });

  final ForumStatus status;
  final List<ForumTopic> topics;
  final String? errorMessage;

  bool get isLoading => status == ForumStatus.loading;
  bool get isCreating => status == ForumStatus.creating;

  ForumState copyWith({
    ForumStatus? status,
    List<ForumTopic>? topics,
    String? errorMessage,
  }) =>
      ForumState(
        status: status ?? this.status,
        topics: topics ?? this.topics,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, topics, errorMessage];
}
