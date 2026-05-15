import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_module/firebase_module.dart';

part 'reply_event.dart';
part 'reply_state.dart';

class ReplyBloc extends Bloc<ReplyEvent, ReplyState> {
  ReplyBloc({
    required IReplyRepository replyRepository,
    required IForumRepository forumRepository,
  })  : _replyRepository = replyRepository,
        _forumRepository = forumRepository,
        super(const ReplyState()) {
    on<ReplySubscriptionRequested>(_onSubscriptionRequested);
    on<ReplyAddRequested>(_onReplyAddRequested);
  }

  final IReplyRepository _replyRepository;
  final IForumRepository _forumRepository;

  Future<void> _onSubscriptionRequested(
    ReplySubscriptionRequested event,
    Emitter<ReplyState> emit,
  ) async {
    emit(state.copyWith(status: ReplyStatus.loading));
    await emit.forEach<List<ForumReply>>(
      _replyRepository.watchReplies(event.topicId),
      onData: (replies) =>
          state.copyWith(status: ReplyStatus.success, replies: replies),
      onError: (_, __) => state.copyWith(
        status: ReplyStatus.failure,
        errorMessage: 'Failed to load replies.',
      ),
    );
  }

  Future<void> _onReplyAddRequested(
    ReplyAddRequested event,
    Emitter<ReplyState> emit,
  ) async {
    emit(state.copyWith(status: ReplyStatus.posting));
    try {
      final reply = ForumReply(
        id: '',
        topicId: event.topicId,
        content: event.content,
        authorId: event.authorId,
        authorName: event.authorName,
        createdAt: DateTime.now(),
      );
      await _replyRepository.addReply(reply);
      // Also bump reply count on the parent topic
      await _forumRepository.incrementReplyCount(event.topicId);
      emit(state.copyWith(status: ReplyStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ReplyStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
