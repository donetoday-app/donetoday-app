import 'dart:async';
import 'package:done_today/state/logs/logs_state.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/providers/logs/logs_notifier.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:done_today/ui/widgets/logs/log_editor_content.dart';
import 'package:done_today/ui/widgets/logs/log_preview_content.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:done_today/ui/widgets/unified_header.dart';
import 'package:done_today/providers/settings/theme_notifier.dart';

class LogScreen extends ConsumerStatefulWidget {
  final Log? log;

  const LogScreen({super.key, this.log});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  List<String> _tags = [];
  String _mood = "normal 🙂";
  String _category = "Personal";
  bool _previewMode = false;
  bool _isLoading = false;
  Timer? _debounceTimer;

  bool get _isEdit => widget.log != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _titleController.text = widget.log!.title;
      _descController.text = widget.log!.description;
      _tags = widget.log!.tags ?? [];
      _mood = widget.log!.mood ?? "normal 🙂";
      _category = widget.log!.category ?? "Personal";
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onTextChangedDebounced() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _todayIso() => TimeUtil.todayIso();

  int _wordCount(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r"\s+")).length;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final logsProvider = ref.read(logsNotifierProvider.notifier);

    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    final date = _isEdit ? widget.log!.date : _todayIso();
    final use24Hour = ref.read(themeNotifierProvider).use24HourFormat;
    final time = _isEdit
        ? widget.log!.time
        : TimeUtil.getCurrentTimeFormatted(use24Hour: use24Hour);

    final logData = {
      "id": _isEdit ? widget.log!.id : const Uuid().v4(),
      "slug": "", // Add placeholder or generate slug
      "date": date,
      "time": time,
      "title": title,
      "description": description,
      "wordCount": _wordCount(description),
      "readTime": (_wordCount(description) / 200).ceil(),
      "tags": _tags,
      "mood": _mood,
      "category": _category,
    };

    try {
      if (_isEdit) {
        await logsProvider.editLog(widget.log!.id, logData);
      } else {
        await logsProvider.createLog(logData);
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

    final logsState = ref.watch(logsNotifierProvider);
    final List<String> existingMoods = [];
    final List<String> existingCategories = [];

    if (logsState is LogsLoaded) {
      existingMoods.addAll(
        logsState.logs
            .map((l) => l.mood)
            .whereType<String>()
            .where((m) => m.isNotEmpty)
            .toSet(),
      );
      existingCategories.addAll(
        logsState.logs
            .map((l) => l.category)
            .whereType<String>()
            .where((c) => c.isNotEmpty)
            .toSet(),
      );
    }

    final editor = LogEditorContent(
      titleController: _titleController,
      descController: _descController,
      mood: _mood,
      category: _category,
      tags: _tags,
      onMoodChanged: (v) => setState(() => _mood = v!),
      onCategoryChanged: (v) => setState(() => _category = v!),
      onTagsChanged: (tags) => setState(() => _tags = tags),
      onDescriptionChanged: _onTextChangedDebounced,
      wordCount: wordCount,
      existingMoods: existingMoods,
      existingCategories: existingCategories,
    );

    final preview = LogPreviewContent(
      title: _titleController.text,
      description: _descController.text,
      mood: _mood,
      category: _category,
      tags: _tags,
      wordCount: wordCount,
      date: _isEdit ? widget.log!.date : null,
      time: _isEdit ? widget.log!.time : null,
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
                title: _isEdit ? 'EDIT LOG' : 'NEW LOG',
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
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _handleSubmit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _isEdit ? 'Update' : 'Save',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 36),
                      elevation: 0,
                    ),
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
    );
  }
}
