import 'dart:io';
import 'dart:convert';
import 'package:device_apps/device_apps.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

// ── Known game package names (Android) ────────────────────────────────────

/// Map of game display name → Android package name.
/// Add more games here as needed.
const Map<String, _GamePackage> kKnownGames = {
  'Valorant':          _GamePackage('com.riotgames.league.wildrift',     '🎯', false), // placeholder — Valorant is PC only; Wild Rift is mobile
  'League of Legends': _GamePackage('com.riotgames.league.wildrift',     '⚔️', true),
  'Apex Legends':      _GamePackage('com.ea.game.apexlegends_row',       '🔫', true),
  'Fortnite':          _GamePackage('com.epicgames.fortnite',            '🏗️', true),
  'PUBG Mobile':       _GamePackage('com.tencent.ig',                    '🪖', true),
  'Call of Duty':      _GamePackage('com.activision.callofduty.shooter', '💥', true),
  'Genshin Impact':    _GamePackage('com.miHoYo.GenshinImpact',          '✨', true),
  'Minecraft':         _GamePackage('com.mojang.minecraftpe',            '⛏️', true),
  'Clash of Clans':    _GamePackage('com.supercell.clashofclans',        '⚔️', true),
  'Roblox':            _GamePackage('com.roblox.client',                 '🟡', true),
};

class _GamePackage {
  const _GamePackage(this.packageName, this.emoji, this.hasMobile);
  final String packageName;
  final String emoji;
  final bool hasMobile;
}

// ── Detected game result ───────────────────────────────────────────────────

class DetectedGame {
  const DetectedGame({
    required this.name,
    required this.emoji,
    required this.packageName,
    required this.versionName,
  });

  final String name;
  final String emoji;
  final String packageName;
  final String versionName;

  Map<String, dynamic> toMap() => {
        'id':          packageName,
        'gameName':    name,
        'emoji':       emoji,
        'source':      'detected',
        'versionName': versionName,
      };
}

// ── OAuth result ───────────────────────────────────────────────────────────

class OAuthGameResult {
  const OAuthGameResult({
    required this.gameName,
    required this.emoji,
    required this.accountName,
    required this.rank,
    required this.rankEmoji,
    required this.rawData,
  });

  final String gameName;
  final String emoji;
  final String accountName;
  final String rank;
  final String rankEmoji;
  final Map<String, dynamic> rawData;

  Map<String, dynamic> toMap() => {
        'id':          'oauth_${gameName.toLowerCase().replaceAll(' ', '_')}',
        'gameName':    gameName,
        'emoji':       emoji,
        'accountName': accountName,
        'rank':        rank,
        'rankEmoji':   rankEmoji,
        'source':      'oauth',
        ...rawData,
      };
}

// ── Game detection service ─────────────────────────────────────────────────

class GameDetectionService {

  // ── Android: detect installed games ───────────────────────────

  /// Returns a list of known games that are currently installed.
  /// Only works on Android. Returns empty list on iOS.
  Future<List<DetectedGame>> detectInstalledGames() async {
    if (!Platform.isAndroid) return [];

    final detected = <DetectedGame>[];

    for (final entry in kKnownGames.entries) {
      final gameName = entry.key;
      final meta     = entry.value;

      try {
        final app = await DeviceApps.getApp(meta.packageName);
        if (app != null) {
          detected.add(DetectedGame(
            name:        gameName,
            emoji:       meta.emoji,
            packageName: meta.packageName,
            versionName: (app as ApplicationWithIcon).versionName ?? '',
          ));
        }
      } catch (_) {
        // Package not found — skip silently
      }
    }

    return detected;
  }

  // ── Riot Games OAuth (Valorant / LoL) ─────────────────────────
  //
  // Riot uses OAuth 2.0 with PKCE.
  // You must register your app at https://developer.riotgames.com/
  // and add your redirect URI (e.g. lobby://riot/callback) to the
  // allowed redirect URIs list.
  //
  // Required: RIOT_CLIENT_ID in your environment / build config.

  static const _riotClientId    = 'YOUR_RIOT_CLIENT_ID';      // ← fill in
  static const _riotRedirectUri = 'lobby://riot/callback';
  static const _riotAuthBase    = 'https://auth.riotgames.com/authorize';
  static const _riotTokenUrl    = 'https://auth.riotgames.com/token';
  static const _riotAccountUrl  = 'https://americas.api.riotgames.com/riot/account/v1/accounts/me';

  Future<OAuthGameResult?> connectRiotAccount() async {
    try {
      // ── Step 1: launch browser auth ─────────────────────────
      final result = await FlutterWebAuth2.authenticate(
        url: Uri.https('auth.riotgames.com', '/authorize', {
          'client_id':     _riotClientId,
          'redirect_uri':  _riotRedirectUri,
          'response_type': 'code',
          'scope':         'openid',
        }).toString(),
        callbackUrlScheme: 'lobby',
      );

      // ── Step 2: extract auth code ────────────────────────────
      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) return null;

      // ── Step 3: exchange code for tokens ─────────────────────
      final tokenResponse = await http.post(
        Uri.parse(_riotTokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type':   'authorization_code',
          'code':          code,
          'redirect_uri':  _riotRedirectUri,
          'client_id':     _riotClientId,
        },
      );

      if (tokenResponse.statusCode != 200) return null;
      final tokens = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final accessToken = tokens['access_token'] as String;

      // ── Step 4: fetch Riot account info ──────────────────────
      final accountResponse = await http.get(
        Uri.parse(_riotAccountUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (accountResponse.statusCode != 200) return null;
      final account = jsonDecode(accountResponse.body) as Map<String, dynamic>;

      final gameName  = account['gameName']  as String? ?? 'Unknown';
      final tagLine   = account['tagLine']   as String? ?? 'NA1';
      final accountName = '$gameName#$tagLine';

      // ── Step 5: fetch rank from Riot API ──────────────────────
      // Note: ranked data requires the Valorant-specific endpoint
      // and your Riot API key — this is a placeholder call.
      // Replace with the actual endpoint once your API key is approved.
      final rankInfo = await _fetchRiotRank(
        puuid:       account['puuid'] as String? ?? '',
        accessToken: accessToken,
      );

      return OAuthGameResult(
        gameName:    'Valorant',
        emoji:       '🎯',
        accountName: accountName,
        rank:        rankInfo['rank']     as String? ?? 'Unranked',
        rankEmoji:   rankInfo['rankEmoji'] as String? ?? '⚪',
        rawData:     {'puuid': account['puuid'], 'tagLine': tagLine},
      );
    } catch (e) {
      // OAuth cancelled or failed
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchRiotRank({
    required String puuid,
    required String accessToken,
  }) async {
    // Placeholder — replace with actual Valorant ranked endpoint:
    // https://na.api.riotgames.com/val/ranked/v1/leaderboards/by-act/{actId}
    // Requires a production Riot API key.
    return {'rank': 'Unranked', 'rankEmoji': '⚪'};
  }

  // ── Steam OAuth ────────────────────────────────────────────────
  //
  // Steam uses OpenID 2.0 (not OAuth2), which redirects to a callback URL.
  // Register your app at https://steamcommunity.com/dev/apikey
  //
  // Required: STEAM_API_KEY in your environment / build config.

  static const _steamApiKey     = 'YOUR_STEAM_API_KEY';       // ← fill in
  static const _steamRedirectUri = 'lobby://steam/callback';
  static const _steamOpenIdUrl   = 'https://steamcommunity.com/openid/login';
  static const _steamProfileUrl  = 'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/';

  Future<OAuthGameResult?> connectSteamAccount() async {
    try {
      // ── Step 1: launch Steam OpenID ──────────────────────────
      final result = await FlutterWebAuth2.authenticate(
        url: Uri.https('steamcommunity.com', '/openid/login', {
          'openid.ns':         'http://specs.openid.net/auth/2.0',
          'openid.mode':       'checkid_setup',
          'openid.return_to':  _steamRedirectUri,
          'openid.realm':      'lobby://',
          'openid.identity':   'http://specs.openid.net/auth/2.0/identifier_select',
          'openid.claimed_id': 'http://specs.openid.net/auth/2.0/identifier_select',
        }).toString(),
        callbackUrlScheme: 'lobby',
      );

      // ── Step 2: extract Steam ID from return URL ─────────────
      final uri      = Uri.parse(result);
      final identity = uri.queryParameters['openid.claimed_id'] ?? '';
      final steamId  = RegExp(r'/(\d+)$').firstMatch(identity)?.group(1);
      if (steamId == null) return null;

      // ── Step 3: fetch Steam profile ───────────────────────────
      final profileResponse = await http.get(Uri.parse(
        '$_steamProfileUrl?key=$_steamApiKey&steamids=$steamId',
      ));

      if (profileResponse.statusCode != 200) return null;
      final data     = jsonDecode(profileResponse.body) as Map<String, dynamic>;
      final players  = (data['response']?['players'] as List?)?.cast<Map<String, dynamic>>();
      final player   = players?.firstOrNull;
      if (player == null) return null;

      final personaName = player['personaname'] as String? ?? 'Unknown';

      // ── Step 4: get most-played game ─────────────────────────
      // Placeholder — you can call GetOwnedGames for hours played
      final topGame = await _fetchTopSteamGame(steamId);

      return OAuthGameResult(
        gameName:    topGame['name'] as String? ?? 'Steam',
        emoji:       '🎮',
        accountName: personaName,
        rank:        'N/A',
        rankEmoji:   '🎮',
        rawData:     {'steamId': steamId, 'profileUrl': player['profileurl']},
      );
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchTopSteamGame(String steamId) async {
    // Placeholder — replace with GetOwnedGames call:
    // https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/
    return {'name': 'Steam', 'appId': null};
  }
}