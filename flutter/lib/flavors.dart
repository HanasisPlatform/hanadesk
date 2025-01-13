enum Flavor {
  member,
  cs,
}

class F {
  static Flavor? appFlavor;

  static String get name => appFlavor?.name ?? '';

  static String get title {
    switch (appFlavor) {
      case Flavor.member:
        return 'HanaDesk';
      case Flavor.cs:
        return 'HanaDeskCS';
      default:
        return 'title';
    }
  }
}
