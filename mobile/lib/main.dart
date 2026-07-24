import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app/app.dart';
import 'app/theme.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'screens/article_detail_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/force_update_screen.dart';
import 'screens/no_internet_screen.dart';
import 'package:khandan_app/l10n/app_localizations.dart';

/// Global navigator key for navigation from outside the widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Handle background FCM message (app killed or in background)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background FCM message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (gracefully falls back if no config)
  try {
    await Firebase.initializeApp();
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      await NotificationService().registerDeviceToken(fcmToken, 'android');
      debugPrint('FCM token registered: ${fcmToken.substring(0, 20)}...');
    }

    messaging.onTokenRefresh.listen((newToken) {
      NotificationService().registerDeviceToken(newToken, 'android');
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM message: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleFcmMessage);
  } catch (e) {
    debugPrint('Firebase init skipped (no project config): $e');
  }

  await NotificationService().init();
  runApp(const KhandanApp());
}

/// Handle FCM message tap - navigate to article
void _handleFcmMessage(RemoteMessage message) {
  final data = message.data;
  final type = data['type'] ?? '';
  final notifiableIdStr = data['article_id'] ?? data['notifiable_id'] ?? '';
  final notifiableId = int.tryParse(notifiableIdStr.toString());

  if (type == 'article' && notifiableId != null) {
    _navigateToArticle(notifiableId);
  }
}

/// Navigate to article detail screen
void _navigateToArticle(int articleId, {int retries = 5}) {
  final context = navigatorKey.currentContext;
  if (context == null) {
    if (retries > 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToArticle(articleId, retries: retries - 1);
      });
    }
    return;
  }

  ApiService.setLocale(
    Localizations.localeOf(context).languageCode,
  );

  ApiService().getArticle(articleId).then((article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArticleDetailScreen(article: article),
      ),
    );
  }).catchError((e) {
    debugPrint('Failed to load article for notification: $e');
  });
}

/// Compare two version strings (e.g., "0.0.3" vs "0.0.5")
bool _isVersionLower(String currentVersion, String minimumVersion) {
  try {
    final currentParts =
        currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final minParts =
        minimumVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen =
        currentParts.length > minParts.length
            ? currentParts.length
            : minParts.length;
    for (int i = 0; i < maxLen; i++) {
      final cur = i < currentParts.length ? currentParts[i] : 0;
      final min = i < minParts.length ? minParts[i] : 0;
      if (cur < min) return true;
      if (cur > min) return false;
    }
    return false;
  } catch (e) {
    return false;
  }
}

/// Check internet connectivity by looking up a host
Future<bool> _checkInternet() async {
  try {
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 5));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

class KhandanApp extends StatefulWidget {
  const KhandanApp({super.key});

  @override
  State<KhandanApp> createState() => KhandanAppState();

  static KhandanAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<KhandanAppState>();
  }
}

class KhandanAppState extends State<KhandanApp> with WidgetsBindingObserver {
  Locale _locale = const Locale('ckb');
  bool _initialLoading = true;
  bool _noInternet = false;
  bool _needsUpdate = false;
  String _updateUrl = '';

  void setLocale(Locale locale) {
    NotificationService().setLocale(locale.languageCode);
    ApiService.setLocale(locale.languageCode);
    NotificationService().startPolling();
    setState(() => _locale = locale);
  }

  /// Handle notification tap
  void _handleNotificationTap(String type, int? notifiableId, String? url) {
    debugPrint(
        'Notification tapped: type=$type, notifiableId=$notifiableId, url=$url');
    if (type == 'article' && notifiableId != null) {
      _navigateToArticle(notifiableId);
    } else {
      _navigateToNotifications();
    }
  }

  void _navigateToNotifications({int retries = 5}) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      if (retries > 0) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigateToNotifications(retries: retries - 1);
        });
      }
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _ensureHome({int retries = 3}) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      if (retries > 0) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _ensureHome(retries: retries - 1);
        });
      }
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _checkAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final settings = await ApiService().getSettings();
      final minimumVersion =
          settings['minimum_app_version']?.toString() ?? '';
      final updateUrl = settings['update_url']?.toString() ?? '';

      debugPrint(
          'App version check: current=$currentVersion, minimum=$minimumVersion');

      if (minimumVersion.isNotEmpty &&
          _isVersionLower(currentVersion, minimumVersion)) {
        setState(() {
          _needsUpdate = true;
          _updateUrl = updateUrl;
        });
      }
    } catch (e) {
      debugPrint('Version check failed: $e');
    }
  }

  Future<void> _startupSequence() async {
    // Step 1: Check internet
    final hasInternet = await _checkInternet();
    if (!mounted) return;

    if (!hasInternet) {
      setState(() {
        _noInternet = true;
        _initialLoading = false;
      });
      return;
    }

    // Step 2: Check version
    await _checkAppVersion();
    if (!mounted) return;

    setState(() => _initialLoading = false);
  }

  void _onInternetRestored() async {
    // User pressed retry and got connected
    setState(() {
      _noInternet = false;
      _initialLoading = true;
    });
    // Re-run startup sequence
    await _startupSequence();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    NotificationService().setLocale(_locale.languageCode);
    ApiService.setLocale(_locale.languageCode);

    NotificationService().setOnTapCallback(_handleNotificationTap);

    Future.delayed(const Duration(seconds: 3), () {
      NotificationService().startPolling();
    });

    // Run startup sequence
    _startupSequence();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService().stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService().startPolling();
    }
  }

  Widget _buildRootApp(Widget home) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      home: home,
      theme: AppTheme.theme,
      scrollBehavior: const _NoOverscrollBehavior(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ckb'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('ckb');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initial loading - show spinner while checking internet + version
    if (_initialLoading) {
      return _buildRootApp(
        const Scaffold(
          backgroundColor: Color(0xFF0A0A0A),
          body: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      );
    }

    // No internet - show no-internet screen with retry
    if (_noInternet) {
      return _buildRootApp(NoInternetScreen(
        onConnected: _onInternetRestored,
      ));
    }

    // Update required - force update screen (with locale)
    if (_needsUpdate) {
      return _buildRootApp(ForceUpdateScreen(updateUrl: _updateUrl));
    }

    // Normal app
    return _buildRootApp(const App());
  }
}

/// Prevents overscroll bounce/glow on all platforms
class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
