class AppRoutes {
  static const String home = '/home';
  static const String albums = '/albums';
  static const String search = '/search';
  static const String settings = '/settings';

  static const List<String> topLevel = <String>[home, albums, search];

  static int indexOf(String? routeName) {
    final int index = topLevel.indexOf(routeName ?? '');
    return index < 0 ? 0 : index;
  }

  static String routeForIndex(int index) {
    if (index < 0 || index >= topLevel.length) {
      return home;
    }
    return topLevel[index];
  }

  static String titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Albums';
      case 2:
        return 'Search';
      default:
        return 'Nimbus';
    }
  }

  static String normalize(String? routeName) {
    if (routeName == null || routeName == '/') {
      return home;
    }
    if (routeName == settings) {
      return settings;
    }
    return topLevel.contains(routeName) ? routeName : home;
  }
}
