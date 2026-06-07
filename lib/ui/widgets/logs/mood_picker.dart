import 'package:done_today/ui/widgets/app_dialog.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MoodPicker extends StatefulWidget {
  final String selectedMood;
  final ValueChanged<String?> onChanged;
  final List<String> existingMoods;

  const MoodPicker({
    super.key,
    required this.selectedMood,
    required this.onChanged,
    this.existingMoods = const [],
  });

  @override
  State<MoodPicker> createState() => _MoodPickerState();
}

class _MoodPickerState extends State<MoodPicker> {
  static const List<Map<String, String>> _defaultMoods = [
    {"label": "happy", "emoji": "😊"},
    {"label": "sad", "emoji": "😞"},
    {"label": "excited", "emoji": "😆"},
    {"label": "angry", "emoji": "😡"},
    {"label": "normal", "emoji": "🙂"},
  ];

  // Local state to keep track of custom moods added in this session
  final List<Map<String, String>> _customMoods = [];

  // List that maintains the physical visual order of mood items
  late List<Map<String, String>> _displayMoods;

  // Flag to suppress re-sorting chips when the user clicks them
  bool _userJustSelected = false;

  @override
  void initState() {
    super.initState();
    _initializeMoods();
  }

  @override
  void didUpdateWidget(MoodPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMood != widget.selectedMood) {
      if (_userJustSelected) {
        _userJustSelected = false;
      } else {
        _initializeMoods();
      }
    }
  }

  void _initializeMoods() {
    _displayMoods = List.from(_defaultMoods);

    // Use a helper to add unique moods from strings
    void addUniqueMoods(Iterable<String> moodStrings) {
      for (final mStr in moodStrings) {
        if (mStr.isEmpty) continue;
        final parts = mStr.split(' ');
        if (parts.length >= 2) {
          final emoji = parts.last;
          final label = parts.sublist(0, parts.length - 1).join(' ');

          // Only add if not already in _displayMoods
          final exists = _displayMoods.any(
            (m) => m['label'] == label && m['emoji'] == emoji,
          );
          if (!exists) {
            _displayMoods.add({"label": label, "emoji": emoji});
          }
        }
      }
    }

    // Add session custom moods
    addUniqueMoods(_customMoods.map((m) => "${m['label']} ${m['emoji']}"));

    // Add existing moods from history
    addUniqueMoods(widget.existingMoods);

    // Ensure currently selected mood is in the list
    if (widget.selectedMood.isNotEmpty) {
      addUniqueMoods([widget.selectedMood]);

      // Move the selected mood to the beginning of _displayMoods
      final selectedIndex = _displayMoods.indexWhere((m) {
        final label = m["label"]!;
        final emoji = m["emoji"]!;
        return widget.selectedMood == "$label $emoji";
      });

      if (selectedIndex != -1) {
        final selectedMoodMap = _displayMoods.removeAt(selectedIndex);
        _displayMoods.insert(0, selectedMoodMap);
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
          _AddCustomMood(
            onAdded: (newMood) {
              if (newMood != null) {
                final parts = newMood.split(' ');
                final emoji = parts.last;
                final label = parts.sublist(0, parts.length - 1).join(' ');

                setState(() {
                  final exists = _customMoods.any(
                    (m) => m['label'] == label && m['emoji'] == emoji,
                  );
                  if (!exists) {
                    _customMoods.add({"label": label, "emoji": emoji});
                  }
                  _userJustSelected = true;
                  _initializeMoods();
                });
                widget.onChanged(newMood);
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
                itemCount: _displayMoods.length,
                itemBuilder: (context, index) {
                  final moodData = _displayMoods[index];
                  final label = moodData["label"]!;
                  final emoji = moodData["emoji"]!;
                  final fullMood = "$label $emoji";
                  final isSelected = widget.selectedMood == fullMood;

                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            label.toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              letterSpacing: 0.5,
                              fontSize: 11,
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
                          widget.onChanged(fullMood);
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
                        horizontal: 8,
                        vertical: 8,
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

class _AddCustomMood extends StatefulWidget {
  final ValueChanged<String?> onAdded;

  const _AddCustomMood({required this.onAdded});

  @override
  State<_AddCustomMood> createState() => _AddCustomMoodState();
}

class _AddCustomMoodState extends State<_AddCustomMood> {
  void _showAddDialog(BuildContext context) {
    final labelController = TextEditingController();
    String selectedEmoji = "😊";
    final theme = Theme.of(context);

    AppDialog.show(
      context: context,
      title: "New Mood",
      confirmLabel: "Add",
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Emoji Picker Slot
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SizedBox(
                        height: 350,
                        child: EmojiPicker(
                          onEmojiSelected: (category, emoji) {
                            setDialogState(() {
                              selectedEmoji = emoji.emoji;
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
                        selectedEmoji,
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
                      labelText: "Mood Label",
                      hintText: "e.g. Focused",
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
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
              "Tap the emoji to change it",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      onConfirm: () {
        final label = labelController.text.trim();
        if (label.isNotEmpty && selectedEmoji.isNotEmpty) {
          widget.onAdded("$label $selectedEmoji");
          Navigator.of(context, rootNavigator: true).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Both label and emoji are required")),
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
        Icons.add_reaction_rounded,
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
