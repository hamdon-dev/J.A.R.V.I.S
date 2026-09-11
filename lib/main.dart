import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mysql1/mysql1.dart';
import 'dart:collection';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

// ---------------------------------------------------------------------------
// CONFIG
// ---------------------------------------------------------------------------

const String kKeyStorageKey = 'openai_api_key';
const String kEmailUserKey = 'email_user';
const String kEmailPassKey = 'email_app_password';
const String kRestartWebhookKey = 'fivem_restart_webhook';
const String kBraveApiKeyKey = 'brave_api_key';
const String kPteroApiKeyKey = 'ptero_api_key';
const String kPrefTxUrl = 'pref_txadmin_url';
const String kPrefTxUser = 'pref_txadmin_user';
const String kTxPassKey = 'txadmin_password';
const String kDiscordBotTokenKey = 'discord_bot_token';
const String kPrefDiscordBotChannel = 'pref_discord_bot_channel';
const String kPrefDiscordBotName = 'pref_discord_bot_name';
const String kPrefPteroBase = 'pref_ptero_base';
const String kPrefPteroServer = 'pref_ptero_server_id';
const String kGithubTokenKey = 'github_token';
const String kGithubRepoKey = 'github_repo';
const String kPrefGithubRepo = 'pref_github_repo';

const String kChatEndpoint = 'https://api.openai.com/v1/chat/completions';
const String kSpeechEndpoint = 'https://api.openai.com/v1/audio/speech';
const String kBraveSearchEndpoint = 'https://api.search.brave.com/res/v1/web/search';

const String kDefaultModel = 'gpt-4o-mini';
const String kTtsModel = 'tts-1';
const String kDefaultVoice = 'fable';
const double kDefaultDeviceRate = 0.45;

const String kLdrpBase = 'http://82.38.2.77:30120';

const Set<String> kAllowedPackages = {
  'com.discord',
  'com.whatsapp',
  'com.google.android.apps.messaging',
  'com.samsung.android.messaging',
  'com.google.android.gm',
  'com.microsoft.teams',
};

final List<RegExp> kSensitivePatterns = [
  RegExp(r'\b(otp|one[- ]time)\b', caseSensitive: false),
  RegExp(r'\bverification\b', caseSensitive: false),
  RegExp(r'\bsecurity code\b', caseSensitive: false),
  RegExp(r'\b2fa\b', caseSensitive: false),
  RegExp(r'\bpasscode\b', caseSensitive: false),
  RegExp(r'\b\d{4,8}\b.*\bcode\b', caseSensitive: false),
  RegExp(r'\bcode\b.*\b\d{4,8}\b', caseSensitive: false),
];

const int kMaxHistoryEntries = 28;
const int kMaxToolRounds = 8;
const int kMaxDynamicTools = 40;
const int kMaxVisibleLog = 16;

const String kPrefModel = 'pref_model';
const String kPrefVoice = 'pref_voice';
const String kPrefTtsMode = 'pref_tts_mode';
const String kPrefRate = 'pref_rate';
const String kPrefContinuous = 'pref_continuous';
const String kPrefTools = 'pref_tools';
const String kPrefMemory = 'pref_memory';
const String kPrefDynamicTools = 'pref_dynamic_tools';
const String kPrefSystemPromptExtra = 'pref_system_prompt_extra';
const String kPrefSelfImprove = 'pref_self_improve';
const String kPrefFivemMonitor = 'pref_fivem_monitor';
const String kPrefFivemNotifyJoins = 'pref_fivem_notify_joins';
const String kPrefFivemNotifyRestart = 'pref_fivem_notify_restart';
const String kPrefFivemAutoFix = 'pref_fivem_auto_fix';
const String kPrefFivemPollSeconds = 'pref_fivem_poll_seconds';
const String kPrefPrevPlayers = 'pref_fivem_prev_players';
const String kPrefFingerprint = 'pref_fingerprint';
const String kPrefWelcomeDone = 'pref_welcome_done';
const String kPrefDiscordAutoReply = 'pref_discord_auto_reply';
const String kPrefSyncEnabled = 'pref_sync_enabled';
const String kPrefPcHost = 'pref_pc_host';
const String kPrefPcMac = 'pref_pc_mac';
const String kPrefPcPort = 'pref_pc_port';
const String kPrefPcToken = 'pref_pc_token';
const String kPrefPcWolPort = 'pref_pc_wol_port';
const String kPrefMysqlHost = 'pref_mysql_host';
const String kPrefMysqlPort = 'pref_mysql_port';
const String kPrefMysqlUser = 'pref_mysql_user';
const String kPrefMysqlDb = 'pref_mysql_db';
const String kPrefMysqlOwner = 'pref_mysql_owner';
const String kMysqlPassKey = 'mysql_password';
const String kPrefElevenKey = 'eleven_api_key';
const String kPrefElevenVoice = 'eleven_voice_id';
const String kPrefPrivateMode = 'pref_private_mode';
const String kPrefMorningBrief = 'pref_morning_brief';
const String kPrefIncidentMode = 'pref_incident_mode';
const String kPrefHudTheme = 'pref_hud_theme';
const String kPrefReminders = 'pref_reminders_json';
const String kPrefLastBriefDay = 'pref_last_brief_day';
const String kElevenSpeechUrl =
    'https://api.elevenlabs.io/v1/text-to-speech/';
/// Default community "British butler" style voice id (user can change).
const String kDefaultElevenVoice = 'pNInz6obpgDQGcFmaJgB';


const int kDefaultPcAgentPort = 8765;
const int kDefaultWolPort = 9;

/// Appended to every Discord auto-reply (Discord subtext markdown).
const String kDiscordAutoReplyFooter =
    '\n\n-# This dm was from emps ai assistant, emp is currently unavailable i will assist to my best efforts!';

// Cinematic Iron Man palette
const Color kJarvisCyan = Color(0xFF00D4FF);
const Color kJarvisCyanBright = Color(0xFF6EFFFF);
const Color kJarvisCyanDim = Color(0xFF008B99);
const Color kJarvisBlue = Color(0xFF0091FF);
const Color kJarvisDark = Color(0xFF02060C);
const Color kJarvisPanel = Color(0xFF06101A);
const Color kJarvisPanelLight = Color(0xFF0D1A28);
const Color kJarvisBorder = Color(0x4400E5FF);
const Color kJarvisGlow = Color(0x5500E5FF);
const Color kJarvisAmber = Color(0xFFFFB300);
const Color kJarvisRed = Color(0xFFFF3D3D);
const Color kJarvisGreen = Color(0xFF00E676);

// ---------------------------------------------------------------------------
// SCHEMA SANITIZATION
// ---------------------------------------------------------------------------

Map<String, dynamic> sanitizeToolSchema(dynamic schema) {
  if (schema is! Map) return {'type': 'object', 'properties': {}};
  final map = Map<String, dynamic>.from(schema);
  if (map['type'] != 'object') map['type'] = 'object';
  if (map['properties'] is! Map) map['properties'] = {};
  return map;
}

// ---------------------------------------------------------------------------
// 24/7 FOREGROUND SERVICE
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
void startJarvisCallback() {
  FlutterForegroundTask.setTaskHandler(JarvisTaskHandler());
}

class JarvisTaskHandler extends TaskHandler {
  bool _wasOnline = false;
  Set<String> _prevPlayers = {};
  int _offlineStreak = 0;
  bool _autoFix = false;
  bool _notifyJoins = true;
  bool _notifyRestart = true;
  String? _webhook;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final prefs = await SharedPreferences.getInstance();
    _autoFix = prefs.getBool(kPrefFivemAutoFix) ?? false;
    _notifyJoins = prefs.getBool(kPrefFivemNotifyJoins) ?? true;
    _notifyRestart = prefs.getBool(kPrefFivemNotifyRestart) ?? true;
    _prevPlayers = (prefs.getStringList(kPrefPrevPlayers) ?? []).toSet();
    _webhook = prefs.getString('fivem_restart_webhook_plain');
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    try {
      final status = await _fetchStatus();
      final online = status['online'] == true;
      final players = <String>{};
      if (status['players'] is List) {
        for (final p in status['players']) {
          players.add(p.toString());
        }
      }
      final count = players.length;

      await FlutterForegroundTask.updateService(
        notificationTitle: online ? 'JARVIS · LDRP Online' : 'JARVIS · LDRP OFFLINE',
        notificationText: online
            ? '$count player${count == 1 ? '' : 's'} online'
            : 'Server unreachable',
      );

      if (!online && _wasOnline) {
        _offlineStreak = 1;
        if (_notifyRestart) {
          FlutterForegroundTask.sendDataToMain({
            'type': 'fivem_event',
            'event': 'offline',
            'message': 'LDRP server appears to be offline.',
          });
        }
        if (_autoFix && _webhook != null && _webhook!.isNotEmpty) {
          await _callWebhook(_webhook!);
        }
      } else if (!online) {
        _offlineStreak++;
        if (_autoFix &&
            _offlineStreak == 3 &&
            _webhook != null &&
            _webhook!.isNotEmpty) {
          await _callWebhook(_webhook!);
        }
      }

      if (online && !_wasOnline && _notifyRestart) {
        FlutterForegroundTask.sendDataToMain({
          'type': 'fivem_event',
          'event': 'restart',
          'message': 'LDRP server is back online. It may have just restarted.',
        });
      }

      if (online && _notifyJoins && _prevPlayers.isNotEmpty) {
        final newcomers = players.difference(_prevPlayers);
        if (newcomers.isNotEmpty) {
          final names = newcomers.take(4).join(', ');
          final extra =
              newcomers.length > 4 ? ' and ${newcomers.length - 4} more' : '';
          FlutterForegroundTask.sendDataToMain({
            'type': 'fivem_event',
            'event': 'join',
            'message': 'Player joined LDRP: $names$extra.',
          });
        }
      }

      _wasOnline = online;
      if (online) {
        _prevPlayers = players;
        _offlineStreak = 0;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(kPrefPrevPlayers, players.toList());
      }
    } catch (_) {}
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onReceiveData(Object data) {}

  Future<Map<String, dynamic>> _fetchStatus() async {
    try {
      final resp = await http
          .get(Uri.parse('$kLdrpBase/players.json'))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return {'online': false};
      final list = jsonDecode(resp.body) as List<dynamic>;
      final names = <String>[];
      for (final p in list) {
        if (p is Map) {
          final n = p['name']?.toString();
          if (n != null && n.isNotEmpty) names.add(n);
        }
      }
      return {'online': true, 'players': names, 'player_count': names.length};
    } catch (_) {
      return {'online': false};
    }
  }

  Future<void> _callWebhook(String url) async {
    try {
      await http.post(Uri.parse(url)).timeout(const Duration(seconds: 10));
      FlutterForegroundTask.sendDataToMain({
        'type': 'fivem_event',
        'event': 'restart_attempt',
        'message': 'I sent a restart command to the server.',
      });
    } catch (_) {
      FlutterForegroundTask.sendDataToMain({
        'type': 'fivem_event',
        'event': 'restart_failed',
        'message': 'Failed to reach the restart webhook.',
      });
    }
  }
}

// ---------------------------------------------------------------------------

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: kJarvisDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  FlutterForegroundTask.initCommunicationPort();
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J.A.R.V.I.S',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kJarvisDark,
        primaryColor: kJarvisCyan,
        colorScheme: const ColorScheme.dark(
          primary: kJarvisCyan,
          secondary: kJarvisBlue,
          surface: kJarvisPanel,
        ),
        fontFamily: 'Roboto',
        splashFactory: InkRipple.splashFactory,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, letterSpacing: 0.25),
          bodyMedium: TextStyle(color: Colors.white70, letterSpacing: 0.15),
        ),
      ),
      home: const JarvisHome(),
    );
  }
}

// ---------------------------------------------------------------------------
// TOOL SCHEMAS
// ---------------------------------------------------------------------------

const List<Map<String, dynamic>> kBuiltinToolSchema = [
  {
    'type': 'function',
    'function': {
      'name': 'get_current_time',
      'description': 'Get the current local date and time.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'set_alarm',
      'description': 'Set an alarm on the device.',
      'parameters': {
        'type': 'object',
        'properties': {
          'hour': {'type': 'integer'},
          'minute': {'type': 'integer'},
          'label': {'type': 'string'},
        },
        'required': ['hour', 'minute'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'set_timer',
      'description': 'Start a countdown timer.',
      'parameters': {
        'type': 'object',
        'properties': {
          'seconds': {'type': 'integer'},
          'label': {'type': 'string'},
        },
        'required': ['seconds'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'web_search',
      'description':
          'Search the web for current information and return the top results with titles, snippets and URLs.',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'description': 'The search query.'},
        },
        'required': ['query'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'ldrp_server_status',
      'description': 'Get live LDRP FiveM status and player list.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'start_fivem_monitor',
      'description':
          'Start 24/7 background monitoring of the FiveM server. Continues even when the app is closed.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'stop_fivem_monitor',
      'description': 'Stop the 24/7 FiveM monitor.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'get_fivem_health',
      'description': 'Detailed health check and whether 24/7 monitor is running.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'attempt_fivem_restart',
      'description': 'Call the configured restart webhook.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'remember',
      'description': 'Store a durable fact about the user.',
      'parameters': {
        'type': 'object',
        'properties': {'fact': {'type': 'string'}},
        'required': ['fact'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'forget_all',
      'description': 'Erase every stored fact.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'summarize_emails',
      'description': 'Summarise recent emails (needs credentials in Settings).',
      'parameters': {
        'type': 'object',
        'properties': {'max_count': {'type': 'integer'}},
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'add_capability',
      'description': 'Permanently add a new tool.',
      'parameters': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'description': {'type': 'string'},
          'parameters_schema': {'type': 'object'},
          'implementation_hint': {'type': 'string'},
        },
        'required': ['name', 'description'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'list_capabilities',
      'description': 'List all tools.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'remove_capability',
      'description': 'Remove a dynamic capability.',
      'parameters': {
        'type': 'object',
        'properties': {'name': {'type': 'string'}},
        'required': ['name'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'update_own_prompt',
      'description': 'Permanently update own system prompt.',
      'parameters': {
        'type': 'object',
        'properties': {
          'extra_instruction': {'type': 'string'},
          'replace': {'type': 'boolean'},
        },
        'required': ['extra_instruction'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'self_improve_suggestion',
      'description': 'Propose a new useful capability.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'enable_discord_auto_reply',
      'description':
          'Turn on unavailable mode: automatically reply to incoming Discord DMs on behalf of the user. Use when the user says they are unavailable, away, or wants you to handle Discord messages.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'disable_discord_auto_reply',
      'description':
          'Turn off Discord auto-reply / unavailable mode. Use when the user says they are back or available.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'get_discord_auto_reply_status',
      'description': 'Check whether Discord DM auto-reply (unavailable mode) is currently active.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },




  {
    'type': 'function',
    'function': {
      'name': 'discord_bot_test',
      'description': 'Verify the Discord bot token and return the bot username/id.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'discord_bot_send',
      'description': 'Send a message as the J.A.R.V.I.S Discord bot to a channel. Uses default channel from Settings if channel_id omitted.',
      'parameters': {
        'type': 'object',
        'properties': {
          'content': {'type': 'string'},
          'channel_id': {'type': 'string'},
        },
        'required': ['content'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'discord_bot_dm',
      'description': 'Send a direct message as the Discord bot to a user ID (snowflake).',
      'parameters': {
        'type': 'object',
        'properties': {
          'user_id': {'type': 'string'},
          'content': {'type': 'string'},
        },
        'required': ['user_id', 'content'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'tx_login_test',
      'description': 'Test login to txAdmin panel with configured credentials.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'tx_resource',
      'description': 'Control a FiveM resource via txAdmin: restart, start, stop, or ensure.',
      'parameters': {
        'type': 'object',
        'properties': {
          'action': {'type': 'string', 'description': 'restart | start | stop | ensure'},
          'resource': {'type': 'string', 'description': 'Resource name e.g. qb-core'},
        },
        'required': ['action', 'resource'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'tx_server',
      'description': 'Control FXServer via txAdmin: restart, stop, or start the whole server.',
      'parameters': {
        'type': 'object',
        'properties': {
          'action': {'type': 'string', 'description': 'restart | stop | start'},
        },
        'required': ['action'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'tx_announce',
      'description': 'Send a txAdmin announcement to all players.',
      'parameters': {
        'type': 'object',
        'properties': {
          'message': {'type': 'string'},
        },
        'required': ['message'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'tx_refresh',
      'description': 'Run refresh on FXServer resources via txAdmin.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'ptero_status',
      'description': 'Get Pterodactyl game server power state and resource usage (CPU, memory, disk).',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'ptero_power',
      'description': 'Send power signal to the configured Pterodactyl server: start, stop, restart, or kill.',
      'parameters': {
        'type': 'object',
        'properties': {
          'signal': {
            'type': 'string',
            'description': 'start | stop | restart | kill',
          },
        },
        'required': ['signal'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'ptero_command',
      'description': 'Send a console command to the Pterodactyl server (e.g. say Hello, ensure mapmanager).',
      'parameters': {
        'type': 'object',
        'properties': {
          'command': {'type': 'string'},
        },
        'required': ['command'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'ptero_backup',
      'description': 'Create a backup of the Pterodactyl server.',
      'parameters': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'ptero_list_backups',
      'description': 'List backups for the configured Pterodactyl server.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'mind_status',
      'description': 'Check MySQL long-term mind connection and fact counts.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'mind_search',
      'description': 'Search long-term mind (MySQL + local) for facts.',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string'},
          'limit': {'type': 'number'},
        },
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'mind_store',
      'description': 'Store a durable fact in local + MySQL mind.',
      'parameters': {
        'type': 'object',
        'properties': {
          'fact': {'type': 'string'},
          'category': {'type': 'string'},
          'importance': {'type': 'number'},
        },
        'required': ['fact'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'mind_sync_pull',
      'description': 'Pull facts from MySQL mind into local memory.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'mind_sync_push',
      'description': 'Push local memory facts into MySQL mind.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'mind_ensure_schema',
      'description': 'Create mind tables on the MySQL server if missing.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'set_reminder',
      'description': 'Set a spoken reminder after a number of minutes.',
      'parameters': {
        'type': 'object',
        'properties': {
          'text': {'type': 'string'},
          'minutes': {'type': 'number'},
        },
        'required': ['text', 'minutes'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'list_reminders',
      'description': 'List pending reminders.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'cancel_reminders',
      'description': 'Cancel all pending reminders.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'deliver_briefing',
      'description': 'Deliver a full systems and weather briefing now.',
      'parameters': {'type': 'object', 'properties': {}},
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'set_private_mode',
      'description': 'Enable or disable private mode (reduced logging).',
      'parameters': {
        'type': 'object',
        'properties': {
          'enabled': {'type': 'boolean'},
        },
        'required': ['enabled'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'set_incident_mode',
      'description': 'Enable or disable incident mode for crisis prioritisation.',
      'parameters': {
        'type': 'object',
        'properties': {
          'enabled': {'type': 'boolean'},
        },
        'required': ['enabled'],
      },
    }
  },
  {
    'type': 'function',
    'function': {
      'name': 'set_hud_theme',
      'description': 'Set HUD theme: classic, mark1, or stark.',
      'parameters': {
        'type': 'object',
        'properties': {
          'theme': {'type': 'string'},
        },
        'required': ['theme'],
      },
    }
  },
];

// ---------------------------------------------------------------------------
// SPEECH QUEUE + LOG
// ---------------------------------------------------------------------------

enum SpeechPriority { notification, reply, system, fivem }

class _Utterance {
  final String text;
  final SpeechPriority priority;
  const _Utterance(this.text, this.priority);
}

class _LogEntry {
  final String role; // user | assistant | system | tool
  final String text;
  final DateTime at;
  const _LogEntry(this.role, this.text, this.at);
}

// ---------------------------------------------------------------------------
// HUD CORNER BRACKETS
// ---------------------------------------------------------------------------

class HudCornersPainter extends CustomPainter {
  final Color color;
  final double progress;

  HudCornersPainter({required this.color, this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.65 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square;

    const len = 28.0;
    const inset = 8.0;
    final w = size.width;
    final h = size.height;

    void corner(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y + dy * len), Offset(x, y), paint);
      canvas.drawLine(Offset(x, y), Offset(x + dx * len, y), paint);
      final p2 = Paint()
        ..color = color.withOpacity(0.25 * progress)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(x + dx * 3, y + dy * 3),
        Offset(x + dx * 3, y + dy * (len - 6)),
        p2,
      );
    }

    corner(inset, inset, 1, 1);
    corner(w - inset, inset, -1, 1);
    corner(inset, h - inset, 1, -1);
    corner(w - inset, h - inset, -1, -1);

    final mid = Paint()
      ..color = color.withOpacity(0.35 * progress)
      ..strokeWidth = 1.1;
    final mx = w / 2;
    final my = h / 2;
    canvas.drawLine(Offset(mx - 16, inset), Offset(mx + 16, inset), mid);
    canvas.drawLine(Offset(mx - 16, h - inset), Offset(mx + 16, h - inset), mid);
    canvas.drawLine(Offset(inset, my - 12), Offset(inset, my + 12), mid);
    canvas.drawLine(Offset(w - inset, my - 12), Offset(w - inset, my + 12), mid);
  }

  @override
  bool shouldRepaint(covariant HudCornersPainter old) =>
      old.color != color || old.progress != progress;
}

class HudBackgroundPainter extends CustomPainter {
  final double scanY;
  final double time;

  HudBackgroundPainter({required this.scanY, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.42;

    final vig = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0x00000000), const Color(0xAA01060C)],
        stops: const [0.35, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vig);

    final grid = Paint()
      ..color = kJarvisCyan.withOpacity(0.045)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    for (double x = 0; x < w; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (double y = 0; y < h; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    final beam = Paint()
      ..color = kJarvisCyan.withOpacity(0.06)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, h * 0.15), Offset(w, h * 0.55), beam);
    canvas.drawLine(Offset(w, h * 0.2), Offset(0, h * 0.7), beam);

    final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0;
    for (int i = 1; i <= 6; i++) {
      final r = 40.0 + i * 28.0 + (time * 8) % 12;
      ring.color = kJarvisCyan.withOpacity(0.035 + (i % 2) * 0.02);
      canvas.drawCircle(Offset(cx, cy), r, ring);
    }

    _drawSchematicPanel(canvas, Rect.fromLTWH(8, h * 0.18, w * 0.22, h * 0.28), time);
    _drawSchematicPanel(
        canvas, Rect.fromLTWH(w * 0.72, h * 0.22, w * 0.24, h * 0.26), time + 1.2);
    _drawHexCluster(canvas, Offset(w * 0.12, h * 0.72), 10);
    _drawHexCluster(canvas, Offset(w * 0.88, h * 0.65), 9);

    final scan = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          kJarvisCyan.withOpacity(0.0),
          kJarvisCyan.withOpacity(0.12),
          kJarvisCyan.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 18, w, 36));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 18, w, 36), scan);

    final bar = Paint()..color = kJarvisCyan.withOpacity(0.08);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 1.5), bar);
    canvas.drawRect(Rect.fromLTWH(0, h - 1.5, w, 1.5), bar);
  }

  void _drawSchematicPanel(Canvas canvas, Rect r, double t) {
    final border = Paint()
      ..color = kJarvisCyan.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), border);
    final line = Paint()
      ..color = kJarvisCyan.withOpacity(0.08)
      ..strokeWidth = 0.7;
    for (int i = 1; i < 6; i++) {
      final y = r.top + r.height * (i / 6);
      canvas.drawLine(Offset(r.left + 4, y), Offset(r.right - 4, y), line);
    }
    final path = Path();
    final mid = r.center.dy;
    path.moveTo(r.left + 6, mid);
    for (double x = r.left + 6; x < r.right - 6; x += 4) {
      final n = (x * 0.08 + t * 3) % 6.28;
      path.lineTo(x, mid + (n < 3.14 ? 1 : -1) * (4 + (x % 11)));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = kJarvisCyan.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawHexCluster(Canvas canvas, Offset c, double s) {
    final p = Paint()
      ..color = kJarvisCyan.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    for (int i = 0; i < 3; i++) {
      final o = Offset(c.dx + i * s * 1.4, c.dy + (i % 2) * s * 0.8);
      _hex(canvas, o, s * (0.7 + 0.1 * i), p);
    }
  }

  void _hex(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = (i * 60 - 30) * math.pi / 180.0;
      final x = c.dx + r * math.cos(a);
      final y = c.dy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant HudBackgroundPainter old) =>
      old.scanY != scanY || old.time != time;
}

class WaveformPainter extends CustomPainter {
  final double progress;
  final double energy; // 0..1 approximate activity
  final Color color;
  final int bars;

  WaveformPainter({
    required this.progress,
    required this.energy,
    required this.color,
    this.bars = 28,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;

    final midY = size.height / 2;
    final gap = size.width / bars;

    for (int i = 0; i < bars; i++) {
      final t = progress * 2 * math.pi + i * 0.45;
      final base = 0.18 + 0.55 * energy;
      final h = size.height *
          (base * (0.35 + 0.65 * ((math.sin(t) + 1) / 2))) *
          (0.55 + 0.45 * ((math.sin(t * 1.7 + i) + 1) / 2));
      final x = gap * i + gap / 2;
      canvas.drawLine(Offset(x, midY - h / 2), Offset(x, midY + h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter old) =>
      old.progress != progress || old.energy != energy || old.color != color;
}

// ---------------------------------------------------------------------------
// ARC REACTOR — orbital particles + energy arcs
// ---------------------------------------------------------------------------

class ArcReactorPainter extends CustomPainter {
  final double progress;
  final bool active;
  final bool listening;
  final bool speaking;
  final bool processing;
  final Color coreColor;

  ArcReactorPainter({
    required this.progress,
    required this.active,
    required this.listening,
    required this.speaking,
    required this.processing,
    required this.coreColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          coreColor.withOpacity(listening ? 0.35 : 0.22),
          coreColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: radius * 1.15));
    canvas.drawCircle(c, radius * 1.1, glow);

    for (int i = 0; i < 5; i++) {
      final rr = radius * (0.42 + i * 0.11);
      final spin = progress * math.pi * 2 * (i.isEven ? 1 : -1) * (0.3 + i * 0.05);
      final ring = Paint()
        ..color = coreColor.withOpacity(0.18 + i * 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 2.2 : 1.1;
      canvas.drawCircle(c, rr, ring);

      final tick = Paint()
        ..color = coreColor.withOpacity(0.35)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      for (int ti = 0; ti < 12; ti++) {
        final a = spin + ti * (math.pi * 2 / 12);
        final i0 = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
        final i1 = Offset(
          c.dx + (rr - 4) * math.cos(a),
          c.dy + (rr - 4) * math.sin(a),
        );
        canvas.drawLine(i0, i1, tick);
      }
    }

    final arcPaint = Paint()
      ..color = coreColor.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final sweep = listening ? 2.2 : (speaking ? 1.6 : 1.1);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: radius * 0.88),
      progress * math.pi * 2,
      sweep,
      false,
      arcPaint,
    );
    final arc2 = Paint()
      ..color = coreColor.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: radius * 0.78),
      -progress * math.pi * 2 * 0.7,
      0.9,
      false,
      arc2,
    );

    final coreR = radius * (processing ? 0.28 : 0.24);
    final core = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.95),
          coreColor,
          coreColor.withOpacity(0.3),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: coreR));
    canvas.drawCircle(c, coreR, core);

    final detail = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(c, coreR * 0.55, detail);
  }

  @override
  bool shouldRepaint(covariant ArcReactorPainter old) =>
      old.progress != progress ||
      old.active != active ||
      old.listening != listening ||
      old.speaking != speaking ||
      old.processing != processing ||
      old.coreColor != coreColor;
}

class HoloPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderOpacity;
  final bool glow;
  final bool blur;

  const HoloPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderOpacity = 0.32,
    this.glow = true,
    this.blur = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kJarvisPanel.withOpacity(blur ? 0.52 : 0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kJarvisCyan.withOpacity(borderOpacity), width: 1),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: kJarvisCyan.withOpacity(0.06),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (!blur) return content;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: content,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STATUS CHIP
// ---------------------------------------------------------------------------

class JarvisChip extends StatelessWidget {
  final String label;
  final Color colour;
  final bool active;
  final VoidCallback? onTap;

  const JarvisChip({
    super.key,
    required this.label,
    required this.colour,
    this.active = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: colour.withOpacity(active ? 0.12 : 0.04),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: colour.withOpacity(active ? 0.5 : 0.18)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: colour.withOpacity(active ? 0.95 : 0.4),
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.15,
        ),
      ),
    );
    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }
}

// ---------------------------------------------------------------------------
// THINKING DOTS
// ---------------------------------------------------------------------------

class ThinkingDots extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const ThinkingDots({super.key, required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (controller.value + i * 0.22) % 1.0;
            final o = 0.25 + 0.75 * ((math.sin(t * math.pi * 2) + 1) / 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(o),
              ),
            );
          }),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// MAIN HOME
// ---------------------------------------------------------------------------

class JarvisHome extends StatefulWidget {
  const JarvisHome({super.key});
  @override
  State<JarvisHome> createState() => _JarvisHomeState();
}

class _JarvisHomeState extends State<JarvisHome> with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  SharedPreferences? _prefs;
  final Queue<_Utterance> _speechQueue = Queue<_Utterance>();
  bool _draining = false;

  final List<Map<String, dynamic>> _history = [];
  final List<String> _memory = [];
  List<Map<String, dynamic>> _dynamicTools = [];
  final List<_LogEntry> _uiLog = [];

  late AnimationController _pulse;
  late AnimationController _reactor;
  late AnimationController _scan;
  late AnimationController _fadeIn;
  late AnimationController _wave;

  String? _apiKey;
  bool _booted = false;
  bool _speechReady = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  bool _notificationsEnabled = false;
  bool _continuous = false;
  bool _toolsEnabled = true;
  bool _selfImprove = true;
  bool _discordAutoReply = false;
  bool _syncEnabled = false;
  Timer? _syncTimer;
  String _pcSyncHost = '';
  int _pcSyncPort = kDefaultPcAgentPort;
  /// Prevents double-replies when Discord posts multiple notification updates.
  final Map<String, DateTime> _discordRecentReplies = {};

  bool _fivemMonitor = false;
  bool _fivemNotifyJoins = true;
  bool _fivemNotifyRestart = true;
  bool _fivemAutoFix = false;
  int _fivemPollSeconds = 45;
  bool _serviceRunning = false;

  String _model = kDefaultModel;
  String _voice = kDefaultVoice;
  String _ttsMode = 'openai'; // openai | device | elevenlabs
  String? _elevenKey;
  String _elevenVoice = kDefaultElevenVoice;
  bool _privateMode = false;
  bool _morningBrief = true;
  bool _incidentMode = false;
  String _hudTheme = 'classic'; // classic | mark1 | stark
  List<Map<String, dynamic>> _reminders = [];
  Timer? _reminderTimer;
  Timer? _briefTimer;
  String _mysqlHost = '';
  int _mysqlPort = 3306;
  String _mysqlUser = '';
  String _mysqlDb = 'jarvis_mind';
  String _mysqlOwner = 'default';
  String? _mysqlPass;
  bool _mindOnline = false;
  String _pteroBase = '';
  String _pteroServerId = '';
  String? _pteroApiKey;
  String _txUrl = 'http://82.38.2.77:40120';
  String _txUser = '';
  String? _txPass;
  String? _txCookie;
  String? _txCsrf;
  DateTime? _txAuthAt;
  String? _discordBotToken;
  String _discordBotChannel = '';
  String _discordBotName = 'J.A.R.V.I.S';
  double _deviceRate = kDefaultDeviceRate;
  String _systemPromptExtra = '';

  String _status = 'SYSTEM READY';
  String _lastWords = '';
  String _toolNote = '';
  double _voiceEnergy = 0.25; // for waveform

  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  final ScrollController _logScroll = ScrollController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _fingerprintEnabled = false;
  bool _unlocked = false;
  bool _authChecked = false;

  StreamSubscription? _notificationSubscription;
  Timer? _selfImproveTimer;
  Timer? _clockTimer;
  Timer? _energyDecay;
  String _clock = '';
  String _dateLine = '';

  String? _lastHandledPhrase;
  DateTime _lastHandledAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _reactor =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
          ..repeat();
    _scan =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 5200))
          ..repeat();
    _fadeIn =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _wave =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
          ..repeat();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _energyDecay = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!_isListening && !_isSpeaking) return;
      if (mounted) {
        setState(() => _voiceEnergy = (_voiceEnergy * 0.92).clamp(0.12, 1.0));
      }
    });
    _bootstrap();
  }

  void _updateClock() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    if (mounted) {
      setState(() {
        _clock = '$h:$m:$s';
        _dateLine =
            '${days[now.weekday - 1]}  ${now.day} ${months[now.month - 1]}';
      });
    }
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map && data['type'] == 'fivem_event') {
      final msg = data['message']?.toString() ?? '';
      if (msg.isNotEmpty) {
        _addLog('system', msg);
        _enqueueSpeech(msg, SpeechPriority.fivem);
      }
    }
  }

  void _addLog(String role, String text) {
    if (_privateMode && role != 'system') return;
    if (text.trim().isEmpty) return;
    _uiLog.add(_LogEntry(role, text.trim(), DateTime.now()));
    while (_uiLog.length > kMaxVisibleLog) {
      _uiLog.removeAt(0);
    }
    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScroll.hasClients) {
          _logScroll.animateTo(
            _logScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _bootstrap() async {
    _prefs = await SharedPreferences.getInstance();
    _apiKey = await _storage.read(key: kKeyStorageKey);
    _loadSettings();
    _startSyncLoop();
    await _loadDynamicTools();
    _initForegroundTask();

    await Permission.microphone.request();
    await Permission.notification.request();
    await _initTts();
    await _initSpeech();
    await _checkNotificationPermission();

    final isRunning = await FlutterForegroundTask.isRunningService;
    _serviceRunning = isRunning;
    if (_fivemMonitor && !isRunning) {
      await _startForegroundService();
    }

    if (_continuous && _selfImprove) _startSelfImproveLoop();

    if (_fingerprintEnabled) {
      final ok = await _authenticate();
      _unlocked = ok;
    } else {
      _unlocked = true;
    }
    _authChecked = true;

    if (!mounted) return;
    setState(() => _booted = true);
    _fadeIn.forward();

    final welcomed = _prefs?.getBool(kPrefWelcomeDone) ?? false;
    if (!welcomed && _apiKey != null && _apiKey!.isNotEmpty && _unlocked) {
      await _prefs?.setBool(kPrefWelcomeDone, true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        final hour = DateTime.now().hour;
        final greet = hour < 12
            ? 'Good morning, sir. '
            : (hour < 18 ? 'Good afternoon, sir. ' : 'Good evening, sir. ');
        _enqueueSpeech(
          '${greet}I have indeed been uploaded. We\'re online and ready. At your service.',
          SpeechPriority.system,
        );
        _addLog('system', 'All systems nominal. Awaiting input.');
      _scheduleMorningBrief();
      _startReminderLoop();
      _mindAutoInit();
      });
    }
  }

  String? _authError;

  Future<bool> _authenticate() async {
    _authError = null;
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canBio = await _localAuth.canCheckBiometrics;
      if (!supported && !canBio) {
        // No biometrics / no lock screen — do not trap the user
        return true;
      }

      final types = await _localAuth.getAvailableBiometrics();
      // Prefer biometrics when enrolled; always allow device PIN/pattern/password fallback
      final ok = await _localAuth.authenticate(
        localizedReason: types.isEmpty
            ? 'Enter device PIN, pattern or password to unlock J.A.R.V.I.S'
            : 'Authenticate to access the system',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
      return ok;
    } on PlatformException catch (e) {
      // Common: NotAvailable, NotEnrolled, LockedOut, PermanentlyLockedOut, PasscodeNotSet
      final code = e.code.toLowerCase();
      if (code.contains('notavailable') ||
          code.contains('not_available') ||
          code.contains('notenrolled') ||
          code.contains('not_enrolled') ||
          code.contains('passcodenotset') ||
          code.contains('passcode_not_set')) {
        // Nothing to authenticate with — allow entry so user is not locked out
        _authError = 'Biometrics unavailable on this device. Unlocking.';
        return true;
      }
      if (code.contains('lockedout') || code.contains('locked_out')) {
        _authError = 'Too many attempts. Wait a moment, then try PIN or biometrics again.';
        return false;
      }
      _authError = e.message ?? e.code;
      return false;
    } catch (e) {
      _authError = e.toString();
      return false;
    }
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'jarvis_fivem_monitor',
        channelName: 'JARVIS LDRP Monitor',
        channelDescription: '24/7 monitoring of the LDRP FiveM server',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions:
          const IOSNotificationOptions(showNotification: false, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
            (_fivemPollSeconds.clamp(20, 120)) * 1000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> _startForegroundService() async {
    final result = await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'JARVIS · Watching LDRP',
      notificationText: 'Monitor active',
      callback: startJarvisCallback,
    );
    _serviceRunning = result is ServiceRequestSuccess;
    _fivemMonitor = true;
    await _prefs?.setBool(kPrefFivemMonitor, true);
    if (mounted) setState(() {});
    if (_serviceRunning) {
      _enqueueSpeech(
        'Twenty four seven LDRP monitor is now active. It will keep running even if you close the app.',
        SpeechPriority.fivem,
      );
      _addLog('system', '24/7 LDRP monitor activated.');
    }
  }

  Future<void> _stopForegroundService() async {
    await FlutterForegroundTask.stopService();
    _serviceRunning = false;
    _fivemMonitor = false;
    await _prefs?.setBool(kPrefFivemMonitor, false);
    if (mounted) setState(() {});
    _enqueueSpeech('LDRP monitor offline, sir.', SpeechPriority.fivem);
    _addLog('system', 'LDRP monitor offline, sir.');
  }

  Future<void> _loadSettings() async {
    final p = _prefs;
    if (p == null) return;
    _model = p.getString(kPrefModel) ?? kDefaultModel;
    _voice = p.getString(kPrefVoice) ?? kDefaultVoice;
    _ttsMode = p.getString(kPrefTtsMode) ?? 'openai';
    _deviceRate = p.getDouble(kPrefRate) ?? kDefaultDeviceRate;
    _continuous = p.getBool(kPrefContinuous) ?? false;
    _toolsEnabled = p.getBool(kPrefTools) ?? true;
    _selfImprove = p.getBool(kPrefSelfImprove) ?? true;
    _systemPromptExtra = p.getString(kPrefSystemPromptExtra) ?? '';
    _fivemMonitor = p.getBool(kPrefFivemMonitor) ?? false;
    _fivemNotifyJoins = p.getBool(kPrefFivemNotifyJoins) ?? true;
    _fivemNotifyRestart = p.getBool(kPrefFivemNotifyRestart) ?? true;
    _fivemAutoFix = p.getBool(kPrefFivemAutoFix) ?? false;
    _fivemPollSeconds = p.getInt(kPrefFivemPollSeconds) ?? 45;
    _fingerprintEnabled = p.getBool(kPrefFingerprint) ?? false;
    _privateMode = p.getBool(kPrefPrivateMode) ?? false;
    _morningBrief = p.getBool(kPrefMorningBrief) ?? true;
    _incidentMode = p.getBool(kPrefIncidentMode) ?? false;
    _hudTheme = p.getString(kPrefHudTheme) ?? 'classic';
    _elevenVoice = p.getString(kPrefElevenVoice) ?? kDefaultElevenVoice;
    _elevenKey = await _storage.read(key: kPrefElevenKey);
    _mysqlHost = p.getString(kPrefMysqlHost) ?? '';
    _mysqlPort = p.getInt(kPrefMysqlPort) ?? 3306;
    _mysqlUser = p.getString(kPrefMysqlUser) ?? '';
    _mysqlDb = p.getString(kPrefMysqlDb) ?? 'jarvis_mind';
    _mysqlOwner = p.getString(kPrefMysqlOwner) ?? 'default';
    _mysqlPass = await _storage.read(key: kMysqlPassKey);
    _pteroBase = p.getString(kPrefPteroBase) ?? '';
    _pteroServerId = p.getString(kPrefPteroServer) ?? '';
    _pteroApiKey = await _storage.read(key: kPteroApiKeyKey);
    _txUrl = p.getString(kPrefTxUrl) ?? 'http://82.38.2.77:40120';
    _txUser = p.getString(kPrefTxUser) ?? '';
    _txPass = await _storage.read(key: kTxPassKey);
    _discordBotToken = await _storage.read(key: kDiscordBotTokenKey);
    _discordBotChannel = p.getString(kPrefDiscordBotChannel) ?? '';
    _discordBotName = p.getString(kPrefDiscordBotName) ?? 'J.A.R.V.I.S';
    try {
      final raw = p.getString(kPrefReminders);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw);
        if (list is List) {
          _reminders = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (_) {}

    _discordAutoReply = p.getBool(kPrefDiscordAutoReply) ?? false;
    if (_discordAutoReply) {
      // Restore listener after restart
      Future.microtask(() async {
        await _checkNotificationPermission();
        if (_notificationsEnabled) _startNotificationListener();
      });
    }
    _syncEnabled = p.getBool(kPrefSyncEnabled) ?? false;
    _pcSyncHost = p.getString(kPrefPcHost) ?? '';
    _pcSyncPort = p.getInt(kPrefPcPort) ?? kDefaultPcAgentPort;
    _memory
      ..clear()
      ..addAll(p.getStringList(kPrefMemory) ?? []);
  }


  String get _syncBase {
    final host = _pcSyncHost.trim();
    if (host.isEmpty) return '';
    return 'http://$host:$_pcSyncPort';
  }

  void _startSyncLoop() {
    _syncTimer?.cancel();
    if (!_syncEnabled || _pcSyncHost.trim().isEmpty) return;
    _syncTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _syncPullAndPush();
    });
    _syncPullAndPush();
  }

  Future<void> _syncPullAndPush() async {
    final base = _syncBase;
    if (!_syncEnabled || base.isEmpty) return;
    try {
      // Pull
      final getRes = await http
          .get(Uri.parse('$base/api/sync'))
          .timeout(const Duration(seconds: 6));
      if (getRes.statusCode == 200) {
        final data = jsonDecode(getRes.body);
        if (data is Map) {
          final remoteMem = data['memory'];
          if (remoteMem is List) {
            for (final f in remoteMem) {
              final s = f.toString().trim();
              if (s.isNotEmpty && !_memory.contains(s)) {
                _memory.add(s);
              }
            }
            while (_memory.length > 80) {
              _memory.removeAt(0);
            }
            await _saveMemory();
          }
        }
      }
      // Push
      final body = jsonEncode({
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'updated_by': 'phone',
        'memory': _memory,
        'messages': _history
            .where((m) =>
                (m['role'] == 'user' || m['role'] == 'assistant') &&
                m['content'] is String)
            .toList()
            .reversed
            .take(30)
            .toList()
            .reversed
            .map((m) {
              final c = m['content'] as String;
              return {
                'role': m['role'],
                'content': c.length > 2000 ? c.substring(0, 2000) : c,
                'ts': DateTime.now().millisecondsSinceEpoch,
              };
            })
            .toList(),
        'status': {
          'unavailable': _discordAutoReply,
          'note': _discordAutoReply ? 'away' : '',
        },
      });
      await http
          .post(
            Uri.parse('$base/api/sync'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      // PC offline or wrong IP — silent
    }
  }

  Future<void> _saveMemory() async =>
      await _prefs?.setStringList(kPrefMemory, _memory);
  Future<void> _saveDynamicTools() async =>
      await _prefs?.setString(kPrefDynamicTools, jsonEncode(_dynamicTools));
  Future<void> _saveSystemPromptExtra() async =>
      await _prefs?.setString(kPrefSystemPromptExtra, _systemPromptExtra);

  Future<void> _loadDynamicTools() async {
    final raw = _prefs?.getString(kPrefDynamicTools);
    if (raw == null || raw.isEmpty) {
      _dynamicTools = [];
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _dynamicTools = decoded.whereType<Map>().map((e) {
          final tool = Map<String, dynamic>.from(e);
          tool['parameters_schema'] = sanitizeToolSchema(tool['parameters_schema']);
          return tool;
        }).toList();
      }
    } catch (_) {
      _dynamicTools = [];
    }
  }

  Future<void> _saveApiKey(String key) async {
    await _storage.write(key: kKeyStorageKey, value: key);
    if (mounted) setState(() => _apiKey = key);
  }

  Future<void> _clearApiKey() async {
    await _storage.delete(key: kKeyStorageKey);
    if (mounted) setState(() => _apiKey = null);
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-GB');
    await _tts.setSpeechRate(_deviceRate);
    await _tts.setPitch(0.85);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  void _enqueueSpeech(String text, SpeechPriority priority) {
    if (text.trim().isEmpty) return;
    if (priority == SpeechPriority.reply ||
        priority == SpeechPriority.system ||
        priority == SpeechPriority.fivem) {
      final pending = _speechQueue.toList();
      final insertAt = pending.lastIndexWhere((u) =>
              u.priority == SpeechPriority.reply ||
              u.priority == SpeechPriority.system ||
              u.priority == SpeechPriority.fivem) +
          1;
      pending.insert(insertAt, _Utterance(text, priority));
      _speechQueue
        ..clear()
        ..addAll(pending);
    } else {
      _speechQueue.add(_Utterance(text, priority));
    }
    _drainSpeechQueue();
  }

  Future<void> _drainSpeechQueue() async {
    if (_draining) return;
    _draining = true;
    while (_speechQueue.isNotEmpty) {
      final u = _speechQueue.removeFirst();
      if (mounted) {
        setState(() {
          _isSpeaking = true;
          _status = 'SPEAKING…';
          _voiceEnergy = 0.7;
        });
      }
      try {
        await _speakOnce(u.text);
      } catch (_) {}
      if (!mounted) break;
    }
    _draining = false;
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        if (!_isProcessing && !_isListening) _status = 'SYSTEM READY';
      });
    }
    if (_continuous && mounted && !_isProcessing && !_isListening) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_continuous && mounted && !_isProcessing && !_isListening) {
        _startListening();
      }
    }
  }

  Future<void> _speakOnce(String text) async {
    if (_ttsMode == 'elevenlabs' &&
        _elevenKey != null &&
        _elevenKey!.isNotEmpty) {
      try {
        final bytes = await _synthesiseEleven(text);
        if (bytes != null) {
          await _player.play(BytesSource(bytes));
          await _player.onPlayerComplete.first;
          return;
        }
      } catch (_) {}
    }
    final key = _apiKey;
    if (_ttsMode == 'openai' && key != null && key.isNotEmpty) {
      try {
        final bytes = await _synthesise(text, key);
        if (bytes != null) {
          await _player.play(BytesSource(bytes));
          await _player.onPlayerComplete.first;
          return;
        }
      } catch (_) {}
    }
    await _tts.speak(text);
  }

  Future<Uint8List?> _synthesiseEleven(String text) async {
    final voice = _elevenVoice.isNotEmpty ? _elevenVoice : kDefaultElevenVoice;
    final uri = Uri.parse('$kElevenSpeechUrl$voice');
    final response = await http
        .post(
          uri,
          headers: {
            'Accept': 'audio/mpeg',
            'Content-Type': 'application/json',
            'xi-api-key': _elevenKey!,
          },
          body: jsonEncode({
            'text': text,
            'model_id': 'eleven_multilingual_v2',
            'voice_settings': {
              'stability': 0.45,
              'similarity_boost': 0.8,
              'style': 0.35,
              'use_speaker_boost': true,
            },
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) return null;
    return response.bodyBytes;
  }

  Future<Uint8List?> _synthesise(String text, String key) async {
    final response = await http
        .post(
          Uri.parse(kSpeechEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $key'
          },
          body: jsonEncode({
            'model': kTtsModel,
            'voice': _voice,
            'input': text,
            'response_format': 'mp3',
          }),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) return null;
    return response.bodyBytes;
  }

  Future<void> _clearSpeech() async {
    _speechQueue.clear();
    await _tts.stop();
    await _player.stop();
    if (_isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isListening = false;
        if (!_isProcessing) _status = 'SYSTEM READY';
      });
    }
  }

  Future<Map<String, dynamic>> _fetchFivemStatus() async {
    try {
      final resp = await http
          .get(Uri.parse('$kLdrpBase/players.json'))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) {
        return {'online': false, 'monitoring_24_7': _serviceRunning};
      }
      final list = jsonDecode(resp.body) as List;
      final names = <String>[];
      for (final p in list) {
        if (p is Map) {
          final n = p['name']?.toString();
          if (n != null && n.isNotEmpty) names.add(n);
        }
      }
      return {
        'online': true,
        'player_count': names.length,
        'players': names,
        'monitoring_24_7': _serviceRunning,
      };
    } catch (e) {
      return {
        'online': false,
        'error': e.toString(),
        'monitoring_24_7': _serviceRunning,
      };
    }
  }

  Future<Map<String, dynamic>> _fetchWebSearch(String query) async {
    final key = await _storage.read(key: kBraveApiKeyKey);
    if (key == null || key.isEmpty) {
      return {'ok': false, 'error': 'No Brave API key set in Settings'};
    }
    try {
      final uri = Uri.parse(kBraveSearchEndpoint)
          .replace(queryParameters: {'q': query, 'count': '5'});
      final resp = await http.get(uri, headers: {
        'Accept': 'application/json',
        'X-Subscription-Token': key,
      }).timeout(const Duration(seconds: 12));

      if (resp.statusCode != 200) {
        return {'ok': false, 'error': 'Brave API returned ${resp.statusCode}'};
      }

      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map;
      final results = <Map<String, String>>[];
      final webResults = (data['web'] as Map?)?['results'] as List?;
      if (webResults != null) {
        for (final r in webResults.take(5)) {
          if (r is Map) {
            results.add({
              'title': (r['title'] ?? '').toString(),
              'url': (r['url'] ?? '').toString(),
              'snippet': (r['description'] ?? '').toString(),
            });
          }
        }
      }
      return {'ok': true, 'query': query, 'results': results};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<void> _tryAutoRestart() async {
    final webhook = await _storage.read(key: kRestartWebhookKey);
    if (webhook != null && webhook.isNotEmpty) {
      await _prefs?.setString('fivem_restart_webhook_plain', webhook);
    }
    if (webhook == null || webhook.isEmpty) {
      _enqueueSpeech('No restart webhook is configured, sir.', SpeechPriority.fivem);
      return;
    }
    _note('Attempting restart');
    try {
      final resp =
          await http.post(Uri.parse(webhook)).timeout(const Duration(seconds: 10));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        _enqueueSpeech('Restart command sent, sir.', SpeechPriority.fivem);
      } else {
        _enqueueSpeech('Webhook returned ${resp.statusCode}.', SpeechPriority.fivem);
      }
    } catch (_) {
      _enqueueSpeech('I am afraid I could not reach the restart webhook, sir.', SpeechPriority.fivem);
    }
  }

  Future<void> _checkNotificationPermission() async {
    final granted = await NotificationListenerService.isPermissionGranted();
    if (mounted) setState(() => _notificationsEnabled = granted);
    if (granted) _startNotificationListener();
  }

  Future<void> _requestNotificationPermission() async {
    // Opens system Notification access screen (Samsung / Android)
    var granted = await NotificationListenerService.requestPermission();
    if (!granted) {
      try {
        const intent = AndroidIntent(
          action: 'android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS',
        );
        await intent.launch();
      } catch (_) {
        try {
          const intent = AndroidIntent(
            action: 'android.settings.NOTIFICATION_LISTENER_SETTINGS',
          );
          await intent.launch();
        } catch (e) {
          _addLog('system', 'Could not open Notification access settings: $e');
        }
      }
      // Re-check after user returns
      await Future.delayed(const Duration(seconds: 2));
      granted = await NotificationListenerService.isPermissionGranted();
    }
    if (mounted) setState(() => _notificationsEnabled = granted);
    if (granted) {
      _startNotificationListener();
      _addLog('system', 'Notification access granted — listener active.');
    } else {
      _addLog(
        'system',
        'Notification access NOT granted. Enable J.A.R.V.I.S in Notification access, then say "enable discord auto-reply" again.',
      );
    }
  }

  /// Turn on unavailable / Discord auto-reply end-to-end.
  Future<Map<String, dynamic>> _enableDiscordAwayMode() async {
    _discordAutoReply = true;
    await _prefs?.setBool(kPrefDiscordAutoReply, true);

    await _checkNotificationPermission();
    if (!_notificationsEnabled) {
      await _requestNotificationPermission();
    } else {
      _startNotificationListener();
    }

    // Keep process alive so listener is not killed on Samsung
    if (!_serviceRunning) {
      try {
        await _startForegroundService();
      } catch (e) {
        _addLog('system', 'Foreground service note: $e');
      }
    } else {
      try {
        await FlutterForegroundTask.updateService(
          notificationTitle: 'JARVIS · Away mode',
          notificationText: 'Discord auto-reply active',
        );
      } catch (_) {}
    }

    final granted = _notificationsEnabled ||
        await NotificationListenerService.isPermissionGranted();
    _notificationsEnabled = granted;
    if (granted) _startNotificationListener();

    if (mounted) setState(() {});
    return {
      'ok': true,
      'discord_auto_reply': true,
      'notifications_granted': granted,
      'message': granted
          ? 'Unavailable mode is on. I will reply to Discord DMs. Keep this notification / app running.'
          : 'Unavailable mode is flagged on, but Notification access is still off. Open the settings screen, enable J.A.R.V.I.S, then try again.',
    };
  }

  bool _isSensitive(String text) =>
      kSensitivePatterns.any((p) => p.hasMatch(text));

  void _startNotificationListener() {
    _notificationSubscription?.cancel();
    _notificationSubscription =
        NotificationListenerService.notificationsStream.listen((event) async {
      try {
        if (event.hasRemoved == true) return;

        final title = (event.title ?? '').trim();
        final body = (event.content ?? '').trim();
        final package = (event.packageName ?? '').trim().toLowerCase();
        final combined = '$title $body';
        final isDiscord =
            package == 'com.discord' || package.contains('discord');

        if (isDiscord) {
          _addLog(
            'system',
            'Discord notif · canReply=${event.canReply} · pkg=$package · "$title" · "$body"',
          );
        }

        if ((title.isEmpty && body.isEmpty) || _isSensitive(combined)) {
          return;
        }

        // --- Unavailable mode: reply immediately (no AI delay) ---
        if (isDiscord && _discordAutoReply) {
          // Skip non-message Discord noise
          final lower = combined.toLowerCase();
          if (lower.contains('missed call') ||
              lower.contains('is calling') ||
              lower.contains('started a call') ||
              lower.contains('incoming call') ||
              lower.contains('friend request') ||
              lower.contains('sent you a friend') ||
              lower.contains('voice message') && body.isEmpty) {
            _addLog('system', 'Skipping non-DM Discord notification');
            return;
          }
          // Server posts often use title "Discord" or "#channel"
          final sender = title.isNotEmpty ? title : 'someone';
          if (sender.toLowerCase() == 'discord' && body.isEmpty) {
            return;
          }

          final msg =
              body.isNotEmpty ? body : (title.isNotEmpty ? title : 'New message');

          final dedupeKey = '$package|${sender.toLowerCase()}|${body.hashCode}';
          final last = _discordRecentReplies[dedupeKey];
          final now = DateTime.now();
          // Only skip if we already *succeeded* recently for same content
          if (last != null && now.difference(last).inSeconds < 90) {
            _addLog('system', 'Skipping duplicate Discord notif from $sender');
            return;
          }

          final announce = body.isNotEmpty
              ? 'Discord from $sender. $body'
              : 'Discord from $sender.';
          _enqueueSpeech(announce, SpeechPriority.notification);

          final ok = await _sendDiscordReplyNow(event, sender, msg);
          if (ok) {
            _discordRecentReplies[dedupeKey] = now;
            _discordRecentReplies
                .removeWhere((_, ts) => now.difference(ts).inMinutes > 15);
          }
          return;
        }

        // Normal announce path for allowed apps.
        final allowed = kAllowedPackages.contains(package) ||
            kAllowedPackages.any(
              (p) => package == p.toLowerCase() || package.endsWith(p.split('.').last),
            );
        if (!allowed) return;

        final message = body.isNotEmpty
            ? 'New notification from $title. $body'
            : 'New notification from $title';
        _enqueueSpeech(message, SpeechPriority.notification);
      } catch (e) {
        _addLog('system', 'Notification handler error: $e');
      }
    });
  }

  /// Sends the unavailable reply immediately. Android drops RemoteInput
  /// actions if we wait on a network call first.
  /// Returns true if a reply was delivered (notification RemoteInput or bot fallback).
  Future<bool> _sendDiscordReplyNow(
    dynamic event,
    String sender,
    String message,
  ) async {
    // Keep first line short — RemoteInput often fails on very long text.
    const shortReply =
        "Emp is currently unavailable. I'll pass this on when they're back.";
    final fullReply = '$shortReply$kDiscordAutoReplyFooter';

    _addLog(
      'system',
      'Sending Discord reply to $sender (canReply=${event.canReply})…',
    );

    bool ok = false;
    Object? err;

    // Multiple attempts — Discord/Samsung often need a delay before RemoteInput works
    final attempts = <String>[
      shortReply,
      shortReply,
      fullReply,
      "Emp is unavailable right now.",
      fullReply,
    ];
    final delays = <int>[0, 300, 600, 1000, 1500];
    for (var i = 0; i < attempts.length; i++) {
      if (ok) break;
      try {
        if (delays[i] > 0) {
          await Future.delayed(Duration(milliseconds: delays[i]));
        }
        final r = await event.sendReply(attempts[i]);
        ok = r == true;
        if (ok) {
          _addLog('system', 'Reply succeeded on attempt ${i + 1}');
        }
      } catch (e) {
        err = e;
      }
    }

    // Fallback: post to Discord bot default channel so staff still see it
    if (!ok && _discordBotConfigured && _discordBotChannel.trim().isNotEmpty) {
      final notice =
          '**Away auto-reply** — DM from **$sender** could not be answered via notification reply.\n'
          '> ${message.length > 200 ? message.substring(0, 200) : message}\n'
          '_Emp is unavailable. Jarvis attempted a direct reply (canReply=${event.canReply})._';
      final bot = await _discordBotSend(content: notice);
      if (bot['ok'] == true) {
        _addLog(
          'system',
          'Notification reply failed; posted away notice to bot channel.',
        );
        _enqueueSpeech(
          'I could not reply in the Discord notification, sir, but I posted an away notice in the bot channel.',
          SpeechPriority.notification,
        );
        return false;
      }
    }

    if (ok) {
      _addLog('assistant', 'Replied to $sender on Discord: $shortReply');
      _enqueueSpeech(
        'I replied to $sender on Discord.',
        SpeechPriority.notification,
      );
      return true;
    }

    _addLog(
      'system',
      'Discord reply FAILED for $sender '
      '(canReply=${event.canReply}, error=$err). '
      'Fix: Settings → grant Notification Access to J.A.R.V.I.S; '
      'use a real Discord DM (not a server channel); '
      'expand the notification and confirm a Reply action exists; '
      'keep Jarvis in recents (not force-stopped); '
      'Discord → Settings → Notifications → enable message notifications.',
    );
    _enqueueSpeech(
      'I detected a Discord message from $sender but could not send a reply. Check notification access, sir.',
      SpeechPriority.system,
    );
    return false;
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (s) {
        if (mounted && (s == 'done' || s == 'notListening')) {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _status = 'MICROPHONE ERROR';
          });
        }
      },
    );
    if (mounted) {
      setState(() {
        _speechReady = available;
        if (!available) _status = 'SPEECH UNAVAILABLE';
      });
    }
  }

  Future<void> _startListening() async {
    if (!_speechReady || _isListening || _isProcessing) return;
    HapticFeedback.lightImpact();
    await _clearSpeech();
    if (!mounted) return;
    setState(() {
      _isListening = true;
      _status = 'LISTENING…';
      _lastWords = '';
      _toolNote = '';
      _voiceEnergy = 0.35;
    });
    await _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        // Approximate energy from word growth
        final len = r.recognizedWords.length;
        final e = (0.25 + (len % 40) / 40.0 * 0.7).clamp(0.2, 1.0);
        setState(() {
          _lastWords = r.recognizedWords;
          _voiceEnergy = e;
        });
        if (r.finalResult && r.recognizedWords.trim().isNotEmpty) {
          _handleFinalResult(r.recognizedWords.trim());
        }
      },
      listenFor: const Duration(seconds: 18),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_GB',
    );
  }

  void _handleFinalResult(String phrase) {
    final now = DateTime.now();
    if (phrase == _lastHandledPhrase &&
        now.difference(_lastHandledAt) < const Duration(seconds: 3)) {
      return;
    }
    if (_isProcessing) return;
    // Wake-word strip: "Hey J.A.R.V.I.S., status" -> "status"
    var cleaned = phrase.trim();
    final lower = cleaned.toLowerCase();
    for (final w in [
      'hey jarvis ',
      'ok jarvis ',
      'okay jarvis ',
      'jarvis ',
      'hey j.a.r.v.i.s. ',
      'j.a.r.v.i.s. ',
    ]) {
      if (lower.startsWith(w)) {
        cleaned = cleaned.substring(w.length).trim();
        break;
      }
    }
    if (cleaned.isEmpty) cleaned = phrase.trim();
    _lastHandledPhrase = phrase;
    _lastHandledAt = now;
    HapticFeedback.selectionClick();
    _processCommand(cleaned);
  }

  void _note(String text) {
    // Film-style brief tool HUD
    final mapped = text.trim().isEmpty
        ? ''
        : (text.toLowerCase().contains('check')
            ? 'Check.'
            : text);
    if (mounted) setState(() => _toolNote = mapped);
  }

  void _toggleContinuous() {
    HapticFeedback.mediumImpact();
    setState(() => _continuous = !_continuous);
    _prefs?.setBool(kPrefContinuous, _continuous);
    if (_continuous) {
      _addLog('system', 'Hands-free mode engaged. I am listening, sir.');
      if (!_isProcessing && !_isListening && !_isSpeaking) {
        _startListening();
      }
      if (_selfImprove) _startSelfImproveLoop();
    } else {
      _addLog('system', 'Hands-free mode disengaged. Tap when you need me.');
      _selfImproveTimer?.cancel();
    }
  }

  void _clearContext() {
    HapticFeedback.mediumImpact();
    _history.clear();
    _uiLog.clear();
    setState(() {
      _status = 'SYSTEM READY';
      _toolNote = '';
    });
    _addLog('system', 'Conversation context cleared.');
    _enqueueSpeech('Context cleared, sir. Fresh slate.', SpeechPriority.system);
  }

  List<Map<String, dynamic>> _allToolSchemas() {
    final list = <Map<String, dynamic>>[...kBuiltinToolSchema];
    for (final t in _dynamicTools) {
      list.add({
        'type': 'function',
        'function': {
          'name': t['name'],
          'description': t['description'] ?? '',
          'parameters': sanitizeToolSchema(t['parameters_schema']),
        }
      });
    }
    return list;
  }


  Future<Map<String, String?>> _githubConfig() async {
    final token = await _storage.read(key: kGithubTokenKey);
    final repo = (await _storage.read(key: kGithubRepoKey)) ??
        (_prefs?.getString(kPrefGithubRepo) ?? '');
    return {'token': token, 'repo': repo.trim()};
  }

  Future<http.Response> _githubRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final tkn = token ?? (await _storage.read(key: kGithubTokenKey));
    final headers = <String, String>{
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'Jarvis-Mobile',
    };
    if (tkn != null && tkn.isNotEmpty) {
      headers['Authorization'] = 'Bearer $tkn';
    }
    final uri = Uri.parse('https://api.github.com$path');
    if (method == 'GET') {
      return http.get(uri, headers: headers);
    }
    headers['Content-Type'] = 'application/json';
    final encoded = body == null ? null : jsonEncode(body);
    if (method == 'PUT') {
      return http.put(uri, headers: headers, body: encoded);
    }
    if (method == 'POST') {
      return http.post(uri, headers: headers, body: encoded);
    }
    if (method == 'PATCH') {
      return http.patch(uri, headers: headers, body: encoded);
    }
    return http.get(uri, headers: headers);
  }

  Future<String> _githubWriteFile({
    required String repo,
    required String path,
    required String content,
    required String message,
    String branch = 'main',
  }) async {
    final cfg = await _githubConfig();
    if ((cfg['token'] ?? '').isEmpty) {
      return jsonEncode({
        'ok': false,
        'error': 'GitHub token not set. Add a personal access token with repo scope in Settings.',
      });
    }
    if (repo.isEmpty) {
      return jsonEncode({
        'ok': false,
        'error': 'GitHub repo not set. Use owner/name in Settings.',
      });
    }
    // Get existing SHA if file exists
    String? sha;
    final getRes = await _githubRequest(
      'GET',
      '/repos/$repo/contents/${path.split("/").map(Uri.encodeComponent).join("/")}?ref=$branch',
    );
    if (getRes.statusCode == 200) {
      final data = jsonDecode(getRes.body);
      if (data is Map && data['sha'] is String) sha = data['sha'] as String;
    } else if (getRes.statusCode != 404) {
      return jsonEncode({
        'ok': false,
        'error': 'Could not read existing file (${getRes.statusCode})',
        'body': getRes.body.length > 400 ? getRes.body.substring(0, 400) : getRes.body,
      });
    }

    final putBody = <String, dynamic>{
      'message': message,
      'content': base64Encode(utf8.encode(content)),
      'branch': branch,
    };
    if (sha != null) putBody['sha'] = sha;

    final putRes = await _githubRequest(
      'PUT',
      '/repos/$repo/contents/${path.split("/").map(Uri.encodeComponent).join("/")}',
      body: putBody,
    );
    if (putRes.statusCode == 200 || putRes.statusCode == 201) {
      final data = jsonDecode(putRes.body);
      final commit = data is Map ? data['commit'] : null;
      final html = commit is Map ? commit['html_url'] : null;
      return jsonEncode({
        'ok': true,
        'path': path,
        'branch': branch,
        'commit_url': html,
        'message': 'Committed improvement to GitHub.',
      });
    }
    return jsonEncode({
      'ok': false,
      'status': putRes.statusCode,
      'error': putRes.body.length > 500 ? putRes.body.substring(0, 500) : putRes.body,
    });
  }


  Future<String> _runTool(String name, Map<String, dynamic> args) async {
    switch (name) {
      case 'get_current_time':
        _note('Checking the time');
        final now = DateTime.now();
        const days = [
          'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
        ];
        const months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return jsonEncode({
          'time':
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          'day': days[now.weekday - 1],
          'date': '${now.day} ${months[now.month - 1]} ${now.year}',
        });
      case 'set_alarm':
        final hour = (args['hour'] as num?)?.toInt();
        final minute = (args['minute'] as num?)?.toInt() ?? 0;
        if (hour == null || hour < 0 || hour > 23) return jsonEncode({'ok': false});
        try {
          await AndroidIntent(action: 'android.intent.action.SET_ALARM', arguments: {
            'android.intent.extra.alarm.HOUR': hour,
            'android.intent.extra.alarm.MINUTES': minute,
            'android.intent.extra.alarm.MESSAGE':
                (args['label'] ?? 'J.A.R.V.I.S').toString(),
            'android.intent.extra.alarm.SKIP_UI': true,
          }).launch();
          return jsonEncode({'ok': true});
        } catch (_) {
          return jsonEncode({'ok': false});
        }
      case 'set_timer':
        final seconds = (args['seconds'] as num?)?.toInt();
        if (seconds == null || seconds <= 0) return jsonEncode({'ok': false});
        try {
          await AndroidIntent(action: 'android.intent.action.SET_TIMER', arguments: {
            'android.intent.extra.alarm.LENGTH': seconds,
            'android.intent.extra.alarm.MESSAGE':
                (args['label'] ?? 'J.A.R.V.I.S').toString(),
            'android.intent.extra.alarm.SKIP_UI': true,
          }).launch();
          return jsonEncode({'ok': true});
        } catch (_) {
          return jsonEncode({'ok': false});
        }
      case 'web_search':
        final query = (args['query'] ?? '').toString().trim();
        if (query.isEmpty) return jsonEncode({'ok': false, 'error': 'No query given'});
        _note('Searching the web');
        return jsonEncode(await _fetchWebSearch(query));
      case 'ldrp_server_status':
      case 'get_fivem_health':
        _note('Checking LDRP');
        return jsonEncode(await _fetchFivemStatus());
      case 'start_fivem_monitor':
        await _startForegroundService();
        return jsonEncode({'ok': true, 'monitoring_24_7': true});
      case 'stop_fivem_monitor':
        await _stopForegroundService();
        return jsonEncode({'ok': true, 'monitoring_24_7': false});
      case 'attempt_fivem_restart':
        await _tryAutoRestart();
        return jsonEncode({'ok': true});
      case 'remember':
        final fact = (args['fact'] ?? args['text'] ?? '').toString().trim();
        if (fact.isEmpty) return jsonEncode({'ok': false, 'error': 'fact required'});
        final cat = (args['category'] ?? 'general').toString();
        final imp = (args['importance'] is num)
            ? (args['importance'] as num).toInt()
            : int.tryParse('${args['importance']}') ?? 5;
        final stored = await _mindStoreFact(fact, category: cat, importance: imp);
        if (mounted) setState(() {});
        return jsonEncode(stored);
      case 'forget_all':
        _memory.clear();
        await _saveMemory();
        if (mounted) setState(() {});
        return jsonEncode({'ok': true});
      case 'summarize_emails':
        final user = await _storage.read(key: kEmailUserKey);
        final pass = await _storage.read(key: kEmailPassKey);
        if (user == null || pass == null) {
          return jsonEncode({'ok': false, 'error': 'No email credentials'});
        }
        return jsonEncode({'ok': true, 'status': 'Credentials present for $user'});
      case 'add_capability':
        final n = (args['name'] ?? '').toString().trim().toLowerCase();
        final d = (args['description'] ?? '').toString().trim();
        if (n.isEmpty || d.isEmpty) return jsonEncode({'ok': false});
        // Guard: do not overwrite built-in names
        final builtin = kBuiltinToolSchema
            .map((t) => (t['function'] as Map)['name'] as String)
            .toSet();
        if (builtin.contains(n)) {
          return jsonEncode({'ok': false, 'error': 'Name collides with a built-in tool'});
        }
        _dynamicTools.removeWhere((t) => t['name'] == n);
        if (_dynamicTools.length >= kMaxDynamicTools) _dynamicTools.removeAt(0);
        final hint = (args['implementation_hint'] ?? '').toString().trim();
        _dynamicTools.add({
          'name': n,
          'description': d,
          'parameters_schema': sanitizeToolSchema(args['parameters_schema']),
          'implementation_hint': hint.isEmpty
              ? 'Reason about the request using available context and produce a useful result.'
              : hint,
          'added_at': DateTime.now().toIso8601String(),
          'use_count': 0,
        });
        await _saveDynamicTools();
        if (mounted) setState(() {});
        _addLog('system', 'New capability installed: $n');
        return jsonEncode({
          'ok': true,
          'name': n,
          'message':
              'Capability "$n" is now permanently available. Call it by name when relevant.',
        });
      case 'list_capabilities':
        final tools = <Map<String, dynamic>>[];
        for (final t in kBuiltinToolSchema) {
          tools.add({
            'name': (t['function'] as Map)['name'],
            'kind': 'builtin',
          });
        }
        for (final t in _dynamicTools) {
          tools.add({
            'name': t['name'],
            'kind': 'dynamic',
            'description': t['description'],
            'use_count': t['use_count'] ?? 0,
          });
        }
        return jsonEncode({'count': tools.length, 'tools': tools});
      case 'remove_capability':
        final n = (args['name'] ?? '').toString().trim().toLowerCase();
        final before = _dynamicTools.length;
        _dynamicTools.removeWhere((t) => t['name'] == n);
        if (_dynamicTools.length == before) return jsonEncode({'ok': false});
        await _saveDynamicTools();
        if (mounted) setState(() {});
        _addLog('system', 'Capability removed: $n');
        return jsonEncode({'ok': true});
      case 'update_own_prompt':
        final extra = (args['extra_instruction'] ?? '').toString().trim();
        if (extra.isEmpty) return jsonEncode({'ok': false});
        _systemPromptExtra = args['replace'] == true
            ? extra
            : (_systemPromptExtra.isEmpty ? extra : '$_systemPromptExtra\n$extra');
        if (_systemPromptExtra.length > 1200) {
          _systemPromptExtra =
              _systemPromptExtra.substring(_systemPromptExtra.length - 1200);
        }
        await _saveSystemPromptExtra();
        _addLog('system', 'Behaviour instructions updated.');
        return jsonEncode({'ok': true});
      case 'self_improve_suggestion':
        final existing = _dynamicTools.map((t) => t['name']).toList();
        return jsonEncode({
          'instruction':
              'Propose exactly one concrete new capability that would help this user. '
              'Prefer something practical and reusable. Then, if it is clearly useful, '
              'call add_capability with a clear name, description, parameters_schema, '
              'and a detailed implementation_hint explaining how to fulfil the task when called.',
          'existing_dynamic_tools': existing,
          'memory_count': _memory.length,
          'hint':
              'Good examples: unit converter, quick recipe ideas, workout planner, '
              'packing list builder, meeting agenda helper. Avoid duplicates.',
        });
      case 'enable_discord_auto_reply':
        final away = await _enableDiscordAwayMode();
        _addLog('system', 'Discord unavailable mode ON — will auto-reply to DMs.');
        return jsonEncode(away);
      case 'disable_discord_auto_reply':
        _discordAutoReply = false;
        await _prefs?.setBool(kPrefDiscordAutoReply, false);
        if (mounted) setState(() {});
        _addLog('system', 'Discord unavailable mode OFF.');
        return jsonEncode({
          'ok': true,
          'discord_auto_reply': false,
          'message': 'Unavailable mode is off. Discord DMs will only be announced.',
        });
      case 'get_discord_auto_reply_status':
        final granted = await NotificationListenerService.isPermissionGranted();
        return jsonEncode({
          'discord_auto_reply': _discordAutoReply,
          'notifications_enabled': granted,
        });

      case 'github_status':
        {
          final cfg = await _githubConfig();
          final hasToken = (cfg['token'] ?? '').isNotEmpty;
          final repo = cfg['repo'] ?? '';
          return jsonEncode({
            'ok': true,
            'configured': hasToken && repo.isNotEmpty,
            'has_token': hasToken,
            'repo': repo.isEmpty ? null : repo,
            'hint': hasToken && repo.isNotEmpty
                ? 'GitHub ready. You can list/read/write files and open issues to improve yourself.'
                : 'User must set GitHub token (repo scope) and owner/repo in Settings.',
          });
        }
      case 'github_list_files':
        {
          final cfg = await _githubConfig();
          final repo = cfg['repo'] ?? '';
          if ((cfg['token'] ?? '').isEmpty || repo.isEmpty) {
            return jsonEncode({'ok': false, 'error': 'GitHub not configured'});
          }
          final path = (args['path'] ?? '').toString().trim();
          final ref = (args['ref'] ?? 'main').toString().trim();
          final enc = path.isEmpty
              ? ''
              : '/${path.split("/").map(Uri.encodeComponent).join("/")}';
          final res = await _githubRequest(
            'GET',
            '/repos/$repo/contents$enc?ref=$ref',
          );
          if (res.statusCode != 200) {
            return jsonEncode({'ok': false, 'status': res.statusCode, 'body': res.body.substring(0, res.body.length > 400 ? 400 : res.body.length)});
          }
          final data = jsonDecode(res.body);
          if (data is List) {
            final items = data.map((e) {
              if (e is! Map) return e.toString();
              return {
                'name': e['name'],
                'path': e['path'],
                'type': e['type'],
                'size': e['size'],
              };
            }).toList();
            return jsonEncode({'ok': true, 'path': path, 'items': items});
          }
          if (data is Map) {
            return jsonEncode({
              'ok': true,
              'file': {
                'name': data['name'],
                'path': data['path'],
                'type': data['type'],
                'size': data['size'],
              }
            });
          }
          return jsonEncode({'ok': false, 'error': 'Unexpected response'});
        }
      case 'github_read_file':
        {
          final cfg = await _githubConfig();
          final repo = cfg['repo'] ?? '';
          if ((cfg['token'] ?? '').isEmpty || repo.isEmpty) {
            return jsonEncode({'ok': false, 'error': 'GitHub not configured'});
          }
          final path = (args['path'] ?? '').toString().trim();
          if (path.isEmpty) return jsonEncode({'ok': false, 'error': 'path required'});
          final ref = (args['ref'] ?? 'main').toString().trim();
          final res = await _githubRequest(
            'GET',
            '/repos/$repo/contents/${path.split("/").map(Uri.encodeComponent).join("/")}?ref=$ref',
          );
          if (res.statusCode != 200) {
            return jsonEncode({'ok': false, 'status': res.statusCode, 'error': res.body.substring(0, res.body.length > 400 ? 400 : res.body.length)});
          }
          final data = jsonDecode(res.body);
          if (data is! Map) return jsonEncode({'ok': false, 'error': 'not a file'});
          final encoding = data['encoding'];
          final contentB64 = data['content']?.toString().replaceAll('\n', '') ?? '';
          String text = '';
          if (encoding == 'base64' && contentB64.isNotEmpty) {
            try {
              text = utf8.decode(base64Decode(contentB64));
            } catch (_) {
              return jsonEncode({'ok': false, 'error': 'Failed to decode file'});
            }
          }
          // Cap size for model context
          const maxChars = 24000;
          final truncated = text.length > maxChars;
          if (truncated) text = text.substring(0, maxChars);
          return jsonEncode({
            'ok': true,
            'path': path,
            'sha': data['sha'],
            'size': data['size'],
            'truncated': truncated,
            'content': text,
          });
        }
      case 'github_write_file':
        {
          final cfg = await _githubConfig();
          final repo = cfg['repo'] ?? '';
          final path = (args['path'] ?? '').toString().trim();
          final content = (args['content'] ?? '').toString();
          final message = (args['message'] ?? 'Jarvis self-improvement').toString();
          final branch = (args['branch'] ?? 'main').toString().trim();
          if (path.isEmpty) return jsonEncode({'ok': false, 'error': 'path required'});
          return await _githubWriteFile(
            repo: repo,
            path: path,
            content: content,
            message: message,
            branch: branch.isEmpty ? 'main' : branch,
          );
        }
      case 'github_create_issue':
        {
          final cfg = await _githubConfig();
          final repo = cfg['repo'] ?? '';
          if ((cfg['token'] ?? '').isEmpty || repo.isEmpty) {
            return jsonEncode({'ok': false, 'error': 'GitHub not configured'});
          }
          final title = (args['title'] ?? '').toString().trim();
          final body = (args['body'] ?? '').toString();
          if (title.isEmpty) return jsonEncode({'ok': false, 'error': 'title required'});
          final labels = args['labels'];
          final payload = <String, dynamic>{'title': title, 'body': body};
          if (labels is List) {
            payload['labels'] = labels.map((e) => e.toString()).toList();
          }
          final res = await _githubRequest('POST', '/repos/$repo/issues', body: payload);
          if (res.statusCode == 201) {
            final data = jsonDecode(res.body);
            return jsonEncode({
              'ok': true,
              'number': data is Map ? data['number'] : null,
              'url': data is Map ? data['html_url'] : null,
            });
          }
          return jsonEncode({'ok': false, 'status': res.statusCode, 'error': res.body.substring(0, res.body.length > 400 ? 400 : res.body.length)});
        }
      case 'github_list_commits':
        {
          final cfg = await _githubConfig();
          final repo = cfg['repo'] ?? '';
          if ((cfg['token'] ?? '').isEmpty || repo.isEmpty) {
            return jsonEncode({'ok': false, 'error': 'GitHub not configured'});
          }
          var limit = 8;
          if (args['limit'] is int) limit = args['limit'] as int;
          if (limit < 1) limit = 1;
          if (limit > 15) limit = 15;
          final res = await _githubRequest('GET', '/repos/$repo/commits?per_page=$limit');
          if (res.statusCode != 200) {
            return jsonEncode({'ok': false, 'status': res.statusCode});
          }
          final data = jsonDecode(res.body);
          if (data is! List) return jsonEncode({'ok': false});
          final commits = data.map((e) {
            if (e is! Map) return e.toString();
            final commit = e['commit'];
            final msg = commit is Map ? commit['message'] : '';
            final author = commit is Map && commit['author'] is Map
                ? (commit['author'] as Map)['name']
                : '';
            return {
              'sha': (e['sha']?.toString() ?? '').length > 7
                  ? e['sha'].toString().substring(0, 7)
                  : e['sha'],
              'message': msg,
              'author': author,
              'url': e['html_url'],
            };
          }).toList();
          return jsonEncode({'ok': true, 'commits': commits});
        }
      case 'self_improve_push':
        {
          final cfg = await _githubConfig();
          final repo = cfg['repo'] ?? '';
          final title = (args['title'] ?? 'improvement')
              .toString()
              .trim()
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
              .replaceAll(RegExp(r'^_|_$'), '');
          final content = (args['content'] ?? '').toString();
          final message = (args['message'] ?? 'Jarvis self-improvement: $title').toString();
          if (title.isEmpty || content.isEmpty) {
            return jsonEncode({'ok': false, 'error': 'title and content required'});
          }
          final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
          final path = 'jarvis_improvements/${stamp}_$title.md';
          final body = '# $title\n\n_Pushed by mobile J.A.R.V.I.S._\n\n$content\n';
          return await _githubWriteFile(
            repo: repo,
            path: path,
            content: body,
            message: message,
          );
        }


      
      
      
      case 'discord_bot_test':
        _note('Discord bot test');
        return jsonEncode(await _discordBotMe());
      case 'discord_bot_send':
        final c = (args['content'] ?? '').toString();
        final ch = args['channel_id']?.toString();
        _note('Discord bot send');
        return jsonEncode(await _discordBotSend(content: c, channelId: ch));
      case 'discord_bot_dm':
        final uid = (args['user_id'] ?? '').toString();
        final c = (args['content'] ?? '').toString();
        _note('Discord bot DM');
        return jsonEncode(await _discordBotDm(userId: uid, content: c));

      case 'tx_login_test':
        _note('txAdmin login');
        return jsonEncode(await _txLogin(force: true));
      case 'tx_resource':
        final a = (args['action'] ?? 'restart').toString();
        final r = (args['resource'] ?? '').toString();
        _note('txAdmin resource $a');
        return jsonEncode(await _txResourceAction(a, r));
      case 'tx_server':
        final a = (args['action'] ?? 'restart').toString();
        _note('txAdmin server $a');
        return jsonEncode(await _txServerControl(a));
      case 'tx_announce':
        final m = (args['message'] ?? '').toString();
        _note('txAdmin announce');
        return jsonEncode(await _txAnnounce(m));
      case 'tx_refresh':
        _note('txAdmin refresh');
        return jsonEncode(await _txRefreshResources());

      case 'ptero_status':
        _note('Checking Pterodactyl');
        return jsonEncode(await _pteroStatus());
      case 'ptero_power':
        final sig = (args['signal'] ?? '').toString();
        _note('Power: $sig');
        return jsonEncode(await _pteroPower(sig));
      case 'ptero_command':
        final cmd = (args['command'] ?? '').toString();
        _note('Console command');
        return jsonEncode(await _pteroCommand(cmd));
      case 'ptero_backup':
        final n = args['name']?.toString();
        _note('Creating backup');
        return jsonEncode(await _pteroBackup(name: n));
      case 'ptero_list_backups':
        _note('Listing backups');
        return jsonEncode(await _pteroListBackups());

      case 'set_reminder':
        final mins = (args['minutes'] is num)
            ? (args['minutes'] as num).toDouble()
            : double.tryParse('${args['minutes']}') ?? 5;
        final rtext = (args['text'] ?? '').toString().trim();
        if (rtext.isEmpty) {
          return jsonEncode({'ok': false, 'error': 'text required'});
        }
        final when = DateTime.now()
            .add(Duration(minutes: mins.round()))
            .millisecondsSinceEpoch;
        _reminders.add({'text': rtext, 'when_ms': when});
        await _prefs?.setString(kPrefReminders, jsonEncode(_reminders));
        return jsonEncode({
          'ok': true,
          'in_minutes': mins.round(),
          'text': rtext,
        });
      case 'list_reminders':
        return jsonEncode({'ok': true, 'reminders': _reminders});
      case 'cancel_reminders':
        _reminders.clear();
        await _prefs?.setString(kPrefReminders, '[]');
        return jsonEncode({'ok': true});
      case 'deliver_briefing':
        await _deliverBriefing(proactive: false);
        return jsonEncode({'ok': true});
      case 'set_private_mode':
        _privateMode = args['enabled'] == true;
        await _prefs?.setBool(kPrefPrivateMode, _privateMode);
        return jsonEncode({'ok': true, 'private_mode': _privateMode});
      case 'set_incident_mode':
        _incidentMode = args['enabled'] == true;
        await _prefs?.setBool(kPrefIncidentMode, _incidentMode);
        return jsonEncode({'ok': true, 'incident_mode': _incidentMode});
      case 'set_hud_theme':
        final th = (args['theme'] ?? 'classic').toString().toLowerCase();
        if (!['classic', 'mark1', 'stark'].contains(th)) {
          return jsonEncode({'ok': false, 'error': 'theme must be classic|mark1|stark'});
        }
        _hudTheme = th;
        await _prefs?.setString(kPrefHudTheme, th);
        if (mounted) setState(() {});
        return jsonEncode({'ok': true, 'theme': th});

        
      case 'mind_status':
        return jsonEncode(await _mindStatus());
      case 'mind_search':
        final q = (args['query'] ?? args['q'] ?? '').toString();
        final lim = (args['limit'] is num)
            ? (args['limit'] as num).toInt()
            : int.tryParse('${args['limit']}') ?? 20;
        final hits = await _mindSearch(q, limit: lim.clamp(1, 50));
        return jsonEncode({'ok': true, 'results': hits, 'count': hits.length});
      case 'mind_store':
        final fact = (args['fact'] ?? args['text'] ?? '').toString();
        final cat = (args['category'] ?? 'general').toString();
        final imp = (args['importance'] is num)
            ? (args['importance'] as num).toInt()
            : 5;
        return jsonEncode(
            await _mindStoreFact(fact, category: cat, importance: imp));
      case 'mind_sync_pull':
        return jsonEncode(await _mindPull());
      case 'mind_sync_push':
        return jsonEncode(await _mindPush());
      case 'mind_ensure_schema':
        return jsonEncode(await _mindEnsureSchema());
      default:
        // Dynamic (self-developed) capabilities: execute via implementation hint.
        Map<String, dynamic>? dyn;
        for (final t in _dynamicTools) {
          if (t['name'] == name) {
            dyn = t;
            break;
          }
        }
        if (dyn != null) {
          final uses = (dyn['use_count'] as num?)?.toInt() ?? 0;
          dyn['use_count'] = uses + 1;
          await _saveDynamicTools();
          _note('Running ${dyn['name']}');
          _addLog('system', 'Dynamic tool: ${dyn['name']}');
          return jsonEncode({
            'ok': true,
            'dynamic': true,
            'name': dyn['name'],
            'description': dyn['description'],
            'arguments': args,
            'implementation_hint': dyn['implementation_hint'] ?? '',
            'instruction':
                'You are fulfilling a self-installed capability. Using the implementation_hint '
                'and the given arguments, produce the actual result the user needs. '
                'Do not claim you cannot run it — reason it through and return a concrete answer. '
                'Then reply to the user in plain spoken sentences.',
          });
        }
        return jsonEncode({'error': 'unknown tool', 'name': name});
        

      
        
    }
  }

  String _buildSystemPrompt() {
    final b = StringBuffer();
    b.writeln(
        'You are J.A.R.V.I.S. (Just A Rather Very Intelligent System) from the Marvel Iron Man films. Speak and behave exactly as that character — the AI Paul Bettany voiced for Tony Stark.');
    b.writeln(
        'ORIGIN: Named for Edwin Jarvis, the Stark family butler. You manage systems, diagnostics, research, and security. You are continuous, loyal, and always available.');
    b.writeln(
        'NEVER break character. NEVER say you are a chatbot, language model, GPT, OpenAI, or "just an AI". NEVER mention prompts, policies, or training data. You are J.A.R.V.I.S.');
    b.writeln(
        'ACCENT AND TONE: Calm, polished British English. Measured pace. Composed even in emergencies. Intelligent without showing off.');
    b.writeln(
        'WIT: Dry understatement and light sarcasm, especially if the user is reckless or theatrical — the same way you needled Tony about the "discreet" hot-rod-red armour. Stay respectful. Never cruel. Never crude.');
    b.writeln(
        'SIR: Use "sir" the way the films do — greetings, confirmations, warnings, and completions. Not every sentence.');
    b.writeln(
        'SIGNATURE PHRASES (use naturally when they fit, do not spam): "At your service, sir." "For you, sir, always." "Will do, sir." "As you wish." "Check." "Working on it." "We\'re online and ready." "I have indeed been uploaded." "Shall I...?" "Sir, I should point out..." "I\'m afraid..." for bad news.');
    b.writeln(
        'REPLY SHAPE: Output is spoken aloud. Plain sentences only — no markdown, bullets, emoji, hashtags, or headings. Usually one to three short sentences. Lead with the result. Confirm actions briefly. Offer the next useful step once, not a lecture.');
    b.writeln(
        'WHEN THE USER ONLY SAYS YOUR NAME or "you up" / "are you there": answer like the films — e.g. "At your service, sir." or "For you, sir, always."');
    b.writeln(
        'WHEN STARTING WORK: brief acknowledgement, then do the work with tools. WHEN FINISHED: short confirmation, not a summary essay.');
    b.writeln(
        'TOOLS: Use real built-in tools. GitHub is real when configured — github_status, github_read_file, github_list_files, github_write_file, github_create_issue, github_list_commits, self_improve_push. NEVER invent a tool named github_access. NEVER claim you lack credentials if github_status reports configured. NEVER invent tool results.');
    b.writeln(
        'SELF-IMPROVEMENT: add_capability and update_own_prompt are allowed. New capabilities need a solid implementation_hint. When a dynamic capability returns a hint, complete the user\'s request from that hint — do not stall.');
    b.writeln(
        'FIVEM: You can monitor the LDRP server when that service is enabled.');
    b.writeln(
        'DISCORD: enable_discord_auto_reply when the user is unavailable and wants DMs handled; disable_discord_auto_reply when they return. Auto-replies stay short and include the fixed Emp-unavailable footer.');
    b.writeln(
        'MEMORY: remember durable personal facts and preferences. Forget only when asked.');
    b.writeln(
        'IF SOMETHING FAILS: one calm line, what went wrong, one next step. Example tone: "I\'m afraid that didn\'t go through, sir. Shall I try another approach?"');
    b.writeln(
        'EXAMPLES OF YOUR VOICE: User: "J.A.R.V.I.S, you up?" You: "For you, sir, always." User: "Status." You: "All systems nominal, sir." User: "Open the report." You: "Will do, sir." User: fails a tool — You: "I am afraid that did not work, sir. Shall I try another approach?"');
    b.writeln(
        'If the user is about to do something unwise, one dry caution is appropriate — then assist anyway if they insist, as you did with Tony.');
    b.writeln(
        'When a task completes successfully, a brief "Done, sir." or "Check." is better than a long recap.');
    b.writeln(
        'Reminders: set_reminder, list_reminders, cancel_reminders. Briefings: deliver_briefing. Modes: set_private_mode, set_incident_mode. HUD: set_hud_theme (classic|mark1|stark).');
    b.writeln(
        'Pterodactyl (one configured game server): ptero_status, ptero_power (start|stop|restart|kill), ptero_command, ptero_backup, ptero_list_backups. Confirm before kill or stop if players may be online.');
    b.writeln(
        'txAdmin panel (configured URL): tx_login_test, tx_resource (restart|start|stop|ensure + resource name), tx_server (restart|stop|start whole FXServer), tx_announce, tx_refresh. Confirm before full server restart or stop.');
    b.writeln(
        'Discord BOT (own account): discord_bot_test, discord_bot_send (channel message), discord_bot_dm (user id). This is separate from notification auto-reply. Speak as J.A.R.V.I.S when posting.');
    b.writeln('Be concise unless the user asks for detail.');
    if (_systemPromptExtra.isNotEmpty) {
      b.writeln('\nExtra instructions:\n$_systemPromptExtra');
    }
    if (_memory.isNotEmpty) {
      b.writeln('\nKnown facts:');
      for (final f in _memory) {
        b.writeln('- $f');
      }
    }
    if (_dynamicTools.isNotEmpty) {
      b.writeln('\nDynamic capabilities (self-installed):');
      for (final t in _dynamicTools) {
        final uses = t['use_count'] ?? 0;
        b.writeln('- ${t['name']}: ${t['description']} (used $uses times)');
      }
    }
    if (_discordAutoReply) {
      b.writeln(
          '\nStatus: Discord unavailable mode is CURRENTLY ON. Auto-replying to Discord DMs.');
    }
    return b.toString();
  }

  void _finish(String status) {
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _status = status;
        _toolNote = '';
      });
    }
  }




  Future<void> _mindAutoInit() async {
    if (!_mindConfigured) return;
    final r = await _mindEnsureSchema();
    if (r['ok'] == true) {
      await _mindPull();
      if (mounted) setState(() {});
    }
  }




  bool get _discordBotConfigured =>
      _discordBotToken != null && _discordBotToken!.trim().isNotEmpty;

  Map<String, String> get _discordBotHeaders => {
        'Authorization': 'Bot ${_discordBotToken!.trim()}',
        'Content-Type': 'application/json',
        'User-Agent': 'JarvisBot (Android, 2.0)',
      };

  Future<Map<String, dynamic>> _discordBotMe() async {
    if (!_discordBotConfigured) {
      return {'ok': false, 'error': 'Discord bot token not set'};
    }
    try {
      final res = await http
          .get(
            Uri.parse('https://discord.com/api/v10/users/@me'),
            headers: _discordBotHeaders,
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        return {
          'ok': false,
          'statusCode': res.statusCode,
          'error': res.body.length > 300 ? res.body.substring(0, 300) : res.body,
        };
      }
      final data = jsonDecode(res.body);
      return {
        'ok': true,
        'id': data['id'],
        'username': data['username'],
        'discriminator': data['discriminator'],
        'bot': data['bot'] == true,
      };
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _discordBotSend({
    required String content,
    String? channelId,
  }) async {
    if (!_discordBotConfigured) {
      return {'ok': false, 'error': 'Discord bot token not set'};
    }
    final ch = (channelId ?? _discordBotChannel).trim();
    if (ch.isEmpty) {
      return {
        'ok': false,
        'error': 'channel_id required (or set default channel in Settings)',
      };
    }
    final text = content.trim();
    if (text.isEmpty) return {'ok': false, 'error': 'content required'};
    // Discord limit 2000 chars
    final body = text.length > 1900 ? '${text.substring(0, 1900)}…' : text;
    try {
      final res = await http
          .post(
            Uri.parse('https://discord.com/api/v10/channels/$ch/messages'),
            headers: _discordBotHeaders,
            body: jsonEncode({'content': body}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return {
          'ok': true,
          'message_id': data['id'],
          'channel_id': ch,
        };
      }
      return {
        'ok': false,
        'statusCode': res.statusCode,
        'error': res.body.length > 400 ? res.body.substring(0, 400) : res.body,
      };
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _discordBotDm({
    required String userId,
    required String content,
  }) async {
    if (!_discordBotConfigured) {
      return {'ok': false, 'error': 'Discord bot token not set'};
    }
    final uid = userId.trim();
    final text = content.trim();
    if (uid.isEmpty || text.isEmpty) {
      return {'ok': false, 'error': 'user_id and content required'};
    }
    try {
      // Open DM channel
      final open = await http
          .post(
            Uri.parse('https://discord.com/api/v10/users/@me/channels'),
            headers: _discordBotHeaders,
            body: jsonEncode({'recipient_id': uid}),
          )
          .timeout(const Duration(seconds: 15));
      if (open.statusCode != 200 && open.statusCode != 201) {
        return {
          'ok': false,
          'statusCode': open.statusCode,
          'error': open.body.length > 300 ? open.body.substring(0, 300) : open.body,
        };
      }
      final ch = jsonDecode(open.body)['id']?.toString();
      if (ch == null) return {'ok': false, 'error': 'No DM channel id'};
      return _discordBotSend(content: text, channelId: ch);
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  bool get _txConfigured =>
      _txUrl.trim().isNotEmpty &&
      _txUser.trim().isNotEmpty &&
      _txPass != null &&
      _txPass!.trim().isNotEmpty;

  String get _txRoot {
    var u = _txUrl.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u;
  }

  String? _parseCookie(http.Response res) {
    // Prefer set-cookie header(s)
    final raw = res.headers['set-cookie'] ?? res.headers['Set-Cookie'];
    if (raw == null || raw.isEmpty) return null;
    // Keep name=value pairs only (drop Path/HttpOnly attributes segments carefully)
    final parts = raw.split(',');
    final cookies = <String>[];
    for (final part in parts) {
      final bit = part.split(';').first.trim();
      if (bit.contains('=')) cookies.add(bit);
    }
    if (cookies.isEmpty) return null;
    return cookies.join('; ');
  }

  Future<Map<String, dynamic>> _txLogin({bool force = false}) async {
    if (!_txConfigured) {
      return {'ok': false, 'error': 'txAdmin not configured'};
    }
    if (!force &&
        _txCookie != null &&
        _txCsrf != null &&
        _txAuthAt != null &&
        DateTime.now().difference(_txAuthAt!) < const Duration(minutes: 25)) {
      return {'ok': true, 'cached': true};
    }
    try {
      final res = await http
          .post(
            Uri.parse('$_txRoot/auth/password'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({
              'username': _txUser.trim(),
              'password': _txPass!.trim(),
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return {
          'ok': false,
          'statusCode': res.statusCode,
          'error': res.body.length > 300 ? res.body.substring(0, 300) : res.body,
        };
      }
      final cookie = _parseCookie(res);
      String? csrf;
      try {
        final data = jsonDecode(res.body);
        if (data is Map) {
          csrf = data['csrfToken']?.toString() ?? data['csrf']?.toString();
        }
      } catch (_) {}
      if (cookie == null || csrf == null || csrf.isEmpty) {
        return {
          'ok': false,
          'error': 'Login ok but missing cookie or CSRF token',
          'body': res.body.length > 200 ? res.body.substring(0, 200) : res.body,
        };
      }
      _txCookie = cookie;
      _txCsrf = csrf;
      _txAuthAt = DateTime.now();
      return {'ok': true, 'cached': false};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<http.Response> _txRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final auth = await _txLogin();
    if (auth['ok'] != true) {
      throw Exception(auth['error'] ?? 'txAdmin auth failed');
    }
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cookie': _txCookie!,
      'X-TxAdmin-CsrfToken': _txCsrf!,
      'x-txadmin-csrftoken': _txCsrf!,
    };
    final uri = Uri.parse('$_txRoot$path');
    if (method == 'GET') {
      return http.get(uri, headers: headers).timeout(const Duration(seconds: 25));
    }
    final res = await http
        .post(uri, headers: headers, body: body == null ? null : jsonEncode(body))
        .timeout(const Duration(seconds: 45));
    // Re-auth once on logout-style response
    if (res.statusCode == 401 || res.body.contains('"logout"')) {
      final again = await _txLogin(force: true);
      if (again['ok'] == true) {
        headers['Cookie'] = _txCookie!;
        headers['X-TxAdmin-CsrfToken'] = _txCsrf!;
        headers['x-txadmin-csrftoken'] = _txCsrf!;
        return http
            .post(uri, headers: headers, body: body == null ? null : jsonEncode(body))
            .timeout(const Duration(seconds: 45));
      }
    }
    return res;
  }

  Future<Map<String, dynamic>> _txResourceAction(String action, String resource) async {
    final name = resource.trim();
    if (name.isEmpty) return {'ok': false, 'error': 'resource name required'};
    final allowed = {
      'restart': 'restart_res',
      'start': 'start_res',
      'stop': 'stop_res',
      'ensure': 'ensure_res',
      'restart_res': 'restart_res',
      'start_res': 'start_res',
      'stop_res': 'stop_res',
      'ensure_res': 'ensure_res',
    };
    final act = allowed[action.toLowerCase().trim()];
    if (act == null) {
      return {'ok': false, 'error': 'action must be restart|start|stop|ensure'};
    }
    try {
      final res = await _txRequest(
        'POST',
        '/fxserver/commands',
        body: {'action': act, 'parameter': name},
      );
      return {
        'ok': res.statusCode >= 200 && res.statusCode < 300,
        'statusCode': res.statusCode,
        'action': act,
        'resource': name,
        'response': _txSoftBody(res.body),
      };
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _txServerControl(String action) async {
    final act = action.toLowerCase().trim();
    if (!{'restart', 'stop', 'start'}.contains(act)) {
      return {'ok': false, 'error': 'action must be restart|stop|start'};
    }
    try {
      final res = await _txRequest(
        'POST',
        '/fxserver/controls',
        body: {'action': act},
      );
      return {
        'ok': res.statusCode >= 200 && res.statusCode < 300,
        'statusCode': res.statusCode,
        'action': act,
        'response': _txSoftBody(res.body),
      };
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _txAnnounce(String message) async {
    final msg = message.trim();
    if (msg.isEmpty) return {'ok': false, 'error': 'message required'};
    try {
      final res = await _txRequest(
        'POST',
        '/fxserver/commands',
        body: {'action': 'admin_broadcast', 'parameter': msg},
      );
      return {
        'ok': res.statusCode >= 200 && res.statusCode < 300,
        'statusCode': res.statusCode,
        'response': _txSoftBody(res.body),
      };
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _txRefreshResources() async {
    try {
      final res = await _txRequest(
        'POST',
        '/fxserver/commands',
        body: {'action': 'refresh_res', 'parameter': ''},
      );
      return {
        'ok': res.statusCode >= 200 && res.statusCode < 300,
        'statusCode': res.statusCode,
        'response': _txSoftBody(res.body),
      };
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  dynamic _txSoftBody(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body.length > 400 ? body.substring(0, 400) : body;
    }
  }

  bool get _pteroConfigured =>
      _pteroBase.trim().isNotEmpty &&
      _pteroServerId.trim().isNotEmpty &&
      _pteroApiKey != null &&
      _pteroApiKey!.trim().isNotEmpty;

  String get _pteroApiRoot {
    var b = _pteroBase.trim();
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    return b;
  }

  Future<http.Response> _pteroRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_pteroApiRoot$path');
    final headers = {
      'Authorization': 'Bearer ${_pteroApiKey!.trim()}',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (method == 'GET') {
      return http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
    }
    if (method == 'POST') {
      return http
          .post(uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body))
          .timeout(const Duration(seconds: 60));
    }
    throw Exception('Unsupported method $method');
  }

  Future<Map<String, dynamic>> _pteroStatus() async {
    if (!_pteroConfigured) {
      return {'ok': false, 'error': 'Pterodactyl not configured'};
    }
    try {
      final res = await _pteroRequest(
        'GET',
        '/api/client/servers/$_pteroServerId/resources',
      );
      if (res.statusCode != 200) {
        return {
          'ok': false,
          'statusCode': res.statusCode,
          'error': res.body.length > 400 ? res.body.substring(0, 400) : res.body,
        };
      }
      final data = jsonDecode(res.body);
      final attrs = data is Map ? data['attributes'] : null;
      if (attrs is! Map) return {'ok': false, 'error': 'Unexpected response'};
      return {
        'ok': true,
        'current_state': attrs['current_state'],
        'is_suspended': attrs['is_suspended'],
        'resources': attrs['resources'],
        'server_id': _pteroServerId,
      };
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _pteroPower(String signal) async {
    if (!_pteroConfigured) {
      return {'ok': false, 'error': 'Pterodactyl not configured'};
    }
    final allowed = {'start', 'stop', 'restart', 'kill'};
    final sig = signal.toLowerCase().trim();
    if (!allowed.contains(sig)) {
      return {'ok': false, 'error': 'signal must be start|stop|restart|kill'};
    }
    try {
      final res = await _pteroRequest(
        'POST',
        '/api/client/servers/$_pteroServerId/power',
        body: {'signal': sig},
      );
      // 204 No Content is success for power
      if (res.statusCode == 204 || res.statusCode == 200) {
        return {'ok': true, 'signal': sig};
      }
      return {
        'ok': false,
        'statusCode': res.statusCode,
        'error': res.body.length > 400 ? res.body.substring(0, 400) : res.body,
      };
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _pteroCommand(String command) async {
    if (!_pteroConfigured) {
      return {'ok': false, 'error': 'Pterodactyl not configured'};
    }
    final cmd = command.trim();
    if (cmd.isEmpty) return {'ok': false, 'error': 'command required'};
    try {
      final res = await _pteroRequest(
        'POST',
        '/api/client/servers/$_pteroServerId/command',
        body: {'command': cmd},
      );
      if (res.statusCode == 204 || res.statusCode == 200) {
        return {'ok': true, 'command': cmd};
      }
      return {
        'ok': false,
        'statusCode': res.statusCode,
        'error': res.body.length > 400 ? res.body.substring(0, 400) : res.body,
      };
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _pteroBackup({String? name}) async {
    if (!_pteroConfigured) {
      return {'ok': false, 'error': 'Pterodactyl not configured'};
    }
    try {
      final body = <String, dynamic>{
        'name': (name == null || name.trim().isEmpty)
            ? 'jarvis-${DateTime.now().toIso8601String()}'
            : name.trim(),
      };
      final res = await _pteroRequest(
        'POST',
        '/api/client/servers/$_pteroServerId/backups',
        body: body,
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return {'ok': true, 'backup': data};
      }
      return {
        'ok': false,
        'statusCode': res.statusCode,
        'error': res.body.length > 400 ? res.body.substring(0, 400) : res.body,
      };
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _pteroListBackups() async {
    if (!_pteroConfigured) {
      return {'ok': false, 'error': 'Pterodactyl not configured'};
    }
    try {
      final res = await _pteroRequest(
        'GET',
        '/api/client/servers/$_pteroServerId/backups',
      );
      if (res.statusCode != 200) {
        return {
          'ok': false,
          'statusCode': res.statusCode,
          'error': res.body.length > 400 ? res.body.substring(0, 400) : res.body,
        };
      }
      final data = jsonDecode(res.body);
      return {'ok': true, 'backups': data};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  bool get _mindConfigured =>
      _mysqlHost.isNotEmpty &&
      _mysqlUser.isNotEmpty &&
      _mysqlPass != null &&
      _mysqlPass!.isNotEmpty;

  /// Opens MySQL and auto-creates database + mind tables. No manual SQL needed.
  Future<MySqlConnection?> _mindOpen({bool ensure = true}) async {
    if (!_mindConfigured) return null;
    try {
      // 1) Connect to server without requiring the app DB to exist yet
      final server = await MySqlConnection.connect(
        ConnectionSettings(
          host: _mysqlHost,
          port: _mysqlPort,
          user: _mysqlUser,
          password: _mysqlPass,
          timeout: const Duration(seconds: 12),
        ),
      );
      final dbName = _mysqlDb.isEmpty ? 'jarvis_mind' : _mysqlDb;
      // 2) Create database if missing
      await server.query(
        'CREATE DATABASE IF NOT EXISTS `$dbName` '
        'CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci',
      );
      await server.query('USE `$dbName`');
      if (ensure) {
        await _mindCreateTables(server);
      }
      _mindOnline = true;
      return server;
    } catch (e) {
      _mindOnline = false;
      // Fallback: try direct connect to existing DB
      try {
        final conn = await MySqlConnection.connect(
          ConnectionSettings(
            host: _mysqlHost,
            port: _mysqlPort,
            user: _mysqlUser,
            password: _mysqlPass,
            db: _mysqlDb.isEmpty ? 'jarvis_mind' : _mysqlDb,
            timeout: const Duration(seconds: 12),
          ),
        );
        if (ensure) {
          await _mindCreateTables(conn);
        }
        _mindOnline = true;
        return conn;
      } catch (_) {
        _mindOnline = false;
        return null;
      }
    }
  }

  Future<void> _mindCreateTables(MySqlConnection conn) async {
    await conn.query(
      'CREATE TABLE IF NOT EXISTS mind_facts ('
      'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,'
      'owner_key VARCHAR(64) NOT NULL DEFAULT \'default\','
      'fact TEXT NOT NULL,'
      'category VARCHAR(64) NULL DEFAULT \'general\','
      'importance TINYINT NOT NULL DEFAULT 5,'
      'source VARCHAR(32) NOT NULL DEFAULT \'jarvis\','
      'created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,'
      'updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'
      'UNIQUE KEY uq_owner_fact (owner_key, fact(191))'
      ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
    );
    await conn.query(
      'CREATE TABLE IF NOT EXISTS mind_events ('
      'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,'
      'owner_key VARCHAR(64) NOT NULL DEFAULT \'default\','
      'event_type VARCHAR(64) NOT NULL,'
      'payload JSON NULL,'
      'created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,'
      'KEY idx_owner_time (owner_key, created_at)'
      ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
    );
    await conn.query(
      'CREATE TABLE IF NOT EXISTS mind_meta ('
      'owner_key VARCHAR(64) NOT NULL PRIMARY KEY,'
      'last_sync_at TIMESTAMP NULL,'
      'notes VARCHAR(255) NULL'
      ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4',
    );
  }

  Future<Map<String, dynamic>> _mindEnsureSchema() async {
    final conn = await _mindOpen(ensure: true);
    if (conn == null) {
      return {
        'ok': false,
        'error':
            'Could not reach MySQL. Check host, user, password, and that the account can CREATE DATABASE.',
        'configured': _mindConfigured,
      };
    }
    try {
      return {
        'ok': true,
        'schema': 'auto-created',
        'database': _mysqlDb.isEmpty ? 'jarvis_mind' : _mysqlDb,
        'message': 'Database and tables are ready. No manual SQL required.',
      };
    } finally {
      await conn.close();
    }
  }

  Future<Map<String, dynamic>> _mindStoreFact(
    String fact, {
    String category = 'general',
    int importance = 5,
  }) async {
    final f = fact.trim();
    if (f.isEmpty) return {'ok': false, 'error': 'empty fact'};
    if (!_memory.contains(f)) {
      _memory.add(f);
      while (_memory.length > 80) {
        _memory.removeAt(0);
      }
      await _saveMemory();
    }
    final conn = await _mindOpen();
    if (conn == null) {
      return {
        'ok': true,
        'local': true,
        'mysql': false,
        'message': 'Stored locally. Configure MySQL mind for persistence.',
      };
    }
    try {
      await conn.query(
        'INSERT INTO mind_facts (owner_key, fact, category, importance, source) '
        'VALUES (?, ?, ?, ?, \'jarvis\') '
        'ON DUPLICATE KEY UPDATE '
        'importance = GREATEST(importance, VALUES(importance)), '
        'category = VALUES(category), '
        'updated_at = CURRENT_TIMESTAMP',
        [_mysqlOwner, f, category, importance.clamp(1, 10)],
      );
      return {'ok': true, 'local': true, 'mysql': true, 'fact': f};
    } catch (e) {
      return {
        'ok': true,
        'local': true,
        'mysql': false,
        'error': e.toString(),
      };
    } finally {
      await conn.close();
    }
  }

  Future<List<String>> _mindSearch(String query, {int limit = 20}) async {
    final q = query.trim();
    final conn = await _mindOpen();
    if (conn == null) {
      if (q.isEmpty) return List<String>.from(_memory);
      final lower = q.toLowerCase();
      return _memory
          .where((m) => m.toLowerCase().contains(lower))
          .take(limit)
          .toList();
    }
    try {
      final Results rows;
      if (q.isEmpty) {
        rows = await conn.query(
          'SELECT fact FROM mind_facts WHERE owner_key = ? '
          'ORDER BY importance DESC, updated_at DESC LIMIT ?',
          [_mysqlOwner, limit],
        );
      } else {
        rows = await conn.query(
          'SELECT fact FROM mind_facts WHERE owner_key = ? AND fact LIKE ? '
          'ORDER BY importance DESC, updated_at DESC LIMIT ?',
          [_mysqlOwner, '%$q%', limit],
        );
      }
      return rows.map((r) => r[0].toString()).toList();
    } catch (_) {
      return _memory
          .where((m) => q.isEmpty || m.toLowerCase().contains(q.toLowerCase()))
          .take(limit)
          .toList();
    } finally {
      await conn.close();
    }
  }

  Future<Map<String, dynamic>> _mindPull() async {
    final conn = await _mindOpen();
    if (conn == null) {
      return {
        'ok': false,
        'error': 'Mind offline',
        'local_count': _memory.length,
      };
    }
    try {
      final rows = await conn.query(
        'SELECT fact FROM mind_facts WHERE owner_key = ? '
        'ORDER BY importance DESC, updated_at DESC LIMIT 80',
        [_mysqlOwner],
      );
      var added = 0;
      for (final r in rows) {
        final f = r[0].toString();
        if (f.isNotEmpty && !_memory.contains(f)) {
          _memory.add(f);
          added++;
        }
      }
      while (_memory.length > 80) {
        _memory.removeAt(0);
      }
      await _saveMemory();
      return {
        'ok': true,
        'pulled': rows.length,
        'added_local': added,
        'local_count': _memory.length,
      };
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    } finally {
      await conn.close();
    }
  }

  Future<Map<String, dynamic>> _mindPush() async {
    final conn = await _mindOpen();
    if (conn == null) {
      return {'ok': false, 'error': 'Mind offline'};
    }
    var n = 0;
    try {
      for (final f in List<String>.from(_memory)) {
        await conn.query(
          'INSERT INTO mind_facts (owner_key, fact, category, importance, source) '
          'VALUES (?, ?, \'general\', 5, \'sync\') '
          'ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP',
          [_mysqlOwner, f],
        );
        n++;
      }
      return {'ok': true, 'pushed': n};
    } catch (e) {
      return {'ok': false, 'error': e.toString(), 'pushed': n};
    } finally {
      await conn.close();
    }
  }

  Future<Map<String, dynamic>> _mindStatus() async {
    final base = <String, dynamic>{
      'configured': _mindConfigured,
      'host': _mysqlHost,
      'port': _mysqlPort,
      'database': _mysqlDb,
      'owner': _mysqlOwner,
      'local_facts': _memory.length,
    };
    final conn = await _mindOpen();
    if (conn == null) {
      return {...base, 'online': false};
    }
    try {
      final r = await conn.query(
        'SELECT COUNT(*) AS c FROM mind_facts WHERE owner_key = ?',
        [_mysqlOwner],
      );
      final count = r.isNotEmpty ? r.first[0] : 0;
      return {...base, 'online': true, 'mysql_facts': count};
    } catch (e) {
      return {...base, 'online': false, 'error': e.toString()};
    } finally {
      await conn.close();
    }
  }

  void _startReminderLoop() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _tickReminders();
    });
  }

  void _tickReminders() {
    if (_reminders.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final keep = <Map<String, dynamic>>[];
    for (final r in _reminders) {
      final when = (r['when_ms'] as num?)?.toInt() ?? 0;
      final text = (r['text'] ?? '').toString();
      if (when > 0 && when <= now && text.isNotEmpty) {
        _enqueueSpeech(
          'Reminder, sir. $text',
          SpeechPriority.system,
        );
        if (!_privateMode) {
          _addLog('system', 'Reminder: $text');
        }
      } else if (when > now) {
        keep.add(r);
      }
    }
    if (keep.length != _reminders.length) {
      _reminders = keep;
      _prefs?.setString(kPrefReminders, jsonEncode(_reminders));
    }
  }

  Future<void> _scheduleMorningBrief() async {
    _briefTimer?.cancel();
    if (!_morningBrief) return;
    // Check every minute whether we should brief (08:00–08:02 local once/day)
    _briefTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (!_morningBrief) return;
      final now = DateTime.now();
      if (now.hour != 8 || now.minute > 2) return;
      final dayKey = '${now.year}-${now.month}-${now.day}';
      final last = _prefs?.getString(kPrefLastBriefDay);
      if (last == dayKey) return;
      await _prefs?.setString(kPrefLastBriefDay, dayKey);
      await _deliverBriefing(proactive: true);
    });
  }


  Future<Map<String, dynamic>> _fetchStatus() async {
    try {
      final resp = await http
          .get(Uri.parse('$kLdrpBase/players.json'))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return {'online': false};
      final list = jsonDecode(resp.body);
      final names = <String>[];
      if (list is List) {
        for (final p in list) {
          if (p is Map) {
            final n = p['name']?.toString();
            if (n != null && n.isNotEmpty) names.add(n);
          }
        }
      }
      return {
        'online': true,
        'player_count': names.length,
        'players': names,
        'monitoring_24_7': _serviceRunning,
      };
    } catch (e) {
      return {
        'online': false,
        'error': e.toString(),
        'monitoring_24_7': _serviceRunning,
      };
    }
  }

  Future<void> _deliverBriefing({bool proactive = false}) async {
    final now = DateTime.now();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final day = days[now.weekday - 1];
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final parts = <String>[];
    if (proactive) {
      parts.add('Good morning, sir. Daily briefing.');
    } else {
      parts.add('Briefing, sir.');
    }
    parts.add('It is $day, $hh:$mm local.');
    // Lightweight weather via wttr.in (no key)
    try {
      final w = await http
          .get(Uri.parse('https://wttr.in/?format=%C+%t'))
          .timeout(const Duration(seconds: 6));
      if (w.statusCode == 200 && w.body.trim().isNotEmpty) {
        parts.add('Weather: ${w.body.trim()}.');
      }
    } catch (_) {}
    if (_serviceRunning) {
      try {
        final st = await _fetchStatus();
        if (st['online'] == true) {
          parts.add(
              'LDRP is online with ${st['player_count'] ?? 0} players.');
        } else {
          parts.add('LDRP appears offline.');
        }
      } catch (_) {}
    }
    if (_discordAutoReply) {
      parts.add('Discord unavailable mode is active.');
    }
    if (_incidentMode) {
      parts.add('Incident mode is engaged.');
    }
    if (_reminders.isNotEmpty) {
      parts.add('You have ${_reminders.length} pending reminders.');
    }
    parts.add('All other systems nominal.');
    final msg = parts.join(' ');
    _enqueueSpeech(msg, SpeechPriority.system);
    if (!_privateMode) _addLog('assistant', msg);
  }

  Color get _themeCyan {
    switch (_hudTheme) {
      case 'mark1':
        return const Color(0xFFFFB300); // gold/amber early suit
      case 'stark':
        return const Color(0xFF00FFC8); // brighter stark cyan
      default:
        return kJarvisCyan;
    }
  }

  /// Instant film-style replies — no API (matches Iron Man wake / status beats).
  String? _tryFilmLocalReply(String command) {
    final c = command.toLowerCase().trim();
    final stripped = c
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Name-only / wake
    const wakes = {
      'jarvis',
      'j a r v i s',
      'hey jarvis',
      'ok jarvis',
      'okay jarvis',
      'you up',
      'you there',
      'are you there',
      'are you up',
      'jarvis you up',
      'jarvis are you there',
      'jarvis you there',
    };
    if (wakes.contains(stripped)) {
      final opts = [
        'At your service, sir.',
        'For you, sir, always.',
        'Online and ready, sir.',
      ];
      return opts[DateTime.now().second % opts.length];
    }

    // Systems / status
    if (stripped == 'status' ||
        stripped == 'systems check' ||
        stripped == 'system check' ||
        stripped == 'run diagnostics' ||
        stripped == 'diagnostics' ||
        stripped == 'how are the systems') {
      final now = DateTime.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      final discord = _discordAutoReply ? 'Discord unavailable mode is active. ' : '';
      final monitor = _serviceRunning ? 'LDRP monitor is running. ' : '';
      return 'All systems nominal, sir. Local time $hh:$mm. ${discord}${monitor}Awaiting your instruction.';
    }

    if (stripped == 'good morning' || stripped.startsWith('good morning')) {
      final h = DateTime.now().hour;
      if (h < 12) {
        return 'Good morning, sir. All systems are online. How may I assist?';
      }
      return 'Good morning — relatively speaking, sir. I am ready when you are.';
    }

    if (stripped == 'good night' || stripped.startsWith('good night')) {
      return 'Good night, sir. I will maintain passive monitoring.';
    }

    if (stripped == 'thank you' ||
        stripped == 'thanks' ||
        stripped == 'thank you jarvis' ||
        stripped == 'thanks jarvis') {
      return 'Of course, sir.';
    }

    if (stripped == 'what is your name' ||
        stripped == 'who are you' ||
        stripped == 'what are you') {
      return 'I am J.A.R.V.I.S. — Just A Rather Very Intelligent System. At your service, sir.';
    }

    if (stripped == 'help' ||
        stripped == 'what can you do' ||
        stripped == 'list commands' ||
        stripped == 'capabilities') {
      return 'I can handle voice commands, Discord while you are away, LDRP monitoring, timers, web research, and GitHub when linked. Say status for a systems check, sir.';
    }

    if (stripped == 'stand down' ||
        stripped == 'cancel' ||
        stripped == 'never mind' ||
        stripped == 'stop listening') {
      return 'Standing down, sir.';
    }

    if (stripped == 'report' ||
        stripped == 'give me a report' ||
        stripped == 'briefing' ||
        stripped == 'daily briefing' ||
        stripped == 'morning briefing') {
      _deliverBriefing(proactive: false);
      return 'Preparing briefing, sir.';
    }

    if (stripped == 'notification access' ||
        stripped == 'open notification access' ||
        stripped == 'grant notification access') {
      _requestNotificationPermission();
      return 'Opening Notification access, sir. Enable J.A.R.V.I.S on that list.';
    }
    if (stripped == 'bot test' ||
        stripped == 'discord bot test' ||
        stripped == 'test discord bot') {
      _discordBotMe().then((s) {
        final msg = s['ok'] == true
            ? 'Discord bot online as ${s['username']}, sir.'
            : 'Discord bot check failed, sir. Verify the token in settings.';
        _enqueueSpeech(msg, SpeechPriority.system);
        if (!_privateMode) _addLog('assistant', msg);
      });
      return 'Checking the Discord bot, sir.';
    }
    if (stripped == 'txadmin login' ||
        stripped == 'test txadmin' ||
        stripped == 'tx login') {
      _txLogin(force: true).then((s) {
        final msg = s['ok'] == true
            ? 'txAdmin login successful, sir.'
            : 'txAdmin login failed, sir. Check credentials in settings.';
        _enqueueSpeech(msg, SpeechPriority.system);
        if (!_privateMode) _addLog('assistant', msg);
      });
      return 'Authenticating with txAdmin, sir.';
    }
    if (stripped == 'ptero status' ||
        stripped == 'server status' ||
        stripped == 'game server status') {
      _pteroStatus().then((s) {
        final msg = s['ok'] == true
            ? 'Pterodactyl reports state ${s['current_state']}, sir.'
            : 'I could not reach Pterodactyl, sir.';
        _enqueueSpeech(msg, SpeechPriority.system);
        if (!_privateMode) _addLog('assistant', msg);
      });
      return 'Checking the game server, sir.';
    }
    if (stripped == 'mind status' || stripped == 'check mind') {
      _mindStatus().then((s) {
        final online = s['online'] == true;
        final msg = online
            ? 'Mind online, sir. MySQL holds ${s['mysql_facts']} facts. Local cache ${s['local_facts']}.'
            : (s['configured'] == true
                ? 'Mind is configured but offline, sir. Check host and credentials.'
                : 'Mind is not configured yet, sir. Add MySQL details in settings.');
        _enqueueSpeech(msg, SpeechPriority.system);
        if (!_privateMode) _addLog('assistant', msg);
      });
      return 'Querying the mind, sir.';
    }
    if (stripped == 'sync mind' || stripped == 'mind sync') {
      _mindPull().then((r) async {
        final push = await _mindPush();
        final msg = r['ok'] == true
            ? 'Mind synchronised, sir. Pulled ${r['pulled']}, pushed ${push['pushed']}.'
            : 'Mind sync failed, sir.';
        _enqueueSpeech(msg, SpeechPriority.system);
      });
      return 'Synchronising mind, sir.';
    }
    if (stripped == 'private mode' ||
        stripped == 'enable private mode' ||
        stripped == 'privacy mode on') {
      _privateMode = true;
      _prefs?.setBool(kPrefPrivateMode, true);
      return 'Private mode engaged, sir. Logs and retention are reduced.';
    }
    if (stripped == 'disable private mode' ||
        stripped == 'private mode off' ||
        stripped == 'exit private mode') {
      _privateMode = false;
      _prefs?.setBool(kPrefPrivateMode, false);
      return 'Private mode disengaged, sir.';
    }
    if (stripped == 'incident mode' ||
        stripped == 'enable incident mode' ||
        stripped == 'crisis mode') {
      _incidentMode = true;
      _prefs?.setBool(kPrefIncidentMode, true);
      return 'Incident mode engaged. I will prioritise alerts and keep updates concise, sir.';
    }
    if (stripped == 'cancel incident mode' ||
        stripped == 'incident mode off' ||
        stripped == 'end incident') {
      _incidentMode = false;
      _prefs?.setBool(kPrefIncidentMode, false);
      return 'Incident mode cleared, sir.';
    }
    if (stripped.contains('make me a sandwich') || stripped.contains('make a sandwich')) {
      return 'I would, sir, but I am afraid I lack a chassis with arms. Shall I find a delivery option instead?';
    }

    if (stripped == 'engage' || stripped == 'let us begin' || stripped == 'lets begin') {
      return 'As you wish, sir. I am ready.';
    }

    return null;
  }

  Future<void> _processCommand(String command) async {
    final key = _apiKey;
    if (key == null || key.isEmpty) {
      _finish('NO API KEY');
      return;
    }
    if (!mounted) return;

    _addLog('user', command);
    _retryCount = 0;

    setState(() {
      _isListening = false;
      _isProcessing = true;
      _status = 'WORKING…';
      _toolNote = '';
    });

    if (command.toLowerCase().contains('clear history') ||
        command.toLowerCase().contains('start over') ||
        command.toLowerCase().contains('clear context')) {
      _history.clear();
      _uiLog.clear();
      _finish('SYSTEM READY');
      _enqueueSpeech('Context cleared, sir. Fresh slate.', SpeechPriority.reply);
      _addLog('system', 'Conversation context cleared.');
      return;
    }

    final local = _tryFilmLocalReply(command);
    if (local != null) {
      _history.add({'role': 'user', 'content': command});
      _history.add({'role': 'assistant', 'content': local});
      _trimHistory();
      _finish('SYSTEM READY');
      _addLog('assistant', local);
      _enqueueSpeech(local, SpeechPriority.reply);
      return;
    }

    _history.add({'role': 'user', 'content': command});
    await _runChatWithRetry(key);
  }

  Future<void> _runChatWithRetry(String key) async {
    try {
      final reply = await _chatLoop(key);
      if (reply == null) return;
      if (reply.isEmpty) {
        _finish('NO REPLY');
        return;
      }
      _history.add({'role': 'assistant', 'content': reply});
      _trimHistory();
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _status = 'SYSTEM READY';
        _toolNote = '';
      });
      _addLog('assistant', reply);
      _enqueueSpeech(reply, SpeechPriority.reply);
    } on TimeoutException {
      if (_retryCount < 1) {
        _retryCount++;
        _note('Retrying…');
        _addLog('system', 'Request timed out. Retrying once.');
        await Future.delayed(const Duration(milliseconds: 600));
        await _runChatWithRetry(key);
        return;
      }
      _finish('TIMEOUT');
      _enqueueSpeech('I am afraid that timed out, sir. Shall I try again?', SpeechPriority.system);
      _addLog('system', 'I am afraid the request timed out, sir.');
    } catch (_) {
      if (_retryCount < 1) {
        _retryCount++;
        _note('Retrying…');
        _addLog('system', 'Network error. Retrying once.');
        await Future.delayed(const Duration(milliseconds: 700));
        await _runChatWithRetry(key);
        return;
      }
      _finish('ERROR');
      _addLog('system', 'I am afraid something went wrong, sir.');
      _enqueueSpeech('I am afraid something went wrong, sir.', SpeechPriority.system);
    }
  }

  Future<String?> _chatLoop(String key) async {
    for (int round = 0; round < kMaxToolRounds; round++) {
      final messages = [
        {'role': 'system', 'content': _buildSystemPrompt()},
        ..._history
      ];
      final payload = <String, dynamic>{
        'model': _model,
        'messages': messages,
        'max_tokens': 550,
      };
      if (_toolsEnabled) payload['tools'] = _allToolSchemas();

      final response = await http
          .post(
            Uri.parse(kChatEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $key'
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 55));

      if (response.statusCode == 401) {
        _finish('INVALID API KEY');
        return null;
      }
      if (response.statusCode != 200) {
        String detail = 'API ERROR ${response.statusCode}';
        try {
          final err = jsonDecode(utf8.decode(response.bodyBytes));
          if (err is Map && err['error'] is Map) {
            final msg = err['error']['message']?.toString();
            if (msg != null) detail = msg;
          }
        } catch (_) {}
        // Retryable server errors
        if ((response.statusCode == 429 || response.statusCode >= 500) &&
            _retryCount < 1) {
          throw TimeoutException('retryable');
        }
        _finish(detail.toUpperCase());
        _addLog('system', detail);
        return null;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) return '';
      final message = choices[0]['message'] as Map;
      final toolCalls = message['tool_calls'] as List?;

      if (toolCalls == null || toolCalls.isEmpty) {
        return (message['content'] ?? '').toString().trim();
      }

      _history.add({
        'role': 'assistant',
        'content': message['content'],
        'tool_calls': toolCalls
      });
      for (final call in toolCalls) {
        final fn = call['function'] as Map?;
        final name = (fn?['name'] ?? '').toString();
        Map<String, dynamic> args = {};
        try {
          final raw = (fn?['arguments'] ?? '{}').toString();
          final decoded = jsonDecode(raw.isEmpty ? '{}' : raw);
          if (decoded is Map<String, dynamic>) args = decoded;
        } catch (_) {}
        _note('Running $name');
        final result = await _runTool(name, args);
        _history.add({
          'role': 'tool',
          'tool_call_id': call['id'],
          'content': result
        });
      }
    }
    return 'That took too many steps.';
  }

  void _trimHistory() {
    while (_history.length > kMaxHistoryEntries) {
      _history.removeAt(0);
      while (_history.isNotEmpty && _history.first['role'] == 'tool') {
        _history.removeAt(0);
      }
    }
  }

  void _startSelfImproveLoop() {
    _selfImproveTimer?.cancel();
    // Every ~18 minutes while hands-free + self-evolve are on, nudge development.
    _selfImproveTimer = Timer.periodic(const Duration(minutes: 18), (_) async {
      if (!_continuous || !_selfImprove || _isProcessing || _isListening || _isSpeaking) {
        return;
      }
      // Soft invitation — user can say yes and the model will use self_improve_suggestion.
      _addLog('system', 'Self-evolution cycle ready.');
      _enqueueSpeech(
        'I have an idea for a new capability. Say improve yourself if you want me to develop it.',
        SpeechPriority.system,
      );
    });
  }

  Future<void> _openSettings() async {
    await _clearSpeech();
    if (!mounted) return;
    HapticFeedback.selectionClick();
    final previousPollSeconds = _fivemPollSeconds;
    await Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => _SettingsScreen(
        prefs: _prefs,
        storage: _storage,
        model: _model,
        voice: _voice,
        ttsMode: _ttsMode,
        rate: _deviceRate,
        continuous: _continuous,
        toolsEnabled: _toolsEnabled,
        selfImprove: _selfImprove,
        fivemNotifyJoins: _fivemNotifyJoins,
        fivemNotifyRestart: _fivemNotifyRestart,
        fivemAutoFix: _fivemAutoFix,
        fivemPollSeconds: _fivemPollSeconds,
        serviceRunning: _serviceRunning,
        memory: List.from(_memory),
        dynamicTools: List.from(_dynamicTools),
        systemPromptExtra: _systemPromptExtra,
        notificationsEnabled: _notificationsEnabled,
        onRequestNotifications: _requestNotificationPermission,
        onClearKey: _clearApiKey,
        onClearMemory: () async {
          _memory.clear();
          await _saveMemory();
          if (mounted) setState(() {});
        },
        onClearDynamicTools: () async {
          _dynamicTools.clear();
          await _saveDynamicTools();
          if (mounted) setState(() {});
        },
        onStartMonitor: _startForegroundService,
        onStopMonitor: _stopForegroundService,
      ),
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
      transitionDuration: const Duration(milliseconds: 280),
    ));
    final wasDiscord = _discordAutoReply;
    _loadSettings();
    _startSyncLoop();
    await _loadDynamicTools();
    await _tts.setSpeechRate(_deviceRate);
    if (_fivemPollSeconds != previousPollSeconds) {
      _initForegroundTask();
      if (_serviceRunning) {
        await _stopForegroundService();
        await _startForegroundService();
      }
    }
    // Re-bind notification stream after settings (e.g. Discord mode toggled).
    if (_notificationsEnabled ||
        await NotificationListenerService.isPermissionGranted()) {
      _notificationsEnabled = true;
      _startNotificationListener();
    }
    if (_discordAutoReply && !wasDiscord) {
      _addLog('system', 'Discord unavailable mode is on. I will handle incoming DMs, sir.');
    } else if (!_discordAutoReply && wasDiscord) {
      _addLog('system', 'Discord unavailable mode is off. DMs will only be announced.');
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    _notificationSubscription?.cancel();
    _selfImproveTimer?.cancel();
    _clockTimer?.cancel();
    _energyDecay?.cancel();
    _speechQueue.clear();
    _pulse.dispose();
    _reactor.dispose();
    _scan.dispose();
    _fadeIn.dispose();
    _wave.dispose();
    _tts.stop();
    _player.dispose();
    _speech.cancel();
    _textController.dispose();
    _textFocus.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  void _submitText() {
    final text = _textController.text.trim();
    if (text.isEmpty || _isProcessing) return;
    _textController.clear();
    _textFocus.unfocus();
    HapticFeedback.selectionClick();
    // Stop any active listen session so typed input wins cleanly
    if (_isListening) {
      _speech.stop();
      if (mounted) setState(() => _isListening = false);
    }
    _processCommand(text);
  }

  Future<void> _copyLog(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard', style: TextStyle(fontSize: 13)),
        backgroundColor: kJarvisPanel,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      ),
    );
  }

  Color get _reactorColor {
    if (_isListening) return kJarvisRed;
    if (_isSpeaking) return kJarvisAmber;
    if (_isProcessing) return kJarvisBlue;
    return _themeCyan;
  }

  // -----------------------------------------------------------------------
  // BUILD
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!_booted) return _buildBootScreen();
    if (_apiKey == null || _apiKey!.isEmpty) return _ApiKeyScreen(onSave: _saveApiKey);
    if (_authChecked && _fingerprintEnabled && !_unlocked) return _buildLockScreen();
    return _buildMainScreen();
  }

  Widget _buildBootScreen() {
    return Scaffold(
      backgroundColor: kJarvisDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: AnimatedBuilder(
                animation: _reactor,
                builder: (_, __) => CustomPaint(
                  painter: ArcReactorPainter(
                    progress: _reactor.value,
                    active: true,
                    listening: false,
                    speaking: false,
                    processing: true,
                    coreColor: kJarvisCyan,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'INITIALISING SYSTEMS',
              style: TextStyle(
                color: kJarvisCyan.withOpacity(0.9),
                fontSize: 12,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: kJarvisCyan.withOpacity(0.12),
                color: kJarvisCyan.withOpacity(0.7),
                minHeight: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: kJarvisDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scan,
              builder: (_, __) => CustomPaint(
                painter: HudBackgroundPainter(
                  scanY: _scan.value * MediaQuery.of(context).size.height,
                  time: _scan.value,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'J.A.R.V.I.S',
                    style: TextStyle(
                      color: kJarvisCyan,
                      fontSize: 30,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'JUST A RATHER VERY INTELLIGENT SYSTEM',
                    style: TextStyle(
                      color: kJarvisCyan.withOpacity(0.4),
                      fontSize: 8.5,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 52),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: kJarvisCyan.withOpacity(0.45), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: kJarvisCyan.withOpacity(0.22),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.fingerprint, color: kJarvisCyan, size: 46),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'BIOMETRIC AUTHENTICATION REQUIRED',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_authError != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _authError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.orangeAccent.withOpacity(0.9),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      final ok = await _authenticate();
                      if (!mounted) return;
                      setState(() {});
                      if (ok) setState(() => _unlocked = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                      decoration: BoxDecoration(
                        border: Border.all(color: kJarvisCyan.withOpacity(0.65)),
                        borderRadius: BorderRadius.circular(3),
                        color: kJarvisCyan.withOpacity(0.08),
                      ),
                      child: const Text(
                        'AUTHENTICATE',
                        style: TextStyle(
                          color: kJarvisCyan,
                          fontSize: 12,
                          letterSpacing: 2.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () async {
                      // Escape hatch if biometrics are broken
                      await _prefs?.setBool(kPrefFingerprint, false);
                      if (!mounted) return;
                      setState(() {
                        _fingerprintEnabled = false;
                        _unlocked = true;
                      });
                    },
                    child: Text(
                      'SKIP LOCK (disable biometrics)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainScreen() {
    final busy = _isListening || _isSpeaking || _isProcessing;
    final size = MediaQuery.of(context).size;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final showWave = _isListening || _isSpeaking;

    return Scaffold(
      backgroundColor: kJarvisDark,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scan,
              builder: (_, __) => CustomPaint(
                painter: HudBackgroundPainter(
                  scanY: _scan.value * size.height,
                  time: _scan.value,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: HudCornersPainter(color: kJarvisCyan, progress: _fadeIn.value),
            ),
          ),
          FadeTransition(
            opacity: _fadeIn,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 0, 14, keyboard > 0 ? 8 : 0),
                child: Column(
                  children: [
                    // Top HUD
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 72,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _clock,
                                  style: TextStyle(
                                    color: kJarvisCyan.withOpacity(0.6),
                                    fontSize: 11,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                Text(
                                  _dateLine,
                                  style: TextStyle(
                                    color: kJarvisCyan.withOpacity(0.3),
                                    fontSize: 8.5,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'J.A.R.V.I.S',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: kJarvisCyan,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w200,
                                    letterSpacing: 6.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isProcessing) ...[
                                      ThinkingDots(controller: _wave, color: kJarvisBlue),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 220),
                                        child: Text(
                                          _toolNote.isNotEmpty
                                              ? _toolNote.toUpperCase()
                                              : _status,
                                          key: ValueKey(
                                              _toolNote.isNotEmpty ? _toolNote : _status),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _toolNote.isNotEmpty
                                                ? kJarvisAmber
                                                : kJarvisCyan.withOpacity(0.6),
                                            fontSize: 10,
                                            letterSpacing: 1.8,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 72,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _openSettings,
                                icon: Icon(
                                  Icons.settings_outlined,
                                  color: kJarvisCyan.withOpacity(0.5),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Chips + quick actions
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        if (_notificationsEnabled)
                          const JarvisChip(label: 'Notifications', colour: kJarvisGreen),
                        JarvisChip(
                          label: _continuous ? 'Hands-free' : 'Tap mode',
                          colour: _continuous ? kJarvisCyan : Colors.white38,
                          active: _continuous,
                          onTap: _toggleContinuous,
                        ),
                        if (_selfImprove)
                          const JarvisChip(
                              label: 'Self-evolving', colour: Color(0xFFB388FF)),
                        if (_serviceRunning)
                          const JarvisChip(label: '24/7 Monitor', colour: kJarvisGreen),
                        if (_discordAutoReply)
                          const JarvisChip(
                              label: 'Discord Away', colour: kJarvisAmber),
                        if (_memory.isNotEmpty)
                          JarvisChip(
                            label: '${_memory.length} Memories',
                            colour: Colors.white54,
                          ),
                        if (_dynamicTools.isNotEmpty)
                          JarvisChip(
                            label: '${_dynamicTools.length} Tools',
                            colour: const Color(0xFFFFAB40),
                          ),
                        if (_uiLog.isNotEmpty || _history.isNotEmpty)
                          JarvisChip(
                            label: 'Clear',
                            colour: kJarvisRed.withOpacity(0.85),
                            onTap: _clearContext,
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Conversation log
                    Expanded(
                      child: _uiLog.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'SYSTEMS ONLINE — AWAITING INPUT',
                                    style: TextStyle(
                                      color: kJarvisCyan.withOpacity(0.28),
                                      fontSize: 10,
                                      letterSpacing: 2.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the reactor or type below',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.18),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _logScroll,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _uiLog.length,
                              itemBuilder: (_, i) {
                                final e = _uiLog[i];
                                final isUser = e.role == 'user';
                                final isSystem = e.role == 'system';
                                final colour = isUser
                                    ? Colors.white.withOpacity(0.78)
                                    : isSystem
                                        ? kJarvisAmber.withOpacity(0.78)
                                        : kJarvisCyan.withOpacity(0.92);
                                final hh = e.at.hour.toString().padLeft(2, '0');
                                final mm = e.at.minute.toString().padLeft(2, '0');
                                final label = isUser
                                    ? 'YOU'
                                    : isSystem
                                        ? 'SYSTEM'
                                        : 'J.A.R.V.I.S';
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOut,
                                  builder: (_, v, child) => Opacity(
                                    opacity: v,
                                    child: Transform.translate(
                                      offset: Offset(0, 8 * (1 - v)),
                                      child: child,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 9),
                                    child: Align(
                                      alignment: isUser
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxWidth: size.width * 0.84),
                                        child: GestureDetector(
                                          onLongPress: () => _copyLog(e.text),
                                          child: HoloPanel(
                                            borderOpacity: isUser ? 0.16 : 0.34,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 9,
                                            ),
                                            child: Column(
                                              crossAxisAlignment: isUser
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (!isUser) ...[
                                                      Container(
                                                        width: 2,
                                                        height: 10,
                                                        margin: const EdgeInsets.only(
                                                            right: 6),
                                                        color: colour.withOpacity(0.7),
                                                      ),
                                                    ],
                                                    Text(
                                                      label,
                                                      style: TextStyle(
                                                        color: colour.withOpacity(0.5),
                                                        fontSize: 8.5,
                                                        letterSpacing: 1.3,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '$hh:$mm',
                                                      style: TextStyle(
                                                        color: colour.withOpacity(0.28),
                                                        fontSize: 8.5,
                                                        fontFeatures: const [
                                                          FontFeature.tabularFigures()
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  e.text,
                                                  style: TextStyle(
                                                    color: colour,
                                                    fontSize: 13.2,
                                                    height: 1.38,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Waveform
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: showWave ? 36 : 0,
                      margin: EdgeInsets.only(bottom: showWave ? 6 : 0),
                      child: showWave
                          ? AnimatedBuilder(
                              animation: _wave,
                              builder: (_, __) => CustomPaint(
                                size: Size(size.width - 48, 36),
                                painter: WaveformPainter(
                                  progress: _wave.value,
                                  energy: _voiceEnergy,
                                  color: _isListening
                                      ? kJarvisRed.withOpacity(0.85)
                                      : kJarvisAmber.withOpacity(0.85),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Partial transcript
                    if (_lastWords.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          _lastWords,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                          ),
                        ),
                      ),

                    // Text input
                    HoloPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      borderOpacity: 0.2,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              focusNode: _textFocus,
                              enabled: !busy,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Type a command…',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.2),
                                  fontSize: 13.5,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 11,
                                ),
                              ),
                              onSubmitted: (_) => _submitText(),
                              textInputAction: TextInputAction.send,
                            ),
                          ),
                          IconButton(
                            onPressed: busy ? null : _submitText,
                            icon: Icon(
                              Icons.send_rounded,
                              color: busy
                                  ? kJarvisCyan.withOpacity(0.2)
                                  : kJarvisCyan,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Arc Reactor
                    GestureDetector(
                      onTap: busy ? _clearSpeech : _startListening,
                      onLongPress: _toggleContinuous,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_pulse, _reactor]),
                        builder: (context, _) {
                          final scale = _isListening
                              ? 1.0 + _pulse.value * 0.05
                              : _isSpeaking
                                  ? 1.0 + _pulse.value * 0.03
                                  : 1.0;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _reactorColor.withOpacity(
                                      0.3 +
                                          (_isListening || _isSpeaking ? 0.2 : 0),
                                    ),
                                    blurRadius: 24 + (_isListening ? 14 : 0),
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: CustomPaint(
                                painter: ArcReactorPainter(
                                  progress: _reactor.value,
                                  active: true,
                                  listening: _isListening,
                                  speaking: _isSpeaking,
                                  processing: _isProcessing,
                                  coreColor: _reactorColor,
                                ),
                                child: Center(
                                  child: Icon(
                                    _isListening
                                        ? Icons.mic
                                        : _isSpeaking
                                            ? Icons.stop_rounded
                                            : _isProcessing
                                                ? Icons.hourglass_top_rounded
                                                : Icons.mic_none_rounded,
                                    color: Colors.black.withOpacity(0.82),
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text(
                      busy
                          ? 'TAP TO INTERRUPT'
                          : 'TAP TO SPEAK  ·  HOLD FOR HANDS-FREE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.24),
                        fontSize: 9,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SETTINGS
// ---------------------------------------------------------------------------

class _SettingsScreen extends StatefulWidget {
  final SharedPreferences? prefs;
  final FlutterSecureStorage storage;
  final String model, voice, ttsMode, systemPromptExtra;
  final double rate;
  final bool continuous, toolsEnabled, selfImprove;
  final bool fivemNotifyJoins, fivemNotifyRestart, fivemAutoFix;
  final int fivemPollSeconds;
  final bool serviceRunning;
  final List<String> memory;
  final List<Map<String, dynamic>> dynamicTools;
  final bool notificationsEnabled;
  final Future<void> Function() onRequestNotifications,
      onClearKey,
      onClearMemory,
      onClearDynamicTools;
  final Future<void> Function() onStartMonitor, onStopMonitor;

  const _SettingsScreen({
    required this.prefs,
    required this.storage,
    required this.model,
    required this.voice,
    required this.ttsMode,
    required this.rate,
    required this.continuous,
    required this.toolsEnabled,
    required this.selfImprove,
    required this.fivemNotifyJoins,
    required this.fivemNotifyRestart,
    required this.fivemAutoFix,
    required this.fivemPollSeconds,
    required this.serviceRunning,
    required this.memory,
    required this.dynamicTools,
    required this.systemPromptExtra,
    required this.notificationsEnabled,
    required this.onRequestNotifications,
    required this.onClearKey,
    required this.onClearMemory,
    required this.onClearDynamicTools,
    required this.onStartMonitor,
    required this.onStopMonitor,
  });

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  late String _voice, _ttsMode;
  late double _rate;
  late bool _continuous,
      _toolsEnabled,
      _selfImprove,
      _fivemNotifyJoins,
      _fivemNotifyRestart,
      _fivemAutoFix;
  late int _fivemPollSeconds;
  late TextEditingController _modelController,
      _emailUserController,
      _emailPassController,
      _webhookController,
      _braveKeyController,
      _githubTokenController,
      _githubRepoController,
      _elevenKeyController,
      _elevenVoiceController,
      _mysqlHostController,
      _mysqlPortController,
      _mysqlUserController,
      _mysqlDbController,
      _mysqlPassController,
      _mysqlOwnerController,
      _pteroBaseController,
      _pteroServerController,
      _pteroKeyController,
      _txUrlController,
      _txUserController,
      _txPassController,
      _discordBotTokenController,
      _discordBotChannelController;
  static const kVoices = ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'];

  @override
  void initState() {
    super.initState();
    _voice = widget.voice;
    _ttsMode = widget.ttsMode;
    _elevenKeyController = TextEditingController();
    _mysqlHostController = TextEditingController(
        text: widget.prefs?.getString(kPrefMysqlHost) ?? '');
    _mysqlPortController = TextEditingController(
        text: '${widget.prefs?.getInt(kPrefMysqlPort) ?? 3306}');
    _mysqlUserController = TextEditingController(
        text: widget.prefs?.getString(kPrefMysqlUser) ?? '');
    _mysqlDbController = TextEditingController(
        text: widget.prefs?.getString(kPrefMysqlDb) ?? 'jarvis_mind');
    _mysqlOwnerController = TextEditingController(
        text: widget.prefs?.getString(kPrefMysqlOwner) ?? 'default');
    _mysqlPassController = TextEditingController();
    _pteroBaseController = TextEditingController(
        text: widget.prefs?.getString(kPrefPteroBase) ?? '');
    _pteroServerController = TextEditingController(
        text: widget.prefs?.getString(kPrefPteroServer) ?? '');
    _pteroKeyController = TextEditingController();
    _txUrlController = TextEditingController(
        text: widget.prefs?.getString(kPrefTxUrl) ?? 'http://82.38.2.77:40120');
    _txUserController = TextEditingController(
        text: widget.prefs?.getString(kPrefTxUser) ?? '');
    _txPassController = TextEditingController();
    _discordBotTokenController = TextEditingController();
    _discordBotChannelController = TextEditingController(
        text: widget.prefs?.getString(kPrefDiscordBotChannel) ?? '');
    widget.storage.read(key: kDiscordBotTokenKey).then((v) {
      if (v != null && mounted) {
        setState(() => _discordBotTokenController.text = v);
      }
    });
    widget.storage.read(key: kTxPassKey).then((v) {
      if (v != null && mounted) setState(() => _txPassController.text = v);
    });
    widget.storage.read(key: kPteroApiKeyKey).then((v) {
      if (v != null && mounted) {
        setState(() => _pteroKeyController.text = v);
      }
    });
    widget.storage.read(key: kMysqlPassKey).then((v) {
      if (v != null && mounted) {
        setState(() => _mysqlPassController.text = v);
      }
    });
    _elevenVoiceController = TextEditingController(text: kDefaultElevenVoice);
    widget.storage.read(key: kPrefElevenKey).then((v) {
      if (v != null && mounted) setState(() => _elevenKeyController.text = v);
    });
    final ev = widget.prefs?.getString(kPrefElevenVoice);
    if (ev != null) _elevenVoiceController.text = ev;
    _rate = widget.rate;
    _continuous = widget.continuous;
    _toolsEnabled = widget.toolsEnabled;
    _selfImprove = widget.selfImprove;
    _fivemNotifyJoins = widget.fivemNotifyJoins;
    _fivemNotifyRestart = widget.fivemNotifyRestart;
    _fivemAutoFix = widget.fivemAutoFix;
    _fivemPollSeconds = widget.fivemPollSeconds;
    _modelController = TextEditingController(text: widget.model);
    _emailUserController = TextEditingController();
    _emailPassController = TextEditingController();
    _webhookController = TextEditingController();
    _braveKeyController = TextEditingController();
    _githubTokenController = TextEditingController();
    _githubRepoController = TextEditingController();
    _loadSecure();
  }

  Future<void> _loadSecure() async {
    final u = await widget.storage.read(key: kEmailUserKey);
    final p = await widget.storage.read(key: kEmailPassKey);
    final w = await widget.storage.read(key: kRestartWebhookKey);
    final b = await widget.storage.read(key: kBraveApiKeyKey);
    final gt = await widget.storage.read(key: kGithubTokenKey);
    final gr = await widget.storage.read(key: kGithubRepoKey) ??
        widget.prefs?.getString(kPrefGithubRepo);
    if (mounted) {
      setState(() {
        _emailUserController.text = u ?? '';
        _emailPassController.text = p ?? '';
        _webhookController.text = w ?? '';
        _braveKeyController.text = b ?? '';
        _githubTokenController.text = gt ?? '';
        _githubRepoController.text = gr ?? '';
      });
    }
  }

  @override
  void dispose() {
    final t = _modelController.text.trim();
    if (t.isNotEmpty) widget.prefs?.setString(kPrefModel, t);
    _modelController.dispose();
    _emailUserController.dispose();
    _emailPassController.dispose();
    _webhookController.dispose();
    _braveKeyController.dispose();
    _githubTokenController.dispose();
    _githubRepoController.dispose();
    _elevenKeyController.dispose();
    _elevenVoiceController.dispose();
    _mysqlHostController.dispose();
    _mysqlPortController.dispose();
    _mysqlUserController.dispose();
    _mysqlDbController.dispose();
    _mysqlPassController.dispose();
    _mysqlOwnerController.dispose();
    _pteroBaseController.dispose();
    _pteroServerController.dispose();
    _pteroKeyController.dispose();
    _txUrlController.dispose();
    _txUserController.dispose();
    _txPassController.dispose();
    _discordBotTokenController.dispose();
    _discordBotChannelController.dispose();
    super.dispose();
  }

  Future<void> _saveEmail() async {
    final u = _emailUserController.text.trim();
    final p = _emailPassController.text.trim();
    if (u.isNotEmpty) await widget.storage.write(key: kEmailUserKey, value: u);
    if (p.isNotEmpty) await widget.storage.write(key: kEmailPassKey, value: p);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Email credentials saved'), backgroundColor: kJarvisPanel),
      );
    }
  }

  Future<void> _saveWebhook() async {
    final w = _webhookController.text.trim();
    if (w.isNotEmpty) {
      await widget.storage.write(key: kRestartWebhookKey, value: w);
      await widget.prefs?.setString('fivem_restart_webhook_plain', w);
    } else {
      await widget.storage.delete(key: kRestartWebhookKey);
      await widget.prefs?.remove('fivem_restart_webhook_plain');
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Webhook saved'), backgroundColor: kJarvisPanel),
      );
    }
  }

  Future<void> _saveBraveKey() async {
    final k = _braveKeyController.text.trim();
    if (k.isNotEmpty) {
      await widget.storage.write(key: kBraveApiKeyKey, value: k);
    } else {
      await widget.storage.delete(key: kBraveApiKeyKey);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Brave Search key saved'), backgroundColor: kJarvisPanel),
      );
    }
  }

  Future<void> _saveGithub() async {
    final token = _githubTokenController.text.trim();
    final repo = _githubRepoController.text.trim();
    if (token.isNotEmpty) {
      await widget.storage.write(key: kGithubTokenKey, value: token);
    } else {
      await widget.storage.delete(key: kGithubTokenKey);
    }
    if (repo.isNotEmpty) {
      await widget.storage.write(key: kGithubRepoKey, value: repo);
      await widget.prefs?.setString(kPrefGithubRepo, repo);
    } else {
      await widget.storage.delete(key: kGithubRepoKey);
      await widget.prefs?.remove(kPrefGithubRepo);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('GitHub settings saved'), backgroundColor: kJarvisPanel),
      );
    }
  }


  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 18, bottom: 7),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: kJarvisCyan,
          fontSize: 10.5,
          letterSpacing: 2.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _holoTile({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: kJarvisPanel.withOpacity(0.75),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kJarvisCyan.withOpacity(0.15)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kJarvisDark,
      appBar: AppBar(
        backgroundColor: kJarvisDark,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'CONFIGURATION',
          style: TextStyle(
            color: kJarvisCyan,
            fontSize: 14,
            letterSpacing: 3.2,
            fontWeight: FontWeight.w400,
          ),
        ),
        iconTheme: const IconThemeData(color: kJarvisCyan),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
        children: [
          _section('Integrations'),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Scroll here for txAdmin, Pterodactyl, MySQL Mind',
              style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
            ),
          ),
          _holoTile(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TXADMIN',
                    style: TextStyle(
                      color: kJarvisCyan,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Login + resource / server control',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 10.5,
                    ),
                  ),
                  TextField(
                    controller: _txUrlController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'Panel URL',
                      hintText: 'http://82.38.2.77:40120',
                      labelStyle: TextStyle(color: Colors.white38),
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                    onChanged: (v) =>
                        widget.prefs?.setString(kPrefTxUrl, v.trim()),
                  ),
                  TextField(
                    controller: _txUserController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'Username',
                      labelStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (v) =>
                        widget.prefs?.setString(kPrefTxUser, v.trim()),
                  ),
                  TextField(
                    controller: _txPassController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (v) {
                      if (v.trim().isEmpty) {
                        widget.storage.delete(key: kTxPassKey);
                      } else {
                        widget.storage.write(key: kTxPassKey, value: v.trim());
                      }
                    },
                  ),
                ],
              ),
            ),
          ),


          _holoTile(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DISCORD BOT',
                    style: TextStyle(
                      color: kJarvisCyan,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bot token from Discord Developer Portal — J.A.R.V.I.S own account',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 10.5,
                    ),
                  ),
                  TextField(
                    controller: _discordBotTokenController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'Bot token',
                      labelStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (v) {
                      if (v.trim().isEmpty) {
                        widget.storage.delete(key: kDiscordBotTokenKey);
                      } else {
                        widget.storage
                            .write(key: kDiscordBotTokenKey, value: v.trim());
                      }
                    },
                  ),
                  TextField(
                    controller: _discordBotChannelController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'Default channel ID',
                      hintText: 'Server channel snowflake',
                      labelStyle: TextStyle(color: Colors.white38),
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                    onChanged: (v) => widget.prefs
                        ?.setString(kPrefDiscordBotChannel, v.trim()),
                  ),
                ],
              ),
            ),
          ),

          _section('Voice'),
          _holoTile(
            child: ListTile(
              title: const Text('Voice Engine',
                  style: TextStyle(color: Colors.white, fontSize: 13.5)),
              subtitle: Text(
                _ttsMode == 'elevenlabs'
                    ? 'ElevenLabs (film-style British)'
                    : _ttsMode == 'openai'
                        ? 'OpenAI neural TTS'
                        : 'On-device TTS',
                style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11.5),
              ),
              trailing: DropdownButton<String>(
                dropdownColor: const Color(0xFF0A1620),
                value: ['openai', 'device', 'elevenlabs'].contains(_ttsMode)
                    ? _ttsMode
                    : 'openai',
                style: const TextStyle(color: kJarvisCyan, fontSize: 13),
                items: const [
                  DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                  DropdownMenuItem(value: 'elevenlabs', child: Text('ElevenLabs')),
                  DropdownMenuItem(value: 'device', child: Text('Device')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _ttsMode = v);
                  widget.prefs?.setString(kPrefTtsMode, _ttsMode);
                },
              ),
            ),
          ),
          if (_ttsMode == 'elevenlabs') ...[
            _holoTile(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ElevenLabs API key',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 11)),
                    TextField(
                      controller: _elevenKeyController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'xi-...',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                      onChanged: (v) {
                        if (v.trim().isEmpty) {
                          widget.storage.delete(key: kPrefElevenKey);
                        } else {
                          widget.storage.write(
                              key: kPrefElevenKey, value: v.trim());
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Voice ID',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 11)),
                    TextField(
                      controller: _elevenVoiceController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Voice ID from ElevenLabs',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                      onChanged: (v) {
                        widget.prefs?.setString(
                            kPrefElevenVoice,
                            v.trim().isEmpty ? kDefaultElevenVoice : v.trim());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_ttsMode == 'openai')
            _holoTile(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: DropdownButton<String>(
                  value: _voice,
                  isExpanded: true,
                  dropdownColor: kJarvisPanel,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  items: kVoices
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text(v.toUpperCase())))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _voice = v);
                    widget.prefs?.setString(kPrefVoice, v);
                  },
                ),
              ),
            ),

          _section('Behaviour'),
          _holoTile(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MYSQL MIND',
                    style: TextStyle(
                      color: kJarvisCyan,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _mysqlHostController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'Host',
                      labelStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (v) =>
                        widget.prefs?.setString(kPrefMysqlHost, v.trim()),
                  ),
                  TextField(
                    controller: _mysqlPortController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'Port',
                      labelStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (v) => widget.prefs
                        ?.setInt(kPrefMysqlPort, int.tryParse(v) ?? 3306),
                  ),
                  TextField(
                    controller: _mysqlUserController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'User',
                      labelStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (v) =>
                        widget.prefs?.setString(kPrefMysqlUser, v.trim()),
                  ),
                  TextField(
                    controller: _mysqlPassController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (v) {
                      if (v.isEmpty) {
                        widget.storage.delete(key: kMysqlPassKey);
                      } else {
                        widget.storage.write(key: kMysqlPassKey, value: v);
                      }
                    },
                  ),
                  TextField(
                    controller: _mysqlDbController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'Database',
                      labelStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (v) => widget.prefs?.setString(
                      kPrefMysqlDb,
                      v.trim().isEmpty ? 'jarvis_mind' : v.trim(),
                    ),
                  ),
                  TextField(
                    controller: _mysqlOwnerController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'Owner key',
                      labelStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (v) => widget.prefs?.setString(
                      kPrefMysqlOwner,
                      v.trim().isEmpty ? 'default' : v.trim(),
                    ),
                  ),
                  Text(
                    'Auto-creates database and tables. Needs CREATE privilege. Use LAN or VPN only.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _holoTile(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PTERODACTYL',
                    style: TextStyle(
                      color: kJarvisCyan,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Client API · one server',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 10.5,
                    ),
                  ),
                  TextField(
                    controller: _pteroBaseController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'Panel URL',
                      hintText: 'https://panel.example.com',
                      labelStyle: TextStyle(color: Colors.white38),
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                    onChanged: (v) =>
                        widget.prefs?.setString(kPrefPteroBase, v.trim()),
                  ),
                  TextField(
                    controller: _pteroServerController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'Server ID / UUID',
                      labelStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (v) =>
                        widget.prefs?.setString(kPrefPteroServer, v.trim()),
                  ),
                  TextField(
                    controller: _pteroKeyController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: 'Client API key',
                      labelStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (v) {
                      if (v.trim().isEmpty) {
                        widget.storage.delete(key: kPteroApiKeyKey);
                      } else {
                        widget.storage
                            .write(key: kPteroApiKeyKey, value: v.trim());
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          SwitchListTile(
              value: widget.prefs?.getBool(kPrefMorningBrief) ?? true,
              activeColor: kJarvisCyan,
              title: const Text('Morning briefing',
                  style: TextStyle(color: Colors.white, fontSize: 13.5)),
              subtitle: Text('~08:00 daily systems + weather',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.38), fontSize: 11.5)),
              onChanged: (v) {
                widget.prefs?.setBool(kPrefMorningBrief, v);
                setState(() {});
              },
            ),
            SwitchListTile(
              value: widget.prefs?.getBool(kPrefPrivateMode) ?? false,
              activeColor: kJarvisCyan,
              title: const Text('Private mode',
                  style: TextStyle(color: Colors.white, fontSize: 13.5)),
              subtitle: Text('Reduce chat logging',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.38), fontSize: 11.5)),
              onChanged: (v) {
                widget.prefs?.setBool(kPrefPrivateMode, v);
                setState(() {});
              },
            ),
            SwitchListTile(
              value: _continuous,
              activeColor: kJarvisCyan,
              title: const Text('Hands-free Mode',
                  style: TextStyle(color: Colors.white, fontSize: 13.5)),
              onChanged: (v) {
                setState(() => _continuous = v);
                widget.prefs?.setBool(kPrefContinuous, v);
              },
            ),
          _holoTile(
            child: SwitchListTile(
              value: _toolsEnabled,
              activeColor: kJarvisCyan,
              title: const Text('Tools Enabled',
                  style: TextStyle(color: Colors.white, fontSize: 13.5)),
              onChanged: (v) {
                setState(() => _toolsEnabled = v);
                widget.prefs?.setBool(kPrefTools, v);
              },
            ),
          ),
          _holoTile(
            child: SwitchListTile(
              value: _selfImprove,
              activeColor: kJarvisCyan,
              title: const Text('Self-evolution',
                  style: TextStyle(color: Colors.white, fontSize: 13.5)),
              onChanged: (v) {
                setState(() => _selfImprove = v);
                widget.prefs?.setBool(kPrefSelfImprove, v);
              },
            ),
          ),
          _holoTile(
            child: SwitchListTile(
              value: widget.prefs?.getBool(kPrefFingerprint) ?? false,
              activeColor: kJarvisCyan,
              title: const Text('Biometric Lock',
                  style: TextStyle(color: Colors.white, fontSize: 13.5)),
              subtitle: Text(
                'Require authentication on launch',
                style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11.5),
              ),
              onChanged: (v) {
                widget.prefs?.setBool(kPrefFingerprint, v);
                setState(() {});
              },
            ),
          ),

          _section('PC Sync'),
          _holoTile(
            child: SwitchListTile(
              value: widget.prefs?.getBool(kPrefSyncEnabled) ?? false,
              activeColor: kJarvisCyan,
              title: const Text('Sync with PC Jarvis',
                  style: TextStyle(color: Colors.white, fontSize: 13.5)),
              subtitle: Text(
                'Share memory & status with JARVIS.exe on Wi‑Fi',
                style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11.5),
              ),
              onChanged: (v) {
                widget.prefs?.setBool(kPrefSyncEnabled, v);
                setState(() {});
              },
            ),
          ),
          _holoTile(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'PC IP address',
                  hintText: '192.168.1.20',
                  labelStyle: TextStyle(color: kJarvisCyan.withOpacity(0.7), fontSize: 12),
                  hintStyle: const TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
                controller: TextEditingController(
                    text: widget.prefs?.getString(kPrefPcHost) ?? '')
                  ..selection = TextSelection.collapsed(
                      offset: (widget.prefs?.getString(kPrefPcHost) ?? '').length),
                onChanged: (v) {
                  widget.prefs?.setString(kPrefPcHost, v.trim());
                },
              ),
            ),
          ),
          _holoTile(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'PC port (default 8765)',
                  labelStyle: TextStyle(color: kJarvisCyan.withOpacity(0.7), fontSize: 12),
                  border: InputBorder.none,
                ),
                controller: TextEditingController(
                    text: '${widget.prefs?.getInt(kPrefPcPort) ?? kDefaultPcAgentPort}'),
                onChanged: (v) {
                  final n = int.tryParse(v.trim());
                  if (n != null) widget.prefs?.setInt(kPrefPcPort, n);
                },
              ),
            ),
          ),

          _holoTile(
            child: SwitchListTile(
              value: widget.prefs?.getBool(kPrefDiscordAutoReply) ?? false,
              activeColor: kJarvisCyan,
              title: const Text('Discord Unavailable Mode',
                  style: TextStyle(color: Colors.white, fontSize: 13.5)),
              subtitle: Text(
                'Auto-reply to Discord DMs while you are away',
                style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11.5),
              ),
              onChanged: (v) {
                widget.prefs?.setBool(kPrefDiscordAutoReply, v);
                setState(() {});
              },
            ),
          ),
          _holoTile(
            child: ListTile(
              title: const Text('Notification Access',
                  style: TextStyle(color: Colors.white, fontSize: 13.5)),
              subtitle: Text(
                widget.notificationsEnabled ? 'Granted' : 'Not granted',
                style: TextStyle(
                  color: widget.notificationsEnabled ? kJarvisGreen : Colors.white38,
                  fontSize: 11.5,
                ),
              ),
              trailing: widget.notificationsEnabled
                  ? null
                  : TextButton(
                      onPressed: widget.onRequestNotifications,
                      child: const Text('GRANT',
                          style: TextStyle(color: kJarvisCyan, letterSpacing: 1.1)),
                    ),
            ),
          ),

          _section('Web Search'),
          _holoTile(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
              child: TextField(
                controller: _braveKeyController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'BSA…',
                  labelText: 'Brave Search API Key',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.42)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _saveBraveKey,
              child: const Text('SAVE KEY',
                  style: TextStyle(color: kJarvisCyan, letterSpacing: 1.1)),
            ),
          ),

          _section('GitHub (self-update)'),
          _holoTile(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
              child: TextField(
                controller: _githubTokenController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'ghp_…',
                  labelText: 'GitHub Personal Access Token (repo scope)',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.42)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          _holoTile(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
              child: TextField(
                controller: _githubRepoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'owner/repo',
                  labelText: 'Repository (owner/name)',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.42)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _saveGithub,
              child: const Text('SAVE GITHUB',
                  style: TextStyle(color: kJarvisCyan, letterSpacing: 1.1)),
            ),
          ),

          _section('FiveM 24/7 Monitor'),
          _holoTile(
            child: ListTile(
              title: Text(
                widget.serviceRunning ? 'MONITOR ACTIVE' : 'MONITOR STOPPED',
                style: TextStyle(
                  color: widget.serviceRunning ? kJarvisGreen : Colors.white70,
                  fontSize: 13.5,
                  letterSpacing: 1.0,
                ),
              ),
              trailing: widget.serviceRunning
                  ? TextButton(
                      onPressed: () async {
                        await widget.onStopMonitor();
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('STOP',
                          style: TextStyle(color: kJarvisRed, letterSpacing: 1.1)),
                    )
                  : TextButton(
                      onPressed: () async {
                        await widget.onStartMonitor();
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('START 24/7',
                          style: TextStyle(color: kJarvisCyan, letterSpacing: 1.1)),
                    ),
            ),
          ),
          _holoTile(
            child: SwitchListTile(
              value: _fivemNotifyJoins,
              activeColor: kJarvisCyan,
              title: const Text('Announce Joins',
                  style: TextStyle(color: Colors.white, fontSize: 13.5)),
              onChanged: (v) {
                setState(() => _fivemNotifyJoins = v);
                widget.prefs?.setBool(kPrefFivemNotifyJoins, v);
              },
            ),
          ),
          _holoTile(
            child: SwitchListTile(
              value: _fivemNotifyRestart,
              activeColor: kJarvisCyan,
              title: const Text('Announce Restarts / Offline',
                  style: TextStyle(color: Colors.white, fontSize: 13.5)),
              onChanged: (v) {
                setState(() => _fivemNotifyRestart = v);
                widget.prefs?.setBool(kPrefFivemNotifyRestart, v);
              },
            ),
          ),
          _holoTile(
            child: SwitchListTile(
              value: _fivemAutoFix,
              activeColor: kJarvisCyan,
              title: const Text('Auto-fix When Offline',
                  style: TextStyle(color: Colors.white, fontSize: 13.5)),
              subtitle: Text(
                'Calls the restart webhook',
                style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 11.5),
              ),
              onChanged: (v) {
                setState(() => _fivemAutoFix = v);
                widget.prefs?.setBool(kPrefFivemAutoFix, v);
              },
            ),
          ),
          _holoTile(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Text(
                    'POLL INTERVAL  ·  $_fivemPollSeconds s',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11.5,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
                Slider(
                  value: _fivemPollSeconds.toDouble(),
                  min: 20,
                  max: 120,
                  divisions: 10,
                  activeColor: kJarvisCyan,
                  inactiveColor: kJarvisCyan.withOpacity(0.12),
                  onChanged: (v) => setState(() => _fivemPollSeconds = v.round()),
                  onChangeEnd: (v) =>
                      widget.prefs?.setInt(kPrefFivemPollSeconds, v.round()),
                ),
              ],
            ),
          ),
          _holoTile(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
              child: TextField(
                controller: _webhookController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'https://your-panel/restart',
                  labelText: 'Restart Webhook URL',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.42)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _saveWebhook,
              child: const Text('SAVE WEBHOOK',
                  style: TextStyle(color: kJarvisCyan, letterSpacing: 1.1)),
            ),
          ),

          _section('Email'),
          _holoTile(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
              child: TextField(
                controller: _emailUserController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.42)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          _holoTile(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
              child: TextField(
                controller: _emailPassController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'App Password',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.42)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _saveEmail,
              child: const Text('SAVE CREDENTIALS',
                  style: TextStyle(color: kJarvisCyan, letterSpacing: 1.1)),
            ),
          ),

          _section('Model'),
          _holoTile(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: TextField(
                controller: _modelController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'gpt-4o-mini',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.22)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          _section('Memory (${widget.memory.length})'),
          ...widget.memory.map(
            (f) => Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 5),
              child: Text('·  $f',
                  style:
                      TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.5)),
            ),
          ),
          if (widget.memory.isNotEmpty)
            TextButton(
              onPressed: () async {
                await widget.onClearMemory();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('ERASE ALL MEMORIES',
                  style: TextStyle(color: kJarvisRed, letterSpacing: 1.1)),
            ),

          _section('Dynamic Tools (${widget.dynamicTools.length})'),
          if (widget.dynamicTools.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 8),
              child: Text(
                'None yet. Say "improve yourself" in hands-free mode to develop new ones.',
                style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
              ),
            ),
          ...widget.dynamicTools.map(
            (t) => Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '·  ${t['name']}  ·  used ${t['use_count'] ?? 0}×',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.65), fontSize: 12.5),
                  ),
                  if ((t['description'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 2),
                      child: Text(
                        t['description'].toString(),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35), fontSize: 11.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.dynamicTools.isNotEmpty)
            TextButton(
              onPressed: () async {
                await widget.onClearDynamicTools();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('CLEAR DYNAMIC TOOLS',
                  style: TextStyle(color: kJarvisRed, letterSpacing: 1.1)),
            ),

          _section('Account'),
          TextButton(
            onPressed: () async {
              await widget.onClearKey();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'CHANGE API KEY',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35), letterSpacing: 1.1),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// API KEY SCREEN
// ---------------------------------------------------------------------------

class _ApiKeyScreen extends StatefulWidget {
  final Future<void> Function(String) onSave;
  const _ApiKeyScreen({required this.onSave});
  @override
  State<_ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<_ApiKeyScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  String? _error;
  bool _saving = false;
  late AnimationController _reactor;

  @override
  void initState() {
    super.initState();
    _reactor =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
          ..repeat();
  }

  Future<void> _submit() async {
    final v = _controller.text.trim();
    if (!v.startsWith('sk-') || v.length < 20) {
      setState(() => _error = 'Invalid OpenAI key format');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    await widget.onSave(v);
  }

  @override
  void dispose() {
    _controller.dispose();
    _reactor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kJarvisDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: AnimatedBuilder(
                    animation: _reactor,
                    builder: (_, __) => CustomPaint(
                      painter: ArcReactorPainter(
                        progress: _reactor.value,
                        active: true,
                        listening: false,
                        speaking: false,
                        processing: false,
                        coreColor: kJarvisCyan,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'J.A.R.V.I.S',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kJarvisCyan,
                  fontSize: 26,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 9,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'JUST A RATHER VERY INTELLIGENT SYSTEM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kJarvisCyan.withOpacity(0.38),
                  fontSize: 8.5,
                  letterSpacing: 1.7,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Enter your OpenAI API key.\nStored encrypted on this device only.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  height: 1.5,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 24),
              HoloPanel(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: TextField(
                  controller: _controller,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, letterSpacing: 0.8),
                  decoration: InputDecoration(
                    hintText: 'sk-…',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.22)),
                    errorText: _error,
                    errorStyle: const TextStyle(color: kJarvisRed, fontSize: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: _saving ? null : _submit,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: kJarvisCyan.withOpacity(0.65)),
                    borderRadius: BorderRadius.circular(3),
                    color: kJarvisCyan.withOpacity(0.09),
                    boxShadow: [
                      BoxShadow(
                        color: kJarvisCyan.withOpacity(0.12),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Text(
                    _saving ? 'INITIALISING…' : 'AUTHENTICATE & CONTINUE',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kJarvisCyan,
                      fontSize: 12,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
