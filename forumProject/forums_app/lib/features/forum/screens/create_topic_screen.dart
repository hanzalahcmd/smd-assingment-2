import 'package:firebase_module/firebase_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forums_app/features/forum/bloc/forum_bloc.dart';

class CreateTopicScreen extends StatefulWidget {
  const CreateTopicScreen({super.key, required this.user});
  final UserModel user;

  @override
  State<CreateTopicScreen> createState() => _CreateTopicScreenState();
}

class _CreateTopicScreenState extends State<CreateTopicScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _submitted = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    context.read<ForumBloc>().add(
          ForumTopicCreateRequested(
            title: _titleCtrl.text.trim(),
            content: _contentCtrl.text.trim(),
            authorId: widget.user.uid,
            authorName: widget.user.displayName,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BlocListener<ForumBloc, ForumState>(
      listener: (context, state) {
        if (state.status == ForumStatus.success && _submitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Topic created!')),
          );
          Navigator.of(context).pop();
        }
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Topic'),
          actions: [
            BlocBuilder<ForumBloc, ForumState>(
              builder: (context, state) {
                final isCreating = state.isCreating;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: isCreating
                        ? const SizedBox(
                            key: ValueKey('loader'),
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : FilledButton(
                            key: const ValueKey('post'),
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(80, 38),
                            ),
                            child: const Text('Post'),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author chip
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          widget.user.displayName[0].toUpperCase(),
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
                          Text(
                            widget.user.displayName,
                            style: theme.textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Posting to General',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title field
                  TextFormField(
                    controller: _titleCtrl,
                    maxLength: 120,
                    textInputAction: TextInputAction.next,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      labelText: 'Topic title',
                      hintText: 'What do you want to discuss?',
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a title for your topic';
                      }
                      if (v.trim().length < 5) {
                        return 'Title should be at least 5 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Content field
                  TextFormField(
                    controller: _contentCtrl,
                    maxLines: 10,
                    maxLength: 5000,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      hintText: 'Share your thoughts, questions or ideas…',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please add some content to your topic';
                      }
                      if (v.trim().length < 10) {
                        return 'Content should be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be respectful and constructive.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
