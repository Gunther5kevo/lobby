import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';
import 'auth_provider.dart';
import 'firestore_providers.dart';

// ── Firestore → model mapping ──────────────────────────────────────────────

Group _groupFromMap(Map<String, dynamic> d) => Group(
      id:                    d['id']                  as String,
      name:                  d['name']                as String? ?? 'Unnamed',
      emoji:                 d['emoji']               as String? ?? '🎮',
      avatarColorIndex:      d['avatarColorIndex']    as int?    ?? 0,
      memberCount:           d['memberCount']         as int?    ?? 0,
      onlineCount:           d['onlineCount']         as int?    ?? 0,
      description:           d['description']         as String? ?? '',
      isMuted:               d['isMuted']             as bool?   ?? false,
      recentActivity:        d['lastActivityPreview'] as String?,
      recentActivityChannel: d['lastActivityChannel'] as String?,
      tags:                  List<String>.from(d['tags'] as List? ?? []),
      channels:              const [],
    );

Channel _channelFromMap(Map<String, dynamic> d) => Channel(
      id:          d['id']          as String,
      name:        d['name']        as String? ?? 'channel',
      type:        _channelType(d['type'] as String? ?? 'text'),
      lastMessage: d['lastMessage'] as String?,
      isLocked:    d['isLocked']    as bool?   ?? false,
      unreadCount: 0,
    );

ChannelType _channelType(String raw) => switch (raw) {
      'voice'         => ChannelType.voice,
      'clips'         => ChannelType.clips,
      'strategy'      => ChannelType.strategy,
      'announcements' => ChannelType.announcements,
      _               => ChannelType.text,
    };

GroupMessage _msgFromMap(Map<String, dynamic> d) {
  DateTime time;
  try {
    final ts = d['sentAt'];
    time = ts is DateTime ? ts : (ts as dynamic).toDate() as DateTime;
  } catch (_) {
    time = DateTime.now();
  }
  return GroupMessage(
    id:               d['id']               as String,
    senderUid:        d['senderUid']        as String,
    senderName:       d['senderName']       as String? ?? 'Player',
    senderColorIndex: d['senderColorIndex'] as int?    ?? 0,
    text:             d['text']             as String? ?? '',
    sentAt:           time,
  );
}

// ── My joined groups ───────────────────────────────────────────────────────

final myGroupsProvider = StreamProvider<List<Group>>((ref) {
  final uid     = ref.watch(currentUidRequiredProvider);
  final service = ref.watch(firestoreServiceProvider);
  return service.myGroupsStream(uid).map((l) => l.map(_groupFromMap).toList());
});

// ── Channels for a group (family) ─────────────────────────────────────────

final groupChannelsProvider =
    StreamProvider.family<List<Channel>, String>((ref, groupId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.channelsStream(groupId).map((l) => l.map(_channelFromMap).toList());
});

// ── Messages for a channel (family keyed by record) ───────────────────────

typedef GroupChannelKey = ({String groupId, String channelId});

final groupMessagesProvider =
    StreamProvider.family<List<GroupMessage>, GroupChannelKey>((ref, key) {
  final service = ref.watch(firestoreServiceProvider);
  return service
      .groupMessagesStream(key.groupId, key.channelId)
      .map((l) => l.map(_msgFromMap).toList());
});

// ── Active expanded group ──────────────────────────────────────────────────

final activeGroupIdProvider = StateProvider<String?>((ref) => null);

// ── Local mute overrides ───────────────────────────────────────────────────

final _mutedGroupsProvider = StateProvider<Set<String>>((ref) => {});

// ── Groups enriched with live channels ────────────────────────────────────

final groupsWithChannelsProvider = Provider<AsyncValue<List<Group>>>((ref) {
  final groupsAsync = ref.watch(myGroupsProvider);
  final mutedIds    = ref.watch(_mutedGroupsProvider);
  return groupsAsync.whenData((groups) => groups.map((g) {
        final channels = ref.watch(groupChannelsProvider(g.id)).valueOrNull ?? [];
        final isMuted  = mutedIds.contains(g.id) || g.isMuted;
        return g.copyWith(channels: channels, isMuted: isMuted);
      }).toList());
});

// ── Search filtered list ───────────────────────────────────────────────────

final groupSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredGroupsProvider = Provider<List<Group>>((ref) {
  final groups = ref.watch(groupsWithChannelsProvider).valueOrNull ?? [];
  final query  = ref.watch(groupSearchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) return groups;
  return groups.where((g) =>
      g.name.toLowerCase().contains(query) ||
      g.tags.any((t) => t.toLowerCase().contains(query))).toList();
});

// ── Total unread badge count ───────────────────────────────────────────────

final totalGroupUnreadProvider = Provider<int>((ref) =>
    ref.watch(groupsWithChannelsProvider).valueOrNull
        ?.where((g) => !g.isMuted)
        .fold(0, (s, g) => s! + g.totalUnread) ?? 0);

// ── Public groups for Browse sheet ────────────────────────────────────────

final browseTagProvider = StateProvider<String>((ref) => '');

final publicGroupsProvider = StreamProvider<List<Group>>((ref) {
  final tag     = ref.watch(browseTagProvider);
  final service = ref.watch(firestoreServiceProvider);
  final stream  = tag.isEmpty
      ? service.publicGroupsStream()
      : service.publicGroupsByTagStream(tag);
  return stream.map((l) => l.map(_groupFromMap).toList());
});

// ── Actions notifier ───────────────────────────────────────────────────────

final groupsActionProvider =
    StateNotifierProvider<GroupsActionNotifier, void>(GroupsActionNotifier.new);

class GroupsActionNotifier extends StateNotifier<void> {
  GroupsActionNotifier(this._ref) : super(null);
  final Ref _ref;

  String get _uid => _ref.read(currentUidRequiredProvider);

  Future<void> joinGroup(String groupId) =>
      _ref.read(firestoreServiceProvider).joinGroup(groupId, _uid);

  Future<void> leaveGroup(String groupId) async {
    await _ref.read(firestoreServiceProvider).leaveGroup(groupId, _uid);
    if (_ref.read(activeGroupIdProvider) == groupId) {
      _ref.read(activeGroupIdProvider.notifier).state = null;
    }
  }

  void toggleMute(String groupId) {
    final n    = _ref.read(_mutedGroupsProvider.notifier);
    final muted = {...n.state};
    muted.contains(groupId) ? muted.remove(groupId) : muted.add(groupId);
    n.state = muted;
  }

  Future<void> sendMessage({
    required String groupId,
    required String channelId,
    required String text,
  }) async {
    final profile = await _ref.read(firestoreServiceProvider).getProfile(_uid);
    await _ref.read(firestoreServiceProvider).sendGroupMessage(
      groupId:          groupId,
      channelId:        channelId,
      senderUid:        _uid,
      senderName:       profile?['displayName'] as String? ?? 'Player',
      senderColorIndex: profile?['avatarColorIndex'] as int? ?? 0,
      text:             text,
    );
  }

  Future<void> markChannelRead(String groupId, String channelId) =>
      _ref.read(firestoreServiceProvider)
          .markGroupChannelRead(groupId, channelId, _uid);
}