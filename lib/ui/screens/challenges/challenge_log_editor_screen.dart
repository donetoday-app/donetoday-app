import 'package:done_today/providers/challenges/challenges_notifier.dart';
import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/logs/log_editor_content.dart';
import 'package:done_today/ui/widgets/logs/log_preview_content.dart';
import 'package:done_today/ui/widgets/unified_header.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChallengeLogEditorScreen extends ConsumerStatefulWidget {
  final Challenge challenge;
  final Log? existingLog;

  const ChallengeLogEditorScreen({
    super.key,
    required this.challenge,
    this.existingLog,
  });

  @override
  ConsumerState<ChallengeLogEditorScreen> createState() =>
      _ChallengeLogEditorScreenState();
}

class _ChallengeLogEditorScreenState
    extends ConsumerState<ChallengeLogEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  List<String> _tags = [];
  String _mood = "🔥";
  String _category = "Challenge";
  bool _previewMode = false;
  bool _isLoading = false;
  late final ScrollController _scrollController;
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    if (_isEdit) {
      _titleController.text = widget.existingLog!.title;
      _descController.text = widget.existingLog!.description;
      _tags = widget.existingLog!.tags ?? [];
      _mood = widget.existingLog!.mood ?? "🔥";
      _category = widget.existingLog!.category ?? "Challenge";
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
      }
    }
  }

  bool get _isEdit => widget.existingLog != null;

  int _wordCount(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r"\s+")).length;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final challengesProvider = ref.read(challengesNotifierProvider.notifier);

    try {
      if (_isEdit) {
        await challengesProvider.updateLog(
          logId: widget.existingLog!.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          mood: _mood,
          tags: _tags,
        );
      } else {
        await challengesProvider.logChallengeDay(
          challenge: widget.challenge,
          date: DateTime.now(),
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          mood: _mood,
          tags: _tags,
        );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final wordCount = _wordCount(_descController.text);

    final List<String> existingMoods = ['🔥', '💪', '🧘', '😊', '😴'];

    final editor = LogEditorContent(
      titleController: _titleController,
      descController: _descController,
      mood: _mood,
      category: _category,
      tags: _tags,
      onMoodChanged: (v) => setState(() => _mood = v!),
      onCategoryChanged: (v) => setState(() => _category = v!),
      onTagsChanged: (tags) => setState(() => _tags = tags),
      onDescriptionChanged: () => setState(() {}),
      wordCount: wordCount,
      existingMoods: existingMoods,
      showCategory: false,
    );

    final preview = LogPreviewContent(
      title: _titleController.text,
      description: _descController.text,
      mood: _mood,
      category: _category,
      tags: _tags,
      wordCount: wordCount,
      date: _isEdit ? widget.existingLog!.date : null,
      time: _isEdit ? widget.existingLog!.time : null,
    );

    return Scaffold(
      body: SafeArea(
        child: ResponsiveConstraints(
          maxWidth: isDesktop
              ? ResponsiveHelper.maxFullWidth
              : ResponsiveHelper.maxContentWidth,
          child: Column(
            children: [
              UnifiedHeader(
                title: _isEdit ? 'EDIT CHALLENGE LOG' : 'CHALLENGE CHECK-IN',
                onBack: () => context.pop(),
                actions: [
                  if (!isDesktop)
                    IconButton(
                      icon: Icon(
                        _previewMode
                            ? Icons.edit_rounded
                            : Icons.visibility_rounded,
                        size: 22,
                      ),
                      onPressed: () =>
                          setState(() => _previewMode = !_previewMode),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
              Expanded(
                child: isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            child: Form(key: _formKey, child: editor),
                          ),
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.5,
                            ),
                          ),
                          Expanded(child: preview),
                        ],
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Form(
                          key: _formKey,
                          child: _previewMode ? preview : editor,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _handleSubmit,
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  key: const ValueKey('content'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.save_rounded),
                    const SizedBox(width: 8),
                    Text(_isEdit ? 'Update Log' : 'Save Progress'),
                  ],
                ),
        ),
      ),
    );
  }
}
