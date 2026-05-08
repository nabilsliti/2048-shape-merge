import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shape_merge/core/models/shop_promo.dart';
import 'package:shape_merge/core/services/app_logger.dart';

const _log = AppLogger('RemoteConfig');

class RemoteConfigService {
  RemoteConfigService._();
  static final instance = RemoteConfigService._();

  final _rc = FirebaseRemoteConfig.instance;

  /// Active promos keyed by productId.
  Map<String, ShopPromo> _activePromos = {};
  Map<String, ShopPromo> get activePromos => _activePromos;

  Future<void> init() async {
    _log.info('Initializing Remote Config...');
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: kDebugMode
          ? const Duration(seconds: 10)
          : const Duration(hours: 1),
    ));

    // Defaults — no promo
    await _rc.setDefaults(const {'shop_promos': '[]'});

    try {
      final activated = await _rc.fetchAndActivate();
      _log.info('Remote Config fetched (activated=$activated)');
    } catch (e) {
      _log.warning('Remote Config fetch failed', error: e);
    }

    _parsePromos();

    // Listen for real-time updates
    _rc.onConfigUpdated.listen((event) async {
      await _rc.activate();
      _parsePromos();
      _log.info('Remote Config updated, promos refreshed');
    });
  }

  void _parsePromos() {
    final raw = _rc.getString('shop_promos');
    _log.info('shop_promos raw value: "$raw"');
    _activePromos = {};

    if (raw.isEmpty || raw == '[]') {
      _log.info('No promos configured');
      return;
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final now = DateTime.now();

      for (final item in list) {
        final promo = ShopPromo.fromJson(item as Map<String, dynamic>);
        if (promo.isActiveAt(now)) {
          _activePromos[promo.productId] = promo;
        }
      }

      _log.info('Parsed ${_activePromos.length} active promos');
    } catch (e) {
      _log.error('Failed to parse shop_promos', error: e);
    }
  }

  /// Get promo for a specific product, or null.
  ShopPromo? promoFor(String productId) => _activePromos[productId];

  /// Whether any promo is currently active.
  bool get hasActivePromos => _activePromos.isNotEmpty;
}
