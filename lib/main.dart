import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shubraepp/leave_requests.dart';
import 'package:shubraepp/loan_requests.dart';
import 'package:shubraepp/request_leave.dart';
import 'package:shubraepp/add_notification.dart';
import 'package:shubraepp/attendance.dart';
import 'package:shubraepp/custody.dart';
import 'package:shubraepp/digital_card.dart';
import 'package:shubraepp/emp_move.dart';
import 'package:shubraepp/emp_rate_mgr.dart';
import 'package:shubraepp/emp_rate.dart';
import 'package:shubraepp/home.dart';
import 'package:shubraepp/login.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shubraepp/new_account.dart';
import 'package:shubraepp/request_loan.dart';
import 'package:shubraepp/salary_details.dart';
import 'package:shubraepp/token_loans.dart';
import 'package:shubraepp/update_info.dart';
import 'colleagues.dart';
import 'complaint.dart';
import 'notification_mgr.dart';
import 'notifications.dart';
import 'custody_mgr.dart';
import 'home_mgr.dart';
import 'l10n/app_localizations.dart';
import 'leave_requests_mgr.dart';
import 'loan_requests_mgr.dart';
import 'shared/utils/logger.dart';
import 'theme.dart';
import 'settings.dart';
import 'profile.dart';
import 'about.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
final ValueNotifier<Locale> localeNotifier = ValueNotifier(Locale("ar"));



Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep status + system nav bars reserved and themed so content never
  // gets hidden behind Android's 3-button nav bar (e.g. Samsung Galaxy).
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Color(0xFFE5E7EB),
  ));

  final _storage = FlutterSecureStorage();
  String? savedLocale = await _storage.read(key: "locale");
  localeNotifier.value = (savedLocale == "en") ? Locale("en") : Locale("ar");
  await Firebase.initializeApp();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;


  });

  runApp(MyApp());
}
/// Root widget — wires localization, theme, and the route table.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}
class _MyAppState extends State<MyApp>  {

  Future<void> _initFCM() async {
    // Request permission
    NotificationSettings settings =
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get APNs token (iOS only). Never log the token itself — log only that
      // one was acquired and its length, which is enough to debug rollouts.
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      logD('APNs token acquired (length=${apnsToken?.length ?? 0})');

      if (apnsToken != null) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        logD('FCM token acquired (length=${fcmToken?.length ?? 0})');
      }
    } else {
      logD('Notification permission denied or not yet granted');
    }
  }
  @override
  void initState() {
    super.initState();
    _initFCM();
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logD('Foreground message: ${message.notification?.title}');
    });

    // Background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logD('Notification opened from background');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('ar'),
          ],
          locale: locale,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => SplashScreen(),
            '/login': (context) => Login(),
            '/newaccount': (context) => NewAccount(),
            '/homeMgr': (context) => HomeMgr(),
            '/home': (context) => Home(),
            '/updateInfo': (context) => UpdateInfo(),
            '/complaint': (context) => Complaint(),
            '/moves': (context) => EmpMove(),
            '/attendance': (context) => const Attendance(),
            '/salaryDetails': (context) => const SalaryDetails(),
            '/digitalCard': (context) => const DigitalCard(),
            '/colleagues': (context) => const Colleagues(),
            '/custody': (context) => Custody(),
            '/custodyMgr': (context) => CustodyMgr(),
            '/emprate': (context) => EmpRate(),
            '/notifications': (context) => Notifications(),
            '/notificationsmgr': (context) => NotificationsMgr(),
            '/addnoti': (context) => AddNotification(),
            '/tokenloans': (context) => TokenLoans(),
            '/requestLoan': (context) => RequestLoan(),
            '/loanRequests': (context) => Loanrequests(),
            '/requestLeave': (context) => RequestLeave(),
            '/leaveRequests': (context) => Leaverequests(),
            '/leaveRequestsMgr': (context) => LeaverequestsMgr(),
            '/loanRequestsMgr': (context) => LoanrequestsMgr(),
            '/emprateMgr': (context) => EmpRateMgr(),
            '/settings': (context) => const SettingsScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/about': (context) => const AboutScreen(),
            '/logout': (context) => Login(),
          },
        );
      },
    );
  }
}
/// Initial gate: reads stored token and redirects to /home, /homeMgr,
/// or /login based on what's persisted in secure storage.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  Future<void> checkAuth() async {
    await Future.delayed(Duration(seconds: 2));
    String? token = await _storage.read(key: "access_token");
    String? legacyType = await _storage.read(key: "type");

    // Legacy manager-only session (token came from /verify-mgr) — its scope
    // probably doesn't cover user endpoints, so force a fresh login. Preserve
    // locale so the user doesn't lose their language preference.
    if (legacyType == 'mgr') {
      String? locale = await _storage.read(key: "locale");
      await _storage.deleteAll();
      if (locale != null) {
        await _storage.write(key: "locale", value: locale);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Legacy employee session — silently migrate `type` → `current_view`.
    if (legacyType == 'user') {
      await _storage.delete(key: "type");
      await _storage.write(key: "current_view", value: "user");
    }

    if (!mounted) return;

    if (token != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Image.asset("assets/shubra.png", height: 100),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor:
                      AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.only(
                    bottom: 24 +
                        MediaQuery.of(context).padding.bottom),
                child: const Text(
                  "SHUBRA",
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
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
