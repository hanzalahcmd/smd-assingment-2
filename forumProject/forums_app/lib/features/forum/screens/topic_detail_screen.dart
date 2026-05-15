import 'package:firebase_module/firebase_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forums_app/core/di/injection.dart';
import 'package:forums_app/features/forum/widgets/reply_card.dart';
import 'package:forums_app/features/reply/bloc/reply_bloc.dart';
import 'package:intl/intl.dart';

class TopicDetailScreen extends StatelessWidget {
  const TopicDetailScreen({
    super.key,
    required this.topic,
    this.currentUser,
  });

  final ForumTopic topic;
  final UserModel? currentUser;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReplyBloc(
        replyRepository: sl(),
        forumRepository: sl(),
      )..add(ReplySubscriptionRequested(topicId: topic.id)),
      child: _TopicDetailView(topic: topic, currentUser: currentUser),
    );
  }
}

class _TopicDetailView extends StatefulWidget {
  const _TopicDetailView({required this.topic, this.currentUser});
  final ForumTopic topic;
  final UserModel? currentUser;

  @override
  State<_TopicDetailView> createState() => _TopicDetailViewState();
}

class _TopicDetailViewState extends State<_TopicDetailView> {
  final _replyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _replyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _postReply() {
    if (widget.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to reply')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    context.read<ReplyBloc>().add(
          ReplyAddRequested(
            topicId: widget.topic.id,
            content: _replyCtrl.text.trim(),
            authorId: widget.currentUser!.uid,
            authorName: widget.currentUser!.displayName,
          ),
        );
    _replyCtrl.clear();
    FocusScope.of(context).unfocus();
    // Scroll to bottom after posting
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BlocListener<ReplyBloc, ReplyState>(
      listener: (context, state) {
        if (state.status == ReplyStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: cs.error,
              ),
            );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Discussion'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: cs.outlineVariant),
          ),
        ),
        body: Column(
          children: [
            // ── Topic header ──────────────────────────
            Expanded(
              child: CustomScrollView(
                controller: _scrollCtrl,
                slivers: [
                  SliverToBoxAdapter(
                    child: _TopicHeader(topic: widget.topic),
                  ),

                  // ── Replies list ─────────────────────
                  BlocBuilder<ReplyBloc, ReplyState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (state.replies.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 40, horizontal: 24),
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded,
                                    size: 48, color: cs.outlineVariant),
                                const SizedBox(height: 12),
                                Text(
                                  'No replies yet',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Be the first to join the discussion!',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final reply = state.replies[i];
                              return ReplyCard(
                                reply: reply,
                                index: i,
                                isCurrentUser:
                                    reply.authorId == widget.currentUser?.uid,
                              );
                            },
                            childCount: state.replies.length,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Reply input bar ────────────────────────
            _ReplyInput(
              controller: _replyCtrl,
              formKey: _formKey,
              onPost: _postReply,
              isGuest: widget.currentUser == null,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────

class _TopicHeader extends StatelessWidget {
  const _TopicHeader({required this.topic});
  final ForumTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      color: cs.surfaceContainerLowest,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            topic.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Author row
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  topic.authorName.isNotEmpty
                      ? topic.authorName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.authorName,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    DateFormat('MMM d, y • h:mm a').format(topic.createdAt),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const Spacer(),
              // Reply count badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_rounded,
                        size: 14, color: cs.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      '${topic.replyCount} ${topic.replyCount == 1 ? 'reply' : 'replies'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          Text(topic.content, style: theme.textTheme.bodyLarge),

          const SizedBox(height: 8),
          Divider(color: cs.outlineVariant),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Replies',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────

class _ReplyInput extends StatelessWidget {
  const _ReplyInput({
    required this.controller,
    required this.formKey,
    required this.onPost,
    required this.isGuest,
  });

  final TextEditingController controller;
  final GlobalKey<FormState> formKey;
  final VoidCallback onPost;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: BlocBuilder<ReplyBloc, ReplyState>(
          builder: (context, state) {
            return Form(
              key: formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      enabled: !isGuest && !state.isPosting,
                      decoration: InputDecoration(
                        hintText: isGuest
                            ? 'Sign in to reply…'
                            : 'Write a reply…',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        isDense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Reply cannot be empty';
                        }
                        if (v.trim().length < 2) {
                          return 'Reply is too short';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: state.isPosting
                        ? Padding(
                            key: const ValueKey('loader'),
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: cs.primary),
                            ),
                          )
                        : IconButton.filled(
                            key: const ValueKey('send'),
                            onPressed: isGuest ? null : onPost,
                            icon: const Icon(Icons.send_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              padding: const EdgeInsets.all(14),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
