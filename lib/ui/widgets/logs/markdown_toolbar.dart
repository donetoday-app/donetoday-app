import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:done_today/ui/widgets/custom_popup.dart';

class MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAction;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    required this.onAction,
  });

  void _insertAtCursor(String prefix, [String suffix = ""]) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.start;
    final end = selection.end;

    if (start == -1) return;

    final selectedText = text.substring(start, end);
    final replacement = "$prefix$selectedText$suffix";

    controller.text = text.replaceRange(start, end, replacement);
    controller.selection = TextSelection.collapsed(
      offset: start + prefix.length + selectedText.length + suffix.length,
    );
    onAction();
  }

  void _showHelpDialog(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Markdown Guide",
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return CustomPopup(
          maxWidth: 480,
          showCloseButton: true,
          footer: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "DONE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: isMobile
                  ? screenSize.height - 240
                  : screenSize.height * 0.6,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Icon(
                        Icons.book_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Done Today Markdown",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 4),

                  // Introduction
                  Text(
                    "Write your daily entries using standard Markdown syntax. We automatically upgrade items into gorgeous layouts and support custom styled chips!",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Custom Extensions Subtitle
                  const _SectionHeader(title: "CUSTOM STYLED CHIPS"),
                  const SizedBox(height: 10),

                  // Mood tag help card
                  _GuideCard(
                    title: "Mood Pills",
                    syntax: "::mood[calm]",
                    description:
                        "Automatically renders a colored pill with a matching emoji based on mood word (happy, sad, calm, angry, tired).",
                    exampleWidget: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade600.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.teal.shade600.withOpacity(0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("🧘", style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text(
                            "CALM",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.teal.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time tag help card
                  _GuideCard(
                    title: "Time Stamps",
                    syntax: "@time[09:30 AM]",
                    description:
                        "Renders an elegant, primary-themed time chip with a clock icon. Use it to record precise timestamps in your text.",
                    exampleWidget: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "09:30 AM",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Standard Syntax Subtitle
                  const _SectionHeader(title: "STANDARD FORMATTING"),
                  const SizedBox(height: 10),

                  // Quick Syntax Reference Row
                  const _SyntaxRow(syntax: "**Text**", label: "Bold Text"),
                  const _SyntaxRow(syntax: "*Text*", label: "Italic Text"),
                  const _SyntaxRow(syntax: "### Title", label: "Heading"),
                  const _SyntaxRow(
                    syntax: "* Item",
                    label: "Bullet Point List",
                  ),
                  const _SyntaxRow(
                    syntax: "- [ ] Task",
                    label: "Interactive Checkbox List",
                  ),
                  const _SyntaxRow(syntax: "> Quote", label: "Blockquote Text"),

                  const SizedBox(height: 20),

                  // HTML Syntax Subtitle
                  const _SectionHeader(title: "HTML TAGS SUPPORT"),
                  const SizedBox(height: 10),

                  const _SyntaxRow(syntax: "<b>Bold</b>", label: "Bold Text"),
                  const _SyntaxRow(
                    syntax: "<u>Underline</u>",
                    label: "Underline Text",
                  ),
                  const _SyntaxRow(
                    syntax: "<i>Italic</i>",
                    label: "Italic Text",
                  ),
                  const _SyntaxRow(
                    syntax: "<img src=\"url\">",
                    label: "Embedded HTML Image",
                  ),
                  const _SyntaxRow(syntax: "<br>", label: "Manual Line Break"),

                  const SizedBox(height: 20),

                  // Question: Can I insert my own custom moods?
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "💡 Can I write my own moods?",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Yes! Write any word inside ::mood[your_word] and Done Today will parse it as a custom pill. Unrecognized moods render with a beautiful gold star (✨) and signature branding! Try writing ::mood[energized]!",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.65,
                            ),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
                ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Formatting actions (Scrollable left portion)
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
                children: [
                  _ToolbarButton(
                    icon: Icons.format_bold_rounded,
                    tooltip: "Bold",
                    onTap: () => _insertAtCursor("**", "**"),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_italic_rounded,
                    tooltip: "Italic",
                    onTap: () => _insertAtCursor("*", "*"),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_size_rounded,
                    tooltip: "Heading",
                    onTap: () => _insertAtCursor("### "),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_list_bulleted_rounded,
                    tooltip: "List",
                    onTap: () => _insertAtCursor("\n* "),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_quote_rounded,
                    tooltip: "Quote",
                    onTap: () => _insertAtCursor("\n> "),
                  ),
                  _ToolbarButton(
                    icon: Icons.link_rounded,
                    tooltip: "Link",
                    onTap: () => _insertAtCursor("[", "](url)"),
                  ),
                  _ToolbarButton(
                    icon: Icons.code_rounded,
                    tooltip: "Code",
                    onTap: () => _insertAtCursor("`", "`"),
                  ),
                  _ToolbarButton(
                    icon: Icons.horizontal_rule_rounded,
                    tooltip: "Divider",
                    onTap: () => _insertAtCursor("\n---\n"),
                  ),
                ],
              ),
            ),
          ),

          // Small elegant vertical divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            indent: 10,
            endIndent: 10,
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),

          // Custom Done Today Shortcuts & Help Action (Fixed right portion)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolbarButton(
                icon: Icons.access_time_rounded,
                tooltip: "Insert Current Time Stamp",
                onTap: () {
                  final now = DateTime.now();
                  final ampm = now.hour >= 12 ? "PM" : "AM";
                  int hr = now.hour % 12;
                  if (hr == 0) hr = 12;
                  final timeStr =
                      "${hr.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $ampm";
                  _insertAtCursor("@time[$timeStr]");
                },
              ),
              _ToolbarButton(
                icon: Icons.sentiment_satisfied_alt_rounded,
                tooltip: "Insert Mood Tag",
                onTap: () => _insertAtCursor("::mood[", "]"),
              ),
              _ToolbarButton(
                icon: Icons.help_outline_rounded,
                tooltip: "Markdown Guide",
                onTap: () => _showHelpDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            hoverColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
              0.5,
            ),
            splashColor: theme.colorScheme.primary.withOpacity(0.1),
            highlightColor: theme.colorScheme.primary.withOpacity(0.05),
            child: Container(
              width: 40,
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: theme.colorScheme.onSurface.withOpacity(0.4),
        letterSpacing: 1.5,
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final String title;
  final String syntax;
  final String description;
  final Widget exampleWidget;

  const _GuideCard({
    required this.title,
    required this.syntax,
    required this.description,
    required this.exampleWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              exampleWidget,
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Text(
              syntax,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyntaxRow extends StatelessWidget {
  final String syntax;
  final String label;

  const _SyntaxRow({required this.syntax, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              syntax,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
