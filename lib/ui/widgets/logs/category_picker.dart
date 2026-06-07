import 'package:done_today/ui/widgets/app_dialog.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CategoryPicker extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String?> onChanged;
  final List<String> existingCategories;

  const CategoryPicker({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    this.existingCategories = const [],
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  static const List<Map<String, String>> _defaultCategories = [
    {"label": "Personal", "icon": "👤"},
    {"label": "Work", "icon": "💼"},
    {"label": "Health", "icon": "🏥"},
    {"label": "Learning", "icon": "📚"},
    {"label": "Finance", "icon": "💰"},
    {"label": "Growth", "icon": "🌱"},
  ];

  // Local state to keep track of custom categories added in this session
  final List<Map<String, String>> _customCategories = [];

  // List that maintains the physical visual order of category items
  late List<Map<String, String>> _displayCategories;

  // Flag to suppress re-sorting chips when the user clicks them
  bool _userJustSelected = false;

  @override
  void initState() {
    super.initState();
    _initializeCategories();
  }

  @override
  void didUpdateWidget(CategoryPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      if (_userJustSelected) {
        _userJustSelected = false;
      } else {
        _initializeCategories();
      }
    }
  }

  void _initializeCategories() {
    _displayCategories = List.from(_defaultCategories);

    // Use a helper to add unique categories from strings
    void addUniqueCategories(Iterable<String> catStrings) {
      for (final cStr in catStrings) {
        if (cStr.isEmpty) continue;
        final parts = cStr.split(' ');
        if (parts.length >= 2) {
          final icon = parts.last;
          final label = parts.sublist(0, parts.length - 1).join(' ');

          // Only add if not already in _displayCategories
          final exists = _displayCategories.any(
            (c) => c['label'] == label && c['icon'] == icon,
          );
          if (!exists) {
            _displayCategories.add({"label": label, "icon": icon});
          }
        }
      }
    }

    // Add session custom categories
    addUniqueCategories(
      _customCategories.map((c) => "${c['label']} ${c['icon']}"),
    );

    // Add existing categories from history
    addUniqueCategories(widget.existingCategories);

    // Ensure currently selected category is in the list
    if (widget.selectedCategory.isNotEmpty) {
      addUniqueCategories([widget.selectedCategory]);

      // Move the selected category to the beginning of _displayCategories
      final selectedIndex = _displayCategories.indexWhere((c) {
        final label = c["label"]!;
        final icon = c["icon"]!;
        return widget.selectedCategory == "$label $icon";
      });

      if (selectedIndex != -1) {
        final selectedCat = _displayCategories.removeAt(selectedIndex);
        _displayCategories.insert(0, selectedCat);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          _AddCustomCategory(
            onAdded: (newCat) {
              if (newCat != null) {
                final parts = newCat.split(' ');
                final icon = parts.last;
                final label = parts.sublist(0, parts.length - 1).join(' ');

                setState(() {
                  final exists = _customCategories.any(
                    (c) => c['label'] == label && c['icon'] == icon,
                  );
                  if (!exists) {
                    _customCategories.add({"label": label, "icon": icon});
                  }
                  _userJustSelected = true;
                  _initializeCategories();
                });
                widget.onChanged(newCat);
              }
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemCount: _displayCategories.length,
                itemBuilder: (context, index) {
                  final catData = _displayCategories[index];
                  final label = catData["label"]!;
                  final icon = catData["icon"]!;
                  final fullCat = "$label $icon";
                  final isSelected = widget.selectedCategory == fullCat;

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _userJustSelected = true;
                          });
                          widget.onChanged(fullCat);
                        }
                      },
                      showCheckmark: false,
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      side: BorderSide.none,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCustomCategory extends StatefulWidget {
  final ValueChanged<String?> onAdded;

  const _AddCustomCategory({required this.onAdded});

  @override
  State<_AddCustomCategory> createState() => _AddCustomCategoryState();
}

class _AddCustomCategoryState extends State<_AddCustomCategory> {
  void _showAddDialog(BuildContext context) {
    final labelController = TextEditingController();
    String selectedIcon = "🏷️";
    final theme = Theme.of(context);

    AppDialog.show(
      context: context,
      title: "New Category",
      confirmLabel: "Add",
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Picker Slot
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SizedBox(
                        height: 350,
                        child: EmojiPicker(
                          onEmojiSelected: (category, emoji) {
                            setDialogState(() {
                              selectedIcon = emoji.emoji;
                            });
                            Navigator.pop(context);
                          },
                          config: Config(
                            height: 256,
                            checkPlatformCompatibility: true,
                            viewOrderConfig: const ViewOrderConfig(),
                            emojiViewConfig: EmojiViewConfig(
                              columns: 7,
                              emojiSizeMax:
                                  32 *
                                  (defaultTargetPlatform == TargetPlatform.iOS
                                      ? 1.30
                                      : 1.0),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        selectedIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Label Input
                Expanded(
                  child: TextField(
                    controller: labelController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: "Category Name",
                      hintText: "e.g. Projects",
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            0.5,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            0.5,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Tap the icon to change it",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      onConfirm: () {
        final label = labelController.text.trim();
        if (label.isNotEmpty && selectedIcon.isNotEmpty) {
          widget.onAdded("$label $selectedIcon");
          Navigator.of(context, rootNavigator: true).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Both label and icon are required")),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(
        Icons.add_rounded,
        size: 18,
        color: theme.colorScheme.onSurface,
      ),
      onPressed: () => _showAddDialog(context),
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
          0.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
