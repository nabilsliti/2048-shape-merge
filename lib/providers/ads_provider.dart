import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/services/ads_service.dart';

final adsServiceProvider = Provider<AdsService>((_) {
  final service = AdsService();
  service.init();
  return service;
});
