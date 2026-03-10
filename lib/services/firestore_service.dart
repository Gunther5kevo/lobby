import 'package:cloud_firestore/cloud_firestore.dart';

/// All Firestore reads and writes.
/// UI never touches Firestore directly — always goes through here.
///
/// Collection schema:
///   /users/{uid}                      — UserProfile doc
///   /users/{uid}/friends/{uid}        — Friend sub-doc
///   /friendRequests/{requestId}       — FriendRequest doc
///   /groups/{groupId}                 — Group doc
///   /groups/{groupId}/channels/{id}   — Channel sub-doc
///   /groups/{groupId}/members/{uid}   — Membership sub-doc
///   /chats/{chatId}                   — DM chat doc
class FirestoreService {
  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ── References ─────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _friendRequests =>
      _db.collection('friendRequests');

  CollectionReference<Map<String, dynamic>> get _groups =>
      _db.collection('groups');

  // ── Users / Profiles ───────────────────────────────────────────

  Future<void> createUserProfile({
    required String uid,
    required String displayName,
    required String handle,
    required String email,
    String? avatarUrl,
  }) async {
    await _users.doc(uid).set({
      'uid':           uid,
      'displayName':   displayName,
      'handle':        handle,
      'email':         email,
      'avatarUrl':     avatarUrl,
      'bio':           '',
      'status':        'online',
      'level':         1,
      'xp':            0,
      'xpToNext':      1000,
      'guildPoints':   0,
      'joinedAt':      FieldValue.serverTimestamp(),
      'connectedGames': [],
      'achievements':  [],
    });
  }

  /// Stream of the current user's profile. Rebuilds on any change.
  Stream<Map<String, dynamic>?> profileStream(String uid) {
    return _users.doc(uid).snapshots().map((snap) => snap.data());
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.data();
  }

  // ── FCM tokens ─────────────────────────────────────────────────

  Future<void> saveFcmToken(String uid, String token) async {
    await _users.doc(uid).collection('tokens').doc(token).set({
      'token':     token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform':  'mobile',
    });
  }

  Future<void> deleteFcmToken(String uid, String token) async {
    await _users.doc(uid).collection('tokens').doc(token).delete();
  }

  // ── Friends ────────────────────────────────────────────────────

  /// Real-time stream of this user's accepted friends.
  Stream<List<Map<String, dynamic>>> friendsStream(String uid) {
    return _users
        .doc(uid)
        .collection('friends')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> addFriend(String myUid, String theirUid) async {
    final batch = _db.batch();
    final now   = FieldValue.serverTimestamp();
    batch.set(
      _users.doc(myUid).collection('friends').doc(theirUid),
      {'uid': theirUid, 'addedAt': now},
    );
    batch.set(
      _users.doc(theirUid).collection('friends').doc(myUid),
      {'uid': myUid, 'addedAt': now},
    );
    await batch.commit();
  }

  Future<void> removeFriend(String myUid, String theirUid) async {
    final batch = _db.batch();
    batch.delete(_users.doc(myUid).collection('friends').doc(theirUid));
    batch.delete(_users.doc(theirUid).collection('friends').doc(myUid));
    await batch.commit();
  }

  // ── User search ────────────────────────────────────────────────

  /// Searches users by handle prefix. [query] is raw input (with or without #).
  /// Excludes [excludeUid] (the current user). Returns up to 10 results.
  Future<List<Map<String, dynamic>>> searchUsersByHandle(
    String query, {
    required String excludeUid,
  }) async {
    if (query.trim().isEmpty) return [];
    final q      = query.trim().toLowerCase().replaceFirst(RegExp(r'^#'), '');
    if (q.isEmpty) return [];
    final prefix = '#$q';
    final snap   = await _users
        .where('handle', isGreaterThanOrEqualTo: prefix)
        .where('handle', isLessThan: '$prefix\uf8ff')
        .limit(10)
        .get();
    return snap.docs
        .map((d) => d.data())
        .where((d) => d['uid'] != excludeUid)
        .toList();
  }

  // ── Friend requests ────────────────────────────────────────────

  /// Stream of incoming pending friend requests for [uid].
  Stream<List<Map<String, dynamic>>> incomingRequestsStream(String uid) {
    return _friendRequests
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final results = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        // Enrich with sender profile if display fields weren't stored inline
        if (data['fromDisplayName'] == null ||
            (data['fromDisplayName'] as String).isEmpty) {
          final profile = await getProfile(data['fromUid'] as String);
          if (profile != null) {
            data['fromDisplayName']      = profile['displayName'] ?? '';
            data['fromHandle']           = profile['handle'] ?? '';
            data['fromAvatarColorIndex'] = profile['avatarColorIndex'] ?? 0;
          }
        }
        results.add(data);
      }
      return results;
    });
  }

  /// Sends a friend request from [fromUid] to [toUid].
  /// Always writes all seven fields so the Firestore hasOnly rule is satisfied.
  Future<void> sendFriendRequest({
    required String fromUid,
    required String toUid,
    String? fromDisplayName,
    String? fromHandle,
    int fromAvatarColorIndex = 0,
  }) async {
    final docId = '${fromUid}_$toUid';
    await _friendRequests.doc(docId).set({
      'fromUid':              fromUid,
      'toUid':                toUid,
      'status':               'pending',
      'createdAt':            FieldValue.serverTimestamp(),
      'fromDisplayName':      fromDisplayName ?? '',   // ✅ never omitted
      'fromHandle':           fromHandle ?? '',        // ✅ never omitted
      'fromAvatarColorIndex': fromAvatarColorIndex,
    });
  }

  Future<void> acceptFriendRequest({
    required String requestId,
    required String myUid,
    required String theirUid,
  }) async {
    final batch = _db.batch();
    batch.update(_friendRequests.doc(requestId), {'status': 'accepted'});
    final now = FieldValue.serverTimestamp();
    batch.set(
      _users.doc(myUid).collection('friends').doc(theirUid),
      {'uid': theirUid, 'addedAt': now},
    );
    batch.set(
      _users.doc(theirUid).collection('friends').doc(myUid),
      {'uid': myUid, 'addedAt': now},
    );
    await batch.commit();
  }

  Future<void> declineFriendRequest(String requestId) async {
    await _friendRequests.doc(requestId).update({'status': 'declined'});
  }

  // ── Groups ─────────────────────────────────────────────────────

  /// Stream of groups the user belongs to, ordered by most recent activity.
  Stream<List<Map<String, dynamic>>> myGroupsStream(String uid) {
    return _groups
        .where('memberUids', arrayContains: uid)
        .orderBy('lastActivity', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Stream of channels inside a group, ordered by their display order.
  Stream<List<Map<String, dynamic>>> channelsStream(String groupId) {
    return _groups
        .doc(groupId)
        .collection('channels')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Stream of messages in a group channel, newest last.
  Stream<List<Map<String, dynamic>>> groupMessagesStream(
      String groupId, String channelId) {
    return _groups
        .doc(groupId)
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .limitToLast(80)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Sends a message to a group channel and updates channel + group metadata.
  Future<void> sendGroupMessage({
    required String groupId,
    required String channelId,
    required String senderUid,
    required String senderName,
    required int senderColorIndex,
    required String text,
  }) async {
    final msgRef = _groups
        .doc(groupId)
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc();
    final batch = _db.batch();
    batch.set(msgRef, {
      'senderUid':        senderUid,
      'senderName':       senderName,
      'senderColorIndex': senderColorIndex,
      'text':             text,
      'sentAt':           FieldValue.serverTimestamp(),
    });
    batch.update(
      _groups.doc(groupId).collection('channels').doc(channelId),
      {
        'lastMessage':    text,
        'lastMessageAt':  FieldValue.serverTimestamp(),
        'lastSenderName': senderName,
      },
    );
    batch.update(_groups.doc(groupId), {
      'lastActivity':        FieldValue.serverTimestamp(),
      'lastActivityChannel': channelId,
      'lastActivityPreview': '$senderName: $text',
    });
    await batch.commit();
  }

  /// Marks channel as read for [uid] via a read-cursor on the membership doc.
  Future<void> markGroupChannelRead(
      String groupId, String channelId, String uid) async {
    await _groups
        .doc(groupId)
        .collection('members')
        .doc(uid)
        .set(
          {'readAt_$channelId': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
  }

  /// Stream of public groups for Browse sheet, sorted by member count.
  Stream<List<Map<String, dynamic>>> publicGroupsStream({int limit = 30}) {
    return _groups
        .where('isPublic', isEqualTo: true)
        .orderBy('memberCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Stream of public groups filtered by a specific tag.
  Stream<List<Map<String, dynamic>>> publicGroupsByTagStream(String tag) {
    return _groups
        .where('isPublic', isEqualTo: true)
        .where('tags', arrayContains: tag)
        .orderBy('memberCount', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  Future<void> joinGroup(String groupId, String uid) async {
    await _groups.doc(groupId).update({
      'memberUids':  FieldValue.arrayUnion([uid]),
      'memberCount': FieldValue.increment(1),
    });
    await _groups.doc(groupId).collection('members').doc(uid).set({
      'uid':      uid,
      'joinedAt': FieldValue.serverTimestamp(),
      'role':     'member',
    });
  }

  Future<void> leaveGroup(String groupId, String uid) async {
    final batch = _db.batch();
    batch.update(_groups.doc(groupId), {
      'memberUids':  FieldValue.arrayRemove([uid]),
      'memberCount': FieldValue.increment(-1),
    });
    batch.delete(_groups.doc(groupId).collection('members').doc(uid));
    await batch.commit();
  }

  // ── Direct chats ───────────────────────────────────────────────

  /// Returns the deterministic DM chat ID for two users.
  /// Always smaller UID first so both users share the same doc.
  String dmChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Stream of all DM conversations for [uid], ordered by most recent message.
  Stream<List<Map<String, dynamic>>> dmChatsStream(String uid) {
    return _db
        .collection('chats')
        .where('participantUids', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Creates or updates a DM chat doc with the latest message preview.
  /// Increments unread count for all participants except the sender.
  Future<void> createOrUpdateDmChat({
    required String chatId,
    required List<String> participantUids,
    required String lastMessage,
    required String lastSenderUid,
  }) async {
    await _db.collection('chats').doc(chatId).set(
      {
        'participantUids': participantUids,
        'lastMessage':     lastMessage,
        'lastSenderUid':   lastSenderUid,
        'lastMessageAt':   FieldValue.serverTimestamp(),
        'unread': {
          for (final uid in participantUids)
            if (uid != lastSenderUid) uid: FieldValue.increment(1),
        },
      },
      SetOptions(merge: true),
    );
  }

  /// Resets the unread count to 0 for [uid] in a DM chat.
  Future<void> markDmRead(String chatId, String uid) async {
    await _db.collection('chats').doc(chatId).update({
      'unread.$uid': 0,
    });
  }

  // ── Connected games ────────────────────────────────────────────

  Future<void> saveConnectedGame(
      String uid, Map<String, dynamic> gameData) async {
    final docId = gameData['id'] as String;
    await _users
        .doc(uid)
        .collection('connectedGames')
        .doc(docId)
        .set(gameData);
  }

  /// Flips the isConnected boolean on a connected game document.
  Future<void> toggleConnectedGame(String uid, String gameId) async {
    final ref     = _users.doc(uid).collection('connectedGames').doc(gameId);
    final snap    = await ref.get();
    final current = snap.data()?['isConnected'] as bool? ?? true;
    await ref.update({'isConnected': !current});
  }

  Stream<List<Map<String, dynamic>>> connectedGamesStream(String uid) {
    return _users
        .doc(uid)
        .collection('connectedGames')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}