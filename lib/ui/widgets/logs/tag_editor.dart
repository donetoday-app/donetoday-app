import 'dart:ui';

import 'package:done_today/ui/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

class TagEditor extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagEditor({super.key, required this.tags, required this.onTagsChanged});

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  void _removeTag(String tag) {
    widget.onTagsChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          // Add Tag Button
          GestureDetector(
            onTap: () => _showAddTagDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Tag",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Scrollable Tags
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: widget.tags
                    .map(
                      (tag) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          label: Text("#$tag"),
                          onDeleted: () => _removeTag(tag),
                          labelStyle: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: theme
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide.none,
                          deleteIcon: const Icon(Icons.close_rounded, size: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(BuildContext outerContext) {
    final controller = TextEditingController();
    AppDialog.show(
      context: outerContext,
      title: "New Tag",
      confirmLabel: "Add",
      content: Builder(
        builder: (dialogContext) => TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter tag name",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onSubmitted: (val) {
            final tag = val.trim();
            if (tag.isNotEmpty) {
              widget.onTagsChanged([...widget.tags, tag]);
              Navigator.of(outerContext, rootNavigator: true).pop();
            }
          },
        ),
      ),
      onConfirm: () {
        final val = controller.text.trim();
        if (val.isNotEmpty) {
          widget.onTagsChanged([...widget.tags, val]);
          Navigator.of(outerContext, rootNavigator: true).pop();
        }
      },
    );
  }
}
