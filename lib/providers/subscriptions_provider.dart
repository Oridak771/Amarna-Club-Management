import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';
import '../models/subscription.dart';
import '../services/odoo_subscription_service.dart';

/// Current search text for the subscriptions screen.
final subscriptionQueryProvider = StateProvider<String>((ref) => '');

/// Subscriptions matching the current query, read live from Odoo.
final subscriptionsProvider =
    FutureProvider<List<Subscription>>((ref) async {
  if (!AppEnvironment.isOdooConfigured) {
    return const [];
  }
  final query = ref.watch(subscriptionQueryProvider);
  return ref
      .read(odooSubscriptionServiceProvider)
      .fetchSubscriptions(query: query);
});
