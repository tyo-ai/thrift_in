import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Manages user online/offline presence using Supabase Realtime Presence.
/// This approach does NOT require any database columns.
///
/// Each user tracks themselves on a per-user realtime channel.
/// Other users can subscribe to that channel to detect online/offline status.
class PresenceService {
  static PresenceService? _instance;
  static PresenceService get instance => _instance ??= PresenceService._();
  PresenceService._();

  RealtimeChannel? _myChannel;

  static String _channelName(int userId) => 'user-online-$userId';

  /// Start broadcasting current user as online.
  /// Call this when the app becomes active.
  Future<void> startTracking(int userId) async {
    try {
      // Clean up any existing channel first
      await stopTracking();

      final channel = SupabaseConfig.client.channel(_channelName(userId));

      channel.subscribe((status, _) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await channel.track({
            'user_id': userId,
            'online_at': DateTime.now().toIso8601String(),
          });
        }
      });

      _myChannel = channel;
    } catch (_) {
      // Presence is best-effort
    }
  }

  /// Stop broadcasting — marks current user as offline.
  /// Call this when the app goes to background or is closed.
  Future<void> stopTracking() async {
    try {
      final ch = _myChannel;
      _myChannel = null;
      if (ch != null) {
        await ch.untrack();
        await SupabaseConfig.client.removeChannel(ch);
      }
    } catch (_) {
      // Presence is best-effort
    }
  }

  /// Subscribe to another user's online/offline status.
  ///
  /// [onPresenceChange] is called immediately after subscribing with the
  /// current status, and again whenever the status changes.
  ///
  /// Returns the [RealtimeChannel] — caller must call
  /// [SupabaseConfig.client.removeChannel] when no longer needed.
  RealtimeChannel subscribeToUserPresence(
    int userId,
    void Function(bool isOnline) onPresenceChange,
  ) {
    final channel = SupabaseConfig.client.channel(_channelName(userId));

    // Fires whenever presence state syncs (join, leave, reconnect)
    channel.onPresenceSync((_) {
      final state = channel.presenceState();
      onPresenceChange(state.isNotEmpty);
    });

    channel.subscribe();
    return channel;
  }
}
