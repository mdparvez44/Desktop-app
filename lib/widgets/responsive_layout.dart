/// Responsive layout builder widget for desktop window resizing.
library;

import 'package:flutter/material.dart';

enum DesktopScreenSize { small, medium, large }

class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, DesktopScreenSize size) builder;

  const ResponsiveLayout({
    super.key,
    required this.builder,
  });

  static DesktopScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) {
      return DesktopScreenSize.large;
    } else if (width >= 800) {
      return DesktopScreenSize.medium;
    } else {
      return DesktopScreenSize.small;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        DesktopScreenSize size;
        if (width >= 1200) {
          size = DesktopScreenSize.large;
        } else if (width >= 800) {
          size = DesktopScreenSize.medium;
        } else {
          size = DesktopScreenSize.small;
        }
        return builder(context, size);
      },
    );
  }
}
