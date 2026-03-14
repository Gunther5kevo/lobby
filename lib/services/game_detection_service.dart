import 'dart:io';
import 'dart:convert';
import 'package:device_apps/device_apps.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

// ── Known game package names (Android) ────────────────────────────────────

const Map<String, _GamePackage> kKnownGames = {
  'Wild Rift':         _GamePackage('com.riotgames.league.wildrift',     '⚔️',  true),
  'Apex Legends':      _GamePackage('com.ea.game.apexlegends_row',       '🔫',  true),
  'Fortnite':          _GamePackage('com.epicgames.fortnite',            '🏗️', true),
  'PUBG Mobile':       _GamePackage('com.tencent.ig',                    '🪖',  true),
  'Call of Duty':      _GamePackage('com.activision.callofduty.shooter', '💥',  true),
  'Genshin Impact':    _GamePackage('com.miHoYo.GenshinImpact',          '✨',  true),
  'Minecraft':         _GamePackage('com.mojang.minecraftpe',            '⛏️', true),
  'Clash of Clans':    _GamePackage('com.supercell.clashofclans',        '🏰',  true),
  'Roblox':            _GamePackage('com.roblox.client',                 '🟡',  true),
  'Free Fire':         _GamePackage('com.dts.freefireth',                '🔥',  true),
  'Mobile Legends':    _GamePackage('com.mobile.legends',                '🗡️', true),
  'Clash Royale':      _GamePackage('com.supercell.clashroyale',         '👑',  true),
  'Among Us':          _GamePackage('com.innersloth.spacemafia',         '🚀',  true),
  'Brawl Stars':       _GamePackage('com.supercell.brawlstars',          '⭐',  true),
  'eFootball':         _GamePackage('jp.konami.pesam',                   '⚽',  true),
  'FIFA Mobile':       _GamePackage('com.ea.game.fifamobile',            '⚽',  true),
  'NBA 2K Mobile':     _GamePackage('com.catdaddy.nba2k18',              '🏀',  true),
};

class _GamePackage {
  const _GamePackage(this.packageName, this.emoji, this.hasMobile);
  final String packageName;
  final String emoji;
  final bool   hasMobile;
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
    'isConnected': true,
    'accountName': '',
    'rank':        '',
    'rankEmoji':   '',
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
    'isConnected': true,
    ...rawData,
  };
}

// ── Game detection service ─────────────────────────────────────────────────

class GameDetectionService {

  // ── Android: scan installed games ─────────────────────────────

  /// Checks each known game package and returns those installed.
  /// Android 11+ requires QUERY_ALL_PACKAGES or explicit <queries> in
  /// AndroidManifest.xml — see instructions below.
  Future<List<DetectedGame>> detectInstalledGames() async {
    if (!Platform.isAndroid) return [];

    final detected = <DetectedGame>[];

    for (final entry in kKnownGames.entries) {
      try {
        // includeAppIcons: false — faster, avoids cast issues
        final app = await DeviceApps.getApp(
          entry.value.packageName,
          false, // don't need icon
        );
        if (app != null) {
          detected.add(DetectedGame(
            name:        entry.key,
            emoji:       entry.value.emoji,
            packageName: entry.value.packageName,
            versionName: app.versionName ?? '',
          ));
        }
      } catch (_) {
        // Package not installed — skip
      }
    }

    return detected;
  }

  // ── Riot Games OAuth ───────────────────────────────────────────

  static String get _riotClientId    => dotenv.env['RIOT_CLIENT_ID']    ?? '';
  static const  _riotRedirectUri     = 'lobby://riot/callback';
  static const  _riotTokenUrl        = 'https://auth.riotgames.com/token';
  static const  _riotAccountUrl      = 'https://americas.api.riotgames.com/riot/account/v1/accounts/me';

  Future<OAuthGameResult?> connectRiotAccount() async {
    if (_riotClientId.isEmpty) {
      throw Exception('RIOT_CLIENT_ID not set in .env');
    }
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: Uri.https('auth.riotgames.com', '/authorize', {
          'client_id':     _riotClientId,
          'redirect_uri':  _riotRedirectUri,
          'response_type': 'code',
          'scope':         'openid',
        }).toString(),
        callbackUrlScheme: 'lobby',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) return null;

      final tokenResponse = await http.post(
        Uri.parse(_riotTokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type':  'authorization_code',
          'code':         code,
          'redirect_uri': _riotRedirectUri,
          'client_id':    _riotClientId,
        },
      );
      if (tokenResponse.statusCode != 200) return null;

      final tokens      = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final accessToken = tokens['access_token'] as String;

      final accountResponse = await http.get(
        Uri.parse(_riotAccountUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (accountResponse.statusCode != 200) return null;

      final account     = jsonDecode(accountResponse.body) as Map<String, dynamic>;
      final gameName    = account['gameName'] as String? ?? 'Unknown';
      final tagLine     = account['tagLine']  as String? ?? 'NA1';

      return OAuthGameResult(
        gameName:    'Valorant',
        emoji:       '🎯',
        accountName: '$gameName#$tagLine',
        rank:        'Unranked',
        rankEmoji:   '⚪',
        rawData:     {
          'puuid':   account['puuid'],
          'tagLine': tagLine,
        },
      );
    } catch (e) {
      return null;
    }
  }

  // ── Steam OpenID ───────────────────────────────────────────────

  static String get _steamApiKey     => dotenv.env['STEAM_API_KEY']     ?? '';
  static const  _steamRedirectUri    = 'lobby://steam/callback';
  static const  _steamProfileUrl     = 'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/';

  Future<OAuthGameResult?> connectSteamAccount() async {
    if (_steamApiKey.isEmpty) {
      throw Exception('STEAM_API_KEY not set in .env');
    }
    try {
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

      final uri      = Uri.parse(result);
      final identity = uri.queryParameters['openid.claimed_id'] ?? '';
      final steamId  = RegExp(r'/(\d+)$').firstMatch(identity)?.group(1);
      if (steamId == null) return null;

      final profileResponse = await http.get(Uri.parse(
        '$_steamProfileUrl?key=$_steamApiKey&steamids=$steamId',
      ));
      if (profileResponse.statusCode != 200) return null;

      final data        = jsonDecode(profileResponse.body) as Map<String, dynamic>;
      final players     = (data['response']?['players'] as List?)
          ?.cast<Map<String, dynamic>>();
      final player      = players?.firstOrNull;
      if (player == null) return null;

      final personaName = player['personaname'] as String? ?? 'Unknown';

      return OAuthGameResult(
        gameName:    'Steam',
        emoji:       '🎮',
        accountName: personaName,
        rank:        'N/A',
        rankEmoji:   '🎮',
        rawData:     {
          'steamId':    steamId,
          'profileUrl': player['profileurl'],
        },
      );
    } catch (e) {
      return null;
    }
  }
}