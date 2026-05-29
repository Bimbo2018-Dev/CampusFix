enum ScreenType { mobile, tablet, desktop }

class ResponsiveBreakpoints {
  static const double mobileMax = 600;
  static const double desktopMin = 1024;

  static ScreenType typeForWidth(double width) {
    if (width < mobileMax) {
      return ScreenType.mobile;
    }
    if (width < desktopMin) {
      return ScreenType.tablet;
    }
    return ScreenType.desktop;
  }

  static bool isMobile(double width) => width < mobileMax;
  static bool isTablet(double width) =>
      width >= mobileMax && width < desktopMin;
  static bool isDesktop(double width) => width >= desktopMin;
}
