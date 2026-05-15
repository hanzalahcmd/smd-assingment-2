import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forums_app/core/di/injection.dart';
import 'package:forums_app/features/auth/bloc/auth_bloc.dart';
import 'package:forums_app/features/forum/bloc/forum_bloc.dart';
import 'package:forums_app/features/forum/screens/create_topic_screen.dart';
import 'package:forums_app/features/forum/screens/topic_detail_screen.dart';
import 'package:forums_app/features/forum/widgets/topic_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForumBloc(forumRepository: sl())
        ..add(const ForumSubscriptionRequested()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final authState = context.watch<AuthBloc>().state;
    final user =
        authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UniForums'),
        actions: [
          // User avatar
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(user.email,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded),
                        SizedBox(width: 12),
                        Text('Sign out'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'logout') {
                    context
                        .read<AuthBloc>()
                        .add(const AuthLogoutRequested());
                  }
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    user.displayName[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: user == null
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<ForumBloc>(),
                      child: CreateTopicScreen(user: user),
                    ),
                  ),
                ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Topic'),
      ),
      body: BlocConsumer<ForumBloc, ForumState>(
        listener: (context, state) {
          if (state.status == ForumStatus.failure &&
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
        builder: (context, state) {
          if (state.status == ForumStatus.loading ||
              state.status == ForumStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.topics.isEmpty) {
            return _EmptyState(onNewTopic: user == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<ForumBloc>(),
                          child: CreateTopicScreen(user: user!),
                        ),
                      ),
                    ));
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<ForumBloc>()
                  .add(const ForumSubscriptionRequested());
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: state.topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final topic = state.topics[index];
                return AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: 200 + index * 30),
                  child: TopicCard(
                    topic: topic,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TopicDetailScreen(
                          topic: topic,
                          currentUser: user,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onNewTopic});
  final VoidCallback? onNewTopic;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 72, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No topics yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to start a discussion!',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          if (onNewTopic != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onNewTopic,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Topic'),
            ),
          ],
        ],
      ),
    );
  }
}
