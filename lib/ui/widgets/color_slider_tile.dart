import 'package:flutter/material.dart';

class ColorSliderTile extends StatefulWidget {
  final String title;
  final Color color;
  final ValueChanged<Color> onChanged;

  const ColorSliderTile({
    super.key,
    required this.title,
    required this.color,
    required this.onChanged,
  });

  @override
  State<ColorSliderTile> createState() => _ColorSliderTileState();
}

class _ColorSliderTileState extends State<ColorSliderTile> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _colorToHex(widget.color));
  }

  @override
  void didUpdateWidget(covariant ColorSliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.color != oldWidget.color) {
      final hex = _colorToHex(widget.color);

      if (_controller.text.toUpperCase() != hex) {
        _controller.text = hex;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) {
    return '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  /// Generates bright colors from hue
  Color _brightColorFromHue(double hue) {
    return HSVColor.fromAHSV(
      1.0,
      hue,
      0.85, // bright saturation
      1.0, // full brightness
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hsv = HSVColor.fromColor(widget.color);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Personalized Tone",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Customize theme accent dynamically",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // HEX INPUT
              SizedBox(
                width: 85,
                height: 34,
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withOpacity(0.04),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.color.withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                  ),
                  onSubmitted: (val) {
                    try {
                      final hex = val.replaceFirst('#', '');
                      if (hex.length != 6) {
                        throw Exception();
                      }
                      final color = Color(int.parse('FF$hex', radix: 16));
                      widget.onChanged(color);
                    } catch (_) {
                      _controller.text = _colorToHex(widget.color);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // COLOR PREVIEW
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.12),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // SPECTRUM SLIDER
          SpectrumSlider(
            hue: hsv.hue,
            currentColor: widget.color,
            onChanged: (value) {
              widget.onChanged(_brightColorFromHue(value));
            },
          ),
        ],
      ),
    );
  }
}

class SpectrumSlider extends StatelessWidget {
  final double hue;
  final Color currentColor;
  final ValueChanged<double> onChanged;

  const SpectrumSlider({
    super.key,
    required this.hue,
    required this.currentColor,
    required this.onChanged,
  });

  Color _bright(double hue) {
    return HSVColor.fromAHSV(1.0, hue, 0.85, 1.0).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // GRADIENT TRACK
        Container(
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                _bright(0),
                _bright(45),
                _bright(90),
                _bright(160),
                _bright(220),
                _bright(280),
                _bright(360),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: currentColor.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),

        // SLIDER
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 0,

            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,

            thumbColor: Colors.white,

            overlayColor: currentColor.withOpacity(0.08),

            overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),

            thumbShape: _ColorThumbShape(color: currentColor),
          ),
          child: Slider(value: hue, min: 0, max: 360, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _ColorThumbShape extends SliderComponentShape {
  final Color color;

  const _ColorThumbShape({required this.color});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(30, 30);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // OUTER GLOW
    canvas.drawCircle(
      center,
      15,
      Paint()
        ..color = color.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // WHITE RING
    canvas.drawCircle(
      center,
      12,
      Paint()..color = Colors.white.withOpacity(0.95),
    );

    // INNER COLOR
    canvas.drawCircle(center, 9, Paint()..color = color);

    // HIGHLIGHT
    canvas.drawCircle(
      center.translate(-2, -2),
      2,
      Paint()..color = Colors.white.withOpacity(0.45),
    );
  }
}
