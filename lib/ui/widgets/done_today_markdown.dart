import 'package:flutter/material.dart';
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:done_today/ui/widgets/done_today_image_loader.dart';

/// ---------------------------------------------------------
/// CUSTOM DART MODELS FOR EXTENDED SYNTAXES & HTML
/// ---------------------------------------------------------

/// Custom Mood Chip Widget
class MoodChipWidget extends StatelessWidget {
  final String mood;

  const MoodChipWidget({Key? key, required this.mood}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodText = mood.trim();

    // Select emoji & tone color based on the mood text
    String emoji = '✨';
    Color moodColor = theme.colorScheme.primary;
    final lowerMood = moodText.toLowerCase();

    if (lowerMood.contains('happy') ||
        lowerMood.contains('joy') ||
        lowerMood.contains('good') ||
        lowerMood.contains('great')) {
      emoji = '😊';
      moodColor = Colors.amber.shade700;
    } else if (lowerMood.contains('sad') ||
        lowerMood.contains('down') ||
        lowerMood.contains('low') ||
        lowerMood.contains('gloomy')) {
      emoji = '😢';
      moodColor = Colors.blue.shade600;
    } else if (lowerMood.contains('angry') ||
        lowerMood.contains('mad') ||
        lowerMood.contains('frustrated') ||
        lowerMood.contains('annoyed')) {
      emoji = '😠';
      moodColor = Colors.red.shade600;
    } else if (lowerMood.contains('calm') ||
        lowerMood.contains('relaxed') ||
        lowerMood.contains('peaceful')) {
      emoji = '🧘';
      moodColor = Colors.teal.shade600;
    } else if (lowerMood.contains('tired') ||
        lowerMood.contains('exhausted') ||
        lowerMood.contains('sleepy')) {
      emoji = '😴';
      moodColor = Colors.purple.shade600;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: moodColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: moodColor.withOpacity(0.25), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14, height: 1.0)),
          const SizedBox(width: 5),
          Text(
            moodText.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: moodColor,
              letterSpacing: 0.5,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Time Stamp Chip Widget
class TimeChipWidget extends StatelessWidget {
  final String time;

  const TimeChipWidget({Key? key, required this.time}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = time.trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 13,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            timeText,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// GPT_MARKDOWN CUSTOM INLINE & BLOCK COMPONENTS
/// ---------------------------------------------------------

/// Parses ::mood[happy]
class MoodChipMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r'::mood\[([^\]]+)\]');

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final match = exp.firstMatch(text.trim());
    final moodText = match?.group(1) ?? '';
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: MoodChipWidget(mood: moodText),
    );
  }
}

/// Parses @time[09:30 AM]
class TimeChipMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r'@time\[([^\]]+)\]');

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final match = exp.firstMatch(text.trim());
    final timeText = match?.group(1) ?? '';
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: TimeChipWidget(time: timeText),
    );
  }
}

/// Parses <b>...</b> and <strong>...</strong>
class HtmlBoldMd extends InlineMd {
  @override
  RegExp get exp => RegExp(
    r'<b\b[^>]*>(.*?)</b>|<strong\b[^>]*>(.*?)</strong>',
    dotAll: true,
  );

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final match = exp.firstMatch(text.trim());
    final innerText = match?.group(1) ?? match?.group(2) ?? '';
    final conf = config.copyWith(
      style: (config.style ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
    return TextSpan(
      children: MarkdownComponent.generate(context, innerText, conf, false),
      style: conf.style,
    );
  }
}

/// Parses <i>...</i> and <em>...</em>
class HtmlItalicMd extends InlineMd {
  @override
  RegExp get exp =>
      RegExp(r'<i\b[^>]*>(.*?)</i>|<em\b[^>]*>(.*?)</em>', dotAll: true);

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final match = exp.firstMatch(text.trim());
    final innerText = match?.group(1) ?? match?.group(2) ?? '';
    final conf = config.copyWith(
      style: (config.style ?? const TextStyle()).copyWith(
        fontStyle: FontStyle.italic,
      ),
    );
    return TextSpan(
      children: MarkdownComponent.generate(context, innerText, conf, false),
      style: conf.style,
    );
  }
}

/// Parses <u>...</u>
class HtmlUnderlineMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r'<u\b[^>]*>(.*?)</u>', dotAll: true);

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final match = exp.firstMatch(text.trim());
    final innerText = match?.group(1) ?? '';
    final conf = config.copyWith(
      style: (config.style ?? const TextStyle()).copyWith(
        decoration: TextDecoration.underline,
      ),
    );
    return TextSpan(
      children: MarkdownComponent.generate(context, innerText, conf, false),
      style: conf.style,
    );
  }
}

/// Parses <br>
class HtmlBrMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r'<br\s*/?>');

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    return const TextSpan(text: '\n');
  }
}

/// Parses <img src="...">
class HtmlImageMd extends InlineMd {
  @override
  RegExp get exp => RegExp(r'<img\s+[^>]*src="([^"]+)"[^>]*>');

  @override
  InlineSpan span(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final match = exp.firstMatch(text.trim());
    final src = match?.group(1) ?? '';
    if (src.isEmpty) return const TextSpan();

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DoneTodayImageLoader(
            imageUrl: src,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// InheritedWidget to pass the checkbox-toggle callback through gpt_markdown's
/// component tree without prop-drilling.
class _CheckboxScope extends InheritedWidget {
  const _CheckboxScope({required this.onToggle, required super.child});
  final void Function(String lineText, bool newValue)? onToggle;

  static _CheckboxScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CheckboxScope>();

  @override
  bool updateShouldNotify(_CheckboxScope old) => onToggle != old.onToggle;
}

/// Interactive stateful checkbox widget used in view mode.
class _InteractiveCheckbox extends StatefulWidget {
  final bool initialChecked;
  final String childText;
  final String rawLine;
  final GptMarkdownConfig config;

  const _InteractiveCheckbox({
    required this.initialChecked,
    required this.childText,
    required this.rawLine,
    required this.config,
  });

  @override
  State<_InteractiveCheckbox> createState() => _InteractiveCheckboxState();
}

class _InteractiveCheckboxState extends State<_InteractiveCheckbox> {
  late bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.initialChecked;
  }

  void _toggle() {
    setState(() => _checked = !_checked);
    final scope = _CheckboxScope.of(context);
    scope?.onToggle?.call(widget.rawLine, _checked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Directionality(
        textDirection: widget.config.textDirection,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _checked
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  key: ValueKey(_checked),
                  size: 20,
                  color: _checked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: (widget.config.style ?? const TextStyle()).copyWith(
                    color: _checked
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                        : null,
                    decoration: _checked ? TextDecoration.lineThrough : null,
                  ),
                  child: MdWidget(
                    context,
                    widget.childText,
                    false,
                    config: widget.config,
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

/// Parses checkboxes. Renders as interactive in view mode.
class InteractiveCheckBoxMd extends BlockMd {
  @override
  String get expString => (r"\[((?:\x|\ ))\]\ (\S[^\n]*?)$");

  @override
  Widget build(
    BuildContext context,
    String text,
    final GptMarkdownConfig config,
  ) {
    final match = exp.firstMatch(text.trim());
    final checked = ("${match?[1]}" == "x");
    final childText = "${match?[2]}";

    return _InteractiveCheckbox(
      initialChecked: checked,
      childText: childText,
      rawLine: text.trim(),
      config: config,
    );
  }
}

/// ---------------------------------------------------------
/// DONE TODAY MARKED RENDERER CLASS
/// ---------------------------------------------------------

/// Highly customized, reusable Markdown renderer specifically built for Done Today.
/// Powered by `gpt_markdown` for robust AI-friendly formatting and LaTeX.
class DoneTodayMarkdown extends StatelessWidget {
  final String data;
  final Color textColor;
  final double fontSize;
  final double height;

  /// Called when the user taps a checkbox in view mode.
  /// Receives the full updated markdown string with the toggled checkbox.
  /// Hook this up to your log provider's update method to persist the change.
  final void Function(String updatedData)? onDataChanged;

  const DoneTodayMarkdown({
    Key? key,
    required this.data,
    required this.textColor,
    this.fontSize = 15.0,
    this.height = 2.0,
    this.onDataChanged,
  }) : super(key: key);

  /// Strips the leading list marker (`- `, `* `, `+ `, or `1. `) from a line
  /// so we can compare the raw content that gpt_markdown provides.
  static String _stripListPrefix(String line) {
    return line.replaceFirst(RegExp(r'^[-*+]\s+|^\d+\.\s+'), '');
  }

  /// Reconstructs the markdown string with the given checkbox line toggled.
  ///
  /// [rawLine] is what gpt_markdown passes to BlockMd.build() — the regex-
  /// matched text, e.g. `[ ] Do the dishes` WITHOUT the leading `- ` prefix.
  /// We strip the list prefix from each source line before comparing.
  String _buildToggled(String rawLine, bool newValue) {
    final lines = data.split('\n');
    bool alreadyToggled = false; // Only toggle the FIRST matching line
    final toggledLines = lines.map((line) {
      if (alreadyToggled) return line;
      final stripped = _stripListPrefix(line.trim());
      if (stripped == rawLine) {
        alreadyToggled = true;
        if (newValue) {
          return line.replaceFirst(RegExp(r'\[ \]'), '[x]');
        } else {
          return line.replaceFirst(RegExp(r'\[x\]'), '[ ]');
        }
      }
      return line;
    }).toList();
    return toggledLines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // CRITICAL: Preprocess markdown string to preserve editor single line-breaks exactly.
    // By ending every single newline with two spaces, we instruct standard Markdown syntax
    // to render the carriage returns as real newlines, avoiding collapsing text layouts!
    final preservedSpacingData = data.replaceAllMapped(
      RegExp(r'(?<!\s)\n(?!\n)'),
      (match) => '  \n',
    );

    return _CheckboxScope(
      onToggle: onDataChanged == null
          ? null
          : (rawLine, newValue) {
              onDataChanged!(_buildToggled(rawLine, newValue));
            },
      child: GptMarkdownTheme(
        gptThemeData: GptMarkdownThemeData(
          brightness: theme.brightness,
          h1: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: fontSize + 7,
            fontWeight: FontWeight.w900,
            height: 1.8,
            color: textColor,
          ),
          h2: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: fontSize + 3,
            fontWeight: FontWeight.w900,
            height: 1.8,
            color: textColor,
          ),
          h3: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: fontSize + 1,
            fontWeight: FontWeight.bold,
            height: 1.8,
            color: textColor,
          ),
          hrLineColor: theme.colorScheme.outlineVariant,
        ),
        child: GptMarkdown(
          preservedSpacingData,
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: fontSize,
            height: height,
            color: textColor.withOpacity(0.85),
          ),
          imageBuilder: (context, imageUrl, imgWidth, imgHeight) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: DoneTodayImageLoader(
                  imageUrl: imageUrl,
                  width: imgWidth,
                  height: imgHeight,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
          components: [
            InteractiveCheckBoxMd(),
            ...MarkdownComponent.globalComponents.where(
              (c) => c is! CheckBoxMd,
            ),
          ],
          inlineComponents: [
            MoodChipMd(),
            TimeChipMd(),
            HtmlBoldMd(),
            HtmlItalicMd(),
            HtmlUnderlineMd(),
            HtmlBrMd(),
            HtmlImageMd(),
            ...MarkdownComponent.inlineComponents,
          ],
        ),
      ),
    );
  }
}
