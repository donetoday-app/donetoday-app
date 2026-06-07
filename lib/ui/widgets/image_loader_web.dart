import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

// Tracks which viewIds have been registered to avoid duplicate registration errors.
final Set<String> _registeredViewIds = {};

class DoneTodayImageLoader extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const DoneTodayImageLoader({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();

    // Unique ID per URL — avoids re-registration on the same image URL
    final String viewId = 'dt_img_${cleanUrl.hashCode}';

    // Only register if not already registered (platformViewRegistry throws on duplicates)
    if (!_registeredViewIds.contains(viewId)) {
      _registeredViewIds.add(viewId);
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
        final objectFitValue = switch (fit) {
          BoxFit.cover => 'cover',
          BoxFit.fill => 'fill',
          BoxFit.scaleDown => 'scale-down',
          BoxFit.none => 'none',
          _ => 'contain', // BoxFit.contain, fitWidth, fitHeight all map to contain
        };

        final div = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.display = 'flex'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center';

        final img = html.ImageElement()
          ..src = cleanUrl
          ..style.maxWidth = '100%'
          ..style.height = 'auto'  // Always auto-height = natural aspect ratio
          ..style.objectFit = objectFitValue
          ..style.border = 'none'
          ..style.display = 'block';

        div.append(img);
        return div;
      });
    }

    return SizedBox(
      // Width fills available space; height is intrinsic (auto from CSS height:auto)
      width: width ?? double.infinity,
      // Use a tall enough container to not clip; image height is driven by CSS height:auto
      height: height ?? 300,
      child: HtmlElementView(viewType: viewId),
    );
  }
}
