enum FlavorType { dev, staging, prod }

class FlavorConfig {
  FlavorConfig._();

  static FlavorConfig? _instance;
  static FlavorConfig get instance => _instance!;

  late final FlavorType flavor;
  late final String name;

  static void initialize(FlavorType flavor) {
    _instance = FlavorConfig._()
      ..flavor = flavor
      ..name = switch (flavor) {
        FlavorType.dev => 'Shape Merge Dev',
        FlavorType.staging => 'Shape Merge Staging',
        FlavorType.prod => 'Shape Merge',
      };
  }

  bool get isDev => flavor == FlavorType.dev;
  bool get isStaging => flavor == FlavorType.staging;
  bool get isProd => flavor == FlavorType.prod;
}
