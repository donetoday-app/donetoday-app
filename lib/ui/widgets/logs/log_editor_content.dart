import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/logs/mood_picker.dart';
import 'package:done_today/ui/widgets/logs/tag_editor.dart';
import 'package:done_today/ui/widgets/logs/category_picker.dart';
import 'package:done_today/ui/widgets/logs/markdown_toolbar.dart';
import 'package:flutter/material.dart';

class LogEditorContent extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descController;
  final String mood;
  final String category;
  final List<String> tags;
  final Function(String?) onMoodChanged;
  final Function(String?) onCategoryChanged;
  final Function(List<String>) onTagsChanged;
  final VoidCallback onDescriptionChanged;
  final int wordCount;
  final List<String> existingMoods;
  final List<String> existingCategories;
  final bool showCategory;
  final ScrollController? controller;

  const LogEditorContent({
    super.key,
    required this.titleController,
    required this.descController,
    required this.mood,
    required this.category,
    required this.tags,
    required this.onMoodChanged,
    required this.onCategoryChanged,
    required this.onTagsChanged,
    required this.onDescriptionChanged,
    required this.wordCount,
    this.existingMoods = const [],
    this.existingCategories = const [],
    this.showCategory = true,
    this.controller,
  });

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: AppSpacing.sm),
        // Moods (Full Width Horizontal Scroll)
        _buildSectionHeader(context, "Title", Icons.title_sharp),
        // Huge Minimalist Title
        TextFormField(
          controller: titleController,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 30,
            letterSpacing: 1,
          ),
          decoration: InputDecoration(
            hintText: "Achievement Title...",
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            filled: true,
            contentPadding: EdgeInsets.zero,
          ),
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Categories (Full Width Horizontal Scroll)
        if (showCategory) ...[
          _buildSectionHeader(context, "Category", Icons.folder_rounded),
          CategoryPicker(
            selectedCategory: category,
            onChanged: onCategoryChanged,
            existingCategories: existingCategories,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Moods (Full Width Horizontal Scroll)
        _buildSectionHeader(context, "Mood", Icons.sentiment_satisfied_rounded),
        MoodPicker(
          selectedMood: mood,
          onChanged: onMoodChanged,
          existingMoods: existingMoods,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Tags
        _buildSectionHeader(context, "Tags", Icons.local_offer_rounded),
        TagEditor(tags: tags, onTagsChanged: onTagsChanged),

        const SizedBox(height: AppSpacing.sm),

        // Description Header & Word Count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(context, "Description", Icons.edit_document),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$wordCount words',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Description Editor Toolbar
        MarkdownToolbar(
          controller: descController,
          onAction: onDescriptionChanged,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Description Writing Space
        TextFormField(
          controller: descController,
          decoration: InputDecoration(
            hintText: "What did you accomplish today? (Markdown supported)",
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          minLines: 15, // Provide lots of writing space visually
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.6, fontSize: 17),
          onChanged: (_) => onDescriptionChanged(),
          validator: (value) =>
              value!.isEmpty ? 'Please enter a description' : null,
        ),

        const SizedBox(height: 80), // Padding for scrolling
      ],
    );
  }
}
