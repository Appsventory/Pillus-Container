import 'package:flutter/widgets.dart';

enum ScreenSize { mobile, tablet, desktop }

class Responsive {
  static ScreenSize of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1100) return ScreenSize.desktop;
    if (w >= 700) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  static int gridColumns(BuildContext context) {
    switch (of(context)) {
      case ScreenSize.desktop:
        return 3;
      case ScreenSize.tablet:
        return 2;
      case ScreenSize.mobile:
        return 1;
    }
  }

  static EdgeInsets pagePadding(BuildContext context) {
    switch (of(context)) {
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 20);
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
  }
}
