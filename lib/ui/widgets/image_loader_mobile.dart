import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

class DoneTodayImageLoader extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  // fit is kept for API compatibility but defaults to contain (full natural size)
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
    final theme = Theme.of(context);
    final cleanUrl = imageUrl.trim();

    Widget imageWidget;

    try {
      if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
        imageWidget = Image.network(
          cleanUrl,
          // width full, height intrinsic — renders at natural resolution
          width: width ?? double.infinity,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorCard(theme, 'Failed to load image'),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingSkeleton(theme);
          },
        );
      } else if (cleanUrl.startsWith('data:image/')) {
        final commaIndex = cleanUrl.indexOf(',');
        if (commaIndex != -1) {
          final base64Data = cleanUrl.substring(commaIndex + 1);
          final decodedBytes = base64Decode(base64Data);
          imageWidget = Image.memory(
            decodedBytes,
            width: double.infinity,
            height: double.infinity,
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                _buildErrorCard(theme, 'Failed to parse base64 image'),
          );
        } else {
          imageWidget = _buildErrorCard(theme, 'Invalid base64 image data');
        }
      } else if (cleanUrl.startsWith('file://') || cleanUrl.startsWith('/')) {
        final filePath = cleanUrl.startsWith('file://')
            ? cleanUrl.replaceFirst('file://', '')
            : cleanUrl;
        imageWidget = Image.file(
          File(filePath),
          width: double.infinity,
          height: double.infinity,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorCard(theme, 'Failed to load local image'),
        );
      } else {
        imageWidget = Image.asset(
          cleanUrl,
          width: double.infinity,
          height: double.infinity,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Image.network(
              cleanUrl,
              width: double.infinity,
              height: double.infinity,
              fit: fit,
              errorBuilder: (_, e, __) =>
                  _buildErrorCard(theme, 'Failed to load image'),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingSkeleton(theme);
              },
            );
          },
        );
      }
    } catch (e) {
      imageWidget = _buildErrorCard(theme, 'Error: ${e.toString()}');
    }

    // Wrap in ConstrainedBox so image stretches to available width
    // but never exceeds it, and height is always intrinsic (natural)
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width ?? double.infinity),
      child: imageWidget,
    );
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    return Container(
      height: 180,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, String reason) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_rounded,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
