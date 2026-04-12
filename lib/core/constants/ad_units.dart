import 'dart:io';

import 'package:flutter/foundation.dart';

/// Centralised ad-unit IDs for Google Mobile Ads.
abstract final class AdUnits {
  static String get banner {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-8640672469603981/7971837478'
        : 'ca-app-pub-3940256099942544/2934735716'; // TODO: replace with real iOS ID
  }

  static String get rewarded {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-8640672469603981/2858766113'
        : 'ca-app-pub-3940256099942544/1712485313'; // TODO: replace with real iOS ID
  }
}
