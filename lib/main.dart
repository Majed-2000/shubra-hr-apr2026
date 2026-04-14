import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shubraepp/LeaveRequests.dart';
import 'package:shubraepp/LoanRequests.dart';
import 'package:shubraepp/RequestLeave.dart';
import 'package:shubraepp/addNotification.dart';
import 'package:shubraepp/custody.dart';
import 'package:shubraepp/empMove.dart';
import 'package:shubraepp/empRateMgr.dart';
import 'package:shubraepp/emprate.dart';
import 'package:shubraepp/home.dart';
import 'package:shubraepp/login.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shubraepp/newaccount.dart';
import 'package:shubraepp/newaccountMgr.dart';
import 'package:shubraepp/requestLoan.dart';
import 'package:shubraepp/tokenloans.dart';
import 'package:shubraepp/updateInfo.dart';
import 'Complaint.dart';
import 'NotificationMgr.dart';
import 'Notifications.dart';
import 'custodyMgr.dart';
import 'homeMgr.dart';
import 'l10n/app_localizations.dart';
import 'leaveRequestsMgr.dart';
import 'loanRequestsMgr.dart';
import 'loginMgr.dart';
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
    systemNavigationBarDividerColor: Color(0xFFE2E8F0),
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
      // Get APNs token (iOS only)
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      print("APNs Token: $apnsToken");

      if (apnsToken != null) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        print("FCM Token: $fcmToken");
      }
    } else {
      print("User declined or has not accepted permission");
    }
  }
  @override
  void initState() {
    super.initState();
    _initFCM();
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Message Received: ${message.notification?.title}");
    });

    // Background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification Clicked!");
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
            '/loginmgr': (context) => LoginMgr(),
            '/homeMgr': (context) => homeMgr(),
            '/newaccountmgr': (context) => NewAccountMGR(),
            '/home': (context) => Home(),
            '/updateInfo': (context) => updateInfo(),
            '/complaint': (context) => Complaint(),
            '/moves': (context) => empMove(),
            '/custody': (context) => custody(),
            '/custodyMgr': (context) => custodyMgr(),
            '/emprate': (context) => empRate(),
            '/notifications': (context) => Notifications(),
            '/notificationsmgr': (context) => NotificationsMgr(),
            '/addnoti': (context) => addNotification(),
            '/tokenloans': (context) => tokenloans(),
            '/requestLoan': (context) => RequestLoan(),
            '/loanRequests': (context) => Loanrequests(),
            '/requestLeave': (context) => RequestLeave(),
            '/leaveRequests': (context) => Leaverequests(),
            '/leaveRequestsMgr': (context) => LeaverequestsMgr(),
            '/loanRequestsMgr': (context) => LoanrequestsMgr(),
            '/emprateMgr': (context) => empRateMgr(),
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
    String? type = await _storage.read(key: "type");

    if (!mounted) return;

    if (token != null) {
      if (type == "mgr") {
        Navigator.pushReplacementNamed(context, '/homeMgr');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset("assets/shubra.png", height: 120),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
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
                      color: Colors.white70,
                      fontSize: 13,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
