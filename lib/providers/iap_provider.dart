import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_merge/core/services/iap_service.dart';

final iapServiceProvider = Provider<IapService>((_) => IapService());
