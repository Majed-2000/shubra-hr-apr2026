// ============================================================================
// File: shared/services/deep_link_router.dart
// Purpose: Single source of truth for FCM data-payload routing.
//          Splash and home consume `pendingDeepLink` after auth+lock settle.
//          Used by: ticket push (feature 10), iqama push (feature 16).
// Payload contract:  message.data["type"] decides target route.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DeepLink {
  final String route;
  final Object? arguments;
  const DeepLink(this.route, [this.arguments]);
}

class DeepLinkRouter {
  /// Reactive slot. Splash + home watch this and consume on first build.
  static final ValueNotifier<DeepLink?> pendingDeepLink = ValueNotifier(null);

  /// Build a DeepLink from an FCM message's data payload, or null if no match.
  static DeepLink? fromMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    if (type == null || type.isEmpty) return null;

    switch (type) {
      case 'ticket_reply':
        final id = int.tryParse(data['ticket_id']?.toString() ?? '');
        if (id == null) return null;
        return DeepLink('/ticketDetail', id);
      case 'iqama_alert':
        return const DeepLink('/profile');
      default:
        return null;
    }
  }

  /// Queue a deep link to be consumed by the next post-auth screen.
  /// Safe to call multiple times — latest wins.
  static void queue(DeepLink link) {
    pendingDeepLink.value = link;
  }

  /// Consume and clear. Returns the link if one was queued.
  static DeepLink? consume() {
    final link = pendingDeepLink.value;
    pendingDeepLink.value = null;
    return link;
  }
}
