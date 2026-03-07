import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

/// All Firebase Realtime Database operations.
///
/// RTDB schema:
///   /messages/{chatId}/{msgId}          — DM messages
///   /groupMessages/{channelId}/{msgId}  — Group channel messages
///   /parties/{partyId}                  — Live party session
///   /presence/{uid}                     — Online/offline state
///   /typing/{chatId}/{uid}              — Typing indicators
class RtdbService {
  RtdbService({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;
  final _uuid = const Uuid();

  // ── DM Messages ────────────────────────────────────────────────

  /// Stream of all messages in a DM chat, ordered by timestamp.
  Stream<List<Map<String, dynamic>>> dmMessagesStream(String chatId) {
    return _db
        .ref('messages/$chatId')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final value = event.snapshot.value;
      if (value == null) return [];

      final map = Map<String, dynamic>.from(value as Map);
      return map.entries.map((e) {
        final msg = Map<String, dynamic>.from(e.value as Map);
        msg['id'] = e.key;
        return msg;
      }).toList()
        ..sort((a, b) =>
            (a['timestamp'] as int).compareTo(b['timestamp'] as int));
    });
  }

  /// Sends a text message to a DM chat.
  Future<String> sendDmMessage({
    required String chatId,
    required String senderUid,
    required String senderName,
    required String text,
    String type = 'text',
    Map<String, dynamic>? extra, // for voice, image, gameInvite payloads
  }) async {
    final msgId = _uuid.v4();
    final payload = {
      'id':         msgId,
      'senderUid':  senderUid,
      'senderName': senderName,
      'text':       text,
      'type':       type,
      'timestamp':  ServerValue.timestamp,
      'status':     'sent',
      if (extra != null) ...extra,
    };

    await _db.ref('messages/$chatId/$msgId').set(payload);
    return msgId;
  }

  /// Updates a message's status (sent → delivered → read).
  Future<void> updateMessageStatus(
      String chatId, String msgId, String status) async {
    await _db.ref('messages/$chatId/$msgId/status').set(status);
  }

  // ── Group Channel Messages ─────────────────────────────────────

  Stream<List<Map<String, dynamic>>> channelMessagesStream(String channelId) {
    return _db
        .ref('groupMessages/$channelId')
        .orderByChild('timestamp')
        .limitToLast(100)
        .onValue
        .map((event) {
      final value = event.snapshot.value;
      if (value == null) return [];

      final map = Map<String, dynamic>.from(value as Map);
      return map.entries.map((e) {
        final msg = Map<String, dynamic>.from(e.value as Map);
        msg['id'] = e.key;
        return msg;
      }).toList()
        ..sort((a, b) =>
            (a['timestamp'] as int).compareTo(b['timestamp'] as int));
    });
  }

  Future<String> sendChannelMessage({
    required String channelId,
    required String senderUid,
    required String senderName,
    required String text,
    String type = 'text',
  }) async {
    final msgId = _uuid.v4();
    await _db.ref('groupMessages/$channelId/$msgId').set({
      'id':         msgId,
      'senderUid':  senderUid,
      'senderName': senderName,
      'text':       text,
      'type':       type,
      'timestamp':  ServerValue.timestamp,
    });
    return msgId;
  }

  // ── Typing indicators ──────────────────────────────────────────

  /// Set typing = true. Call [clearTyping] when the user stops.
  Future<void> setTyping(String chatId, String uid, bool isTyping) async {
    final ref = _db.ref('typing/$chatId/$uid');
    if (isTyping) {
      await ref.set(ServerValue.timestamp);
      // Auto-clear after 5 seconds (server-side via onDisconnect)
      await ref.onDisconnect().remove();
    } else {
      await ref.remove();
    }
  }

  /// Stream of uids currently typing in a chat (excludes self).
  Stream<List<String>> typingStream(String chatId, String myUid) {
    return _db.ref('typing/$chatId').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return [];
      final map = Map<String, dynamic>.from(value as Map);
      return map.keys.where((uid) => uid != myUid).toList();
    });
  }

  // ── Presence ───────────────────────────────────────────────────

  /// Marks the user as online and sets up onDisconnect to go offline.
  Future<void> goOnline(String uid) async {
    final ref = _db.ref('presence/$uid');
    await ref.set({
      'online':    true,
      'lastSeen':  ServerValue.timestamp,
    });
    // When the connection drops, Firebase automatically sets offline
    await ref.onDisconnect().set({
      'online':   false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  Future<void> goOffline(String uid) async {
    await _db.ref('presence/$uid').set({
      'online':   false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  /// Stream of a single user's online presence.
  Stream<bool> presenceStream(String uid) {
    return _db.ref('presence/$uid/online').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  // ── Party sessions ─────────────────────────────────────────────

  /// Creates a new party node and returns the generated party ID.
  Future<String> createParty({
    required String captainUid,
    required Map<String, dynamic> initialData,
  }) async {
    final partyId = _uuid.v4();
    await _db.ref('parties/$partyId').set({
      ...initialData,
      'id':         partyId,
      'captainUid': captainUid,
      'createdAt':  ServerValue.timestamp,
      'status':     'waiting',
    });
    // Disband when captain disconnects
    await _db.ref('parties/$partyId').onDisconnect().remove();
    return partyId;
  }

  Stream<Map<String, dynamic>?> partyStream(String partyId) {
    return _db.ref('parties/$partyId').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return null;
      return Map<String, dynamic>.from(value as Map);
    });
  }

  Future<void> updateParty(String partyId, Map<String, dynamic> data) async {
    await _db.ref('parties/$partyId').update(data);
  }

  Future<void> updatePartyMember(
      String partyId, String uid, Map<String, dynamic> data) async {
    await _db.ref('parties/$partyId/members/$uid').update(data);
  }

  Future<void> disbandParty(String partyId) async {
    await _db.ref('parties/$partyId').remove();
  }

  Future<void> leaveParty(String partyId, String uid) async {
    await _db.ref('parties/$partyId/members/$uid').remove();
  }

  // ── Reactions ──────────────────────────────────────────────────

  Future<void> toggleReaction({
    required String chatId,
    required String msgId,
    required String emoji,
    required String uid,
    required bool isDm, // true = DM, false = group channel
  }) async {
    final path = isDm
        ? 'messages/$chatId/$msgId/reactions/$emoji/$uid'
        : 'groupMessages/$chatId/$msgId/reactions/$emoji/$uid';

    final ref = _db.ref(path);
    final snap = await ref.get();

    if (snap.exists) {
      await ref.remove(); // toggle off
    } else {
      await ref.set(true); // toggle on
    }
  }
}