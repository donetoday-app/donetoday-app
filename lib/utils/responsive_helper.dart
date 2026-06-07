import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double mobileLimit = 800;
  static const double tabletLimit = 900;

  // Standard Max Widths for constraints
  static const double maxContentWidth =
      800; // For reading/editing logs, settings
  static const double maxFullWidth = 1200; // For dashboards, grids
  static const double maxAuthWidth = 600; // For auth forms

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileLimit;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileLimit &&
      MediaQuery.sizeOf(context).width < tabletLimit;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletLimit;

  static T adaptive<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}

class ResponsiveConstraints extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  const ResponsiveConstraints({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveHelper.maxContentWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveHelper.tabletLimit) {
          return desktop;
        } else if (constraints.maxWidth >= ResponsiveHelper.mobileLimit) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
