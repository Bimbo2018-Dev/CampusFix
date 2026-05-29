import 'package:flutter/material.dart';

import '../utils/responsive_breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final type = ResponsiveBreakpoints.typeForWidth(constraints.maxWidth);
        switch (type) {
          case ScreenType.mobile:
            return mobile;
          case ScreenType.tablet:
            return tablet;
          case ScreenType.desktop:
            return desktop;
        }
      },
    );
  }
}
