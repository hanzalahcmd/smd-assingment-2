import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_module/firebase_module.dart';

part 'forum_event.dart';
part 'forum_state.dart';

class ForumBloc extends Bloc<ForumEvent, ForumState> {
  ForumBloc({required IForumRepository forumRepository})
      : _forumRepository = forumRepository,
        super(const ForumState()) {
    on<ForumSubscriptionRequested>(_onSubscriptionRequested);
    on<ForumTopicCreateRequested>(_onTopicCreateRequested);
  }

  final IForumRepository _forumRepository;
  StreamSubscription<List<ForumTopic>>? _topicsSubscription;

  Future<void> _onSubscriptionRequested(
    ForumSubscriptionRequested event,
    Emitter<ForumState> emit,
  ) async {
    emit(state.copyWith(status: ForumStatus.loading));

    await _topicsSubscription?.cancel();

    await emit.forEach<List<ForumTopic>>(
      _forumRepository.watchTopics(),
      onData: (topics) =>
          state.copyWith(status: ForumStatus.success, topics: topics),
      onError: (_, __) => state.copyWith(
        status: ForumStatus.failure,
        errorMessage: 'Failed to load topics. Pull to refresh.',
      ),
    );
  }

  Future<void> _onTopicCreateRequested(
    ForumTopicCreateRequested event,
    Emitter<ForumState> emit,
  ) async {
    emit(state.copyWith(status: ForumStatus.creating));
    try {
      final topic = ForumTopic(
        id: '',
        title: event.title,
        content: event.content,
        authorId: event.authorId,
        authorName: event.authorName,
        createdAt: DateTime.now(),
      );
      await _forumRepository.createTopic(topic);
      // Stream will push the new topic; just restore success state
      emit(state.copyWith(status: ForumStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ForumStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  @override
  Future<void> close() {
    _topicsSubscription?.cancel();
    return super.close();
  }
}
