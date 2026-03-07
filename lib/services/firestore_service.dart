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

    // Write to both sides
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

  // ── Friend requests ────────────────────────────────────────────

  /// Stream of incoming friend requests for [uid].
  Stream<List<Map<String, dynamic>>> incomingRequestsStream(String uid) {
    return _friendRequests
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  Future<void> sendFriendRequest({
    required String fromUid,
    required String toUid,
  }) async {
    // Idempotent — use composite key so duplicates can't be created
    final docId = '${fromUid}_$toUid';
    await _friendRequests.doc(docId).set({
      'fromUid':   fromUid,
      'toUid':     toUid,
      'status':    'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest({
    required String requestId,
    required String myUid,
    required String theirUid,
  }) async {
    final batch = _db.batch();

    // Mark request accepted
    batch.update(_friendRequests.doc(requestId), {'status': 'accepted'});

    // Add both to each other's friends list
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

  /// Stream of groups the user belongs to.
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

  /// Stream of channels inside a group.
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

  Future<void> joinGroup(String groupId, String uid) async {
    await _groups.doc(groupId).update({
      'memberUids': FieldValue.arrayUnion([uid]),
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

  Future<void> updateGroupLastActivity({
    required String groupId,
    required String channelId,
    required String preview,
  }) async {
    await _groups.doc(groupId).update({
      'lastActivity':        FieldValue.serverTimestamp(),
      'lastActivityChannel': channelId,
      'lastActivityPreview': preview,
    });
  }

  // ── Direct chats ───────────────────────────────────────────────

  /// Returns the deterministic DM chat ID for two users.
  /// Always smaller UID first so both users share the same doc.
  String dmChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Stream of all DM conversations for [uid].
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
        // Unread counts keyed by uid
        'unread': {
          for (final uid in participantUids)
            if (uid != lastSenderUid) uid: FieldValue.increment(1),
        },
      },
      SetOptions(merge: true),
    );
  }

  Future<void> markDmRead(String chatId, String uid) async {
    await _db.collection('chats').doc(chatId).update({
      'unread.$uid': 0,
    });
  }

  // ── Connected games (sub-collection on user) ───────────────────

  Future<void> saveConnectedGame(
      String uid, Map<String, dynamic> gameData) async {
    final docId = gameData['id'] as String;
    await _users.doc(uid).collection('connectedGames').doc(docId).set(gameData);
  }

  Stream<List<Map<String, dynamic>>> connectedGamesStream(String uid) {
    return _users
        .doc(uid)
        .collection('connectedGames')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}