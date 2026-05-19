// ============================================================================
// ملف: main.dart
// الغرض: نقطة الدخول للتطبيق. هنا يتم:
//   1) تهيئة Flutter binding وأشرطة النظام (status + nav bar).
//   2) قراءة اللغة المحفوظة من secure storage (عربي افتراضياً).
//   3) تهيئة Firebase + Firebase Messaging.
//   4) تشغيل MyApp مع جدول المسارات (37 مسار).
//   5) شاشة SplashScreen التي تقرر: /home (إذا token موجود) أو /login.
// المعتمدون عليه: لا شيء — هذه نقطة الدخول الجذرية.
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:shubraepp/privacy.dart';
import 'package:shubraepp/request_loan.dart';
import 'package:shubraepp/sessions.dart';
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
import 'documents/document_models.dart';
import 'documents/document_viewer.dart';
import 'documents/documents_vault.dart';
import 'eos/eos_calculator.dart';
import 'security/biometric_lock_screen.dart';
import 'security/biometric_service.dart';
import 'shared/services/deep_link_router.dart';
import 'shared/services/feature_flags.dart';
import 'tickets/new_ticket.dart';
import 'tickets/ticket_detail.dart';
import 'tickets/ticket_list.dart';
import 'leave_requests_mgr.dart';
import 'loan_requests_mgr.dart';
import 'shared/utils/logger.dart';
import 'theme.dart';
import 'settings.dart';
import 'profile.dart';
import 'about.dart';
import 'terms.dart';
import 'website.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// متغير عام reactive للغة الحالية — تغييره يُعيد بناء MaterialApp فوراً.
/// نستعمل ValueNotifier لتجنّب الحاجة لمكتبة state management كاملة.
/// قيمة افتراضية: عربية (سوق التطبيق الأساسي).
final ValueNotifier<Locale> localeNotifier = ValueNotifier(Locale("ar"));

/// متغير عام reactive لوضع الألوان (light / dark).
/// تغييره يُعيد بناء MaterialApp بالـ ThemeData المناسب + يُحدّث AppColors._isDark.
/// نقرأ القيمة المحفوظة من secure storage عند بدء التطبيق.
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);



/// Handler لرسائل Firebase التي تصل والتطبيق في الخلفية أو مغلق.
/// مطلوب أن يكون top-level function (ليس داخل كلاس) لأن Flutter يستدعيه
/// في isolate منفصل لا يستطيع رؤية حالة التطبيق الرئيسي.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// نقطة دخول التطبيق الفعلية.
/// async لأننا ننتظر قراءة secure storage وتهيئة Firebase قبل runApp.
void main() async {
  // ضروري قبل أي استدعاء async لأشياء native (channels, plugins).
  WidgetsFlutterBinding.ensureInitialized();

  // في وضع التطوير (debug) فقط: نُسكت رسائل console المزعجة من
  // "A RenderFlex overflowed by N pixels" — الـ banner المرئي الأصفر/الأسود
  // ما زال يظهر إن وُجد overflow فعلاً (لأن Flutter يرسمه مباشرة في paint)،
  // لكن log الـ console يصير نظيفاً. في الإصدار النهائي (release) لا شيء
  // من هذا يظهر أصلاً.
  if (kDebugMode) {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('overflowed by')) return;
      originalOnError?.call(details);
    };
  }

  // Keep status + system nav bars reserved and themed so content never
  // gets hidden behind Android's 3-button nav bar (e.g. Samsung Galaxy).
  //
  // نُلزم النظام بإظهار شريط الحالة والـ navigation bar (يدوياً)
  // حتى لا يختفي محتوى التطبيق خلفهما على أجهزة Samsung وغيرها.
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  // ألوان أشرطة النظام: شفّاف للأعلى، أبيض للأسفل + أيقونات داكنة (matching الـ theme).
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Color(0xFFE5E7EB),
  ));

  // قراءة اللغة المحفوظة من جلسة سابقة (إن وجدت).
  final _storage = FlutterSecureStorage();
  String? savedLocale = await _storage.read(key: "locale");
  // إذا كانت "en" نستعملها، وإلا (null أو "ar" أو أي قيمة) → عربي.
  localeNotifier.value = (savedLocale == "en") ? Locale("en") : Locale("ar");

  // قراءة وضع الـ theme المحفوظ (light افتراضياً).
  String? savedTheme = await _storage.read(key: "theme_mode");
  themeNotifier.value =
      savedTheme == "dark" ? ThemeMode.dark : ThemeMode.light;
  // تطبيق الـ flag على AppColors قبل أي قراءة من شاشة (مثلاً SplashScreen).
  AppColors.setDark(themeNotifier.value == ThemeMode.dark);

  // تهيئة Firebase (يقرأ google-services.json / GoogleService-Info.plist).
  await Firebase.initializeApp();

  // تسجيل معالج رسائل الخلفية — يجب أن يكون قبل runApp.
  // يعمل في isolate منفصل عندما يكون التطبيق مغلقاً أو في الخلفية.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // مستمع للرسائل التي تصل والتطبيق مفتوح (foreground).
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    logD('FCM foreground: ${message.notification?.title}');
  });

  // تشغيل شجرة الـ widgets.
  runApp(MyApp());
}

/// Root widget — wires localization, theme, and the route table.
///
/// MyApp = جذر الشجرة. مهامه:
///   1) إعداد FCM (طلب صلاحية + الحصول على tokens).
///   2) الاستماع لتغيّر لغة الواجهة.
///   3) تعريف خريطة المسارات (routes).
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Track when the app was last backgrounded so we can re-lock if it
  // returns to foreground past the user's lock timeout (feature 1).
  DateTime? _pausedAt;
  final _navKey = GlobalKey<NavigatorState>();

  /// إعداد Firebase Cloud Messaging:
  ///   1) طلب صلاحية الإشعارات (يظهر popup للمستخدم).
  ///   2) الحصول على APNs token (iOS فقط — مطلوب قبل FCM token).
  ///   3) الحصول على FCM token (المعرّف الذي يستخدمه الـ backend للإرسال).
  Future<void> _initFCM() async {
    // Request permission
    // طلب صلاحية الإشعارات من المستخدم (alert + badge + sound).
    NotificationSettings settings =
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get APNs token (iOS only). Never log the token itself — log only that
      // one was acquired and its length, which is enough to debug rollouts.
      //
      // على iOS، يجب الحصول على APNs token من Apple قبل FCM token.
      // ⚠️ لا نُسجّل قيمة الـ token (سرّي) — فقط طوله للتأكد أنه وصل.
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      logD('APNs token acquired (length=${apnsToken?.length ?? 0})');

      if (apnsToken != null) {
        // الحصول على FCM token (الـ token الذي يستعمله Firebase للإرسال).
        // الـ backend يحتاجه ليرسل إشعار لمستخدم محدد.
        final fcmToken = await FirebaseMessaging.instance.getToken();
        logD('FCM token acquired (length=${fcmToken?.length ?? 0})');
      }
    } else {
      // المستخدم رفض الصلاحية أو لم يردّ بعد — لن نتلقى إشعارات.
      logD('Notification permission denied or not yet granted');
    }
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initFCM();
    // Foreground messages
    // مستمع لرسائل تصل والتطبيق ظاهر — هنا فقط نلوّغها (لا UI).
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logD('Foreground message: ${message.notification?.title}');
    });

    // Background messages
    // مستمع لفتح إشعار من tray (والتطبيق كان في الخلفية).
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logD('Notification opened from background');
      final link = DeepLinkRouter.fromMessage(message);
      if (link != null) DeepLinkRouter.queue(link);
    });
    // Foreground deep links (FCM data while app is open).
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final link = DeepLinkRouter.fromMessage(message);
      if (link == null) return;
      // Surface as snack; user taps to navigate (avoids stealing context).
      final ctx = _navKey.currentState?.context;
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: const Text('HR replied — tap to view'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => _navKey.currentState
                  ?.pushNamed(link.route, arguments: link.arguments),
            ),
          ),
        );
      }
    });
    // Cold-start deep link.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      final link = DeepLinkRouter.fromMessage(message);
      if (link != null) DeepLinkRouter.queue(link);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final timeout = await BiometricService.lockTimeoutSeconds;
      final elapsed = DateTime.now().difference(_pausedAt!).inSeconds;
      _pausedAt = null;
      if (elapsed < timeout) return;
      final lockOn = await BiometricService.isLockEnabled;
      if (!lockOn) return;
      final ctx = _navKey.currentState?.context;
      if (ctx == null) return;
      final current = ModalRoute.of(ctx)?.settings.name;
      if (current == '/lock' || current == '/login' || current == '/splash') {
        return;
      }
      _navKey.currentState
          ?.pushNamedAndRemoveUntil('/lock', (_) => false, arguments: current);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder خارجي يستمع لوضع الـ theme، داخلي للّغة.
    // تغيير أيٍّ منهما يُعيد بناء MaterialApp بالقيم الجديدة.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        // مزامنة AppColors._isDark قبل أن يبني الـ children أي UI.
        // (الشاشات تقرأ AppColors.surface/bg/... statically.)
        AppColors.setDark(themeMode == ThemeMode.dark);
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp(
              navigatorKey: _navKey,
              // إخفاء شريط "Debug" في الزاوية أثناء التطوير.
              debugShowCheckedModeBanner: false,
              // theme فاتح + theme داكن — MaterialApp يختار حسب themeMode.
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              // delegates الترجمة — AppLocalizations لنا + Global للمكوّنات الافتراضية.
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // اللغات المدعومة: إنجليزي وعربي فقط.
              supportedLocales: [
                Locale('en'),
                Locale('ar'),
              ],
              locale: locale,
              // أول شاشة بعد التشغيل = SplashScreen (تقرر إلى أين نذهب).
              initialRoute: '/splash',
              // خريطة المسارات الـ 37 — كل اسم مسار يُربط بشاشة.
              // طريقة الاستعمال: Navigator.pushNamed(context, '/home');
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
                '/privacy': (context) => const PrivacyScreen(),
                '/terms': (context) => const TermsScreen(),
                '/website': (context) => const WebsiteScreen(),
                '/sessions': (context) => const SessionsScreen(),
                '/logout': (context) => Login(),
                '/lock': (context) => const BiometricLockScreen(),
                '/eosCalculator': (context) => const EosCalculator(),
                '/documents': (context) => const DocumentsVault(),
                '/documentViewer': (context) => const DocumentViewer(),
                '/tickets': (context) => const TicketList(),
                '/ticketDetail': (context) => const TicketDetail(),
                '/newTicket': (context) => const NewTicket(),
              },
            );
          },
        );
      },
    );
  }
}

/// Initial gate: reads stored token and redirects to /home, /homeMgr,
/// or /login based on what's persisted in secure storage.
///
/// شاشة Splash هي البوابة الأولى للتطبيق:
///   - تعرض شعار شُبرا لمدة ثانيتين.
///   - تقرأ access_token من secure storage.
///   - تحوّل المستخدم إلى /home إن كان مسجلاً، وإلا /login.
///   - تهاجر الـ tokens القديمة (legacy) إذا وجدت.
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

  /// منطق فحص المصادقة عند البدء.
  /// التدفق:
  ///   1) ننتظر 2 ثانية لإظهار الشعار (UX).
  ///   2) نقرأ access_token و mgr_access_token من storage.
  ///   3) نتعامل مع جلسات قديمة (legacy `type` field).
  ///   4) نوجّه حسب current_view: user → /home، mgr → /homeMgr، وإلا /login.
  Future<void> checkAuth() async {
    await Future.delayed(Duration(seconds: 2));
    String? userToken = await _storage.read(key: "access_token");
    String? mgrToken = await _storage.read(key: "mgr_access_token");
    String? currentView = await _storage.read(key: "current_view");
    String? legacyType = await _storage.read(key: "type");

    // Legacy migration — older builds wrote `type: 'mgr'` with the manager token
    // stored under `access_token`. We migrate it to the new dual-scope keys
    // instead of force-logging-out, so existing managers keep their session.
    if (legacyType == 'mgr') {
      // إذا كان هناك token محفوظ تحت access_token فهو فعلياً token المدير.
      if (userToken != null && mgrToken == null) {
        final legacyRefresh = await _storage.read(key: 'refresh_token');
        await _storage.write(key: 'mgr_access_token', value: userToken);
        if (legacyRefresh != null) {
          await _storage.write(key: 'mgr_refresh_token', value: legacyRefresh);
        }
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'refresh_token');
        mgrToken = userToken;
        userToken = null;
      }
      await _storage.delete(key: 'type');
      await _storage.write(key: 'current_view', value: 'mgr');
      await _storage.write(key: 'is_manager', value: 'true');
      currentView = 'mgr';
    }

    // Legacy employee session — silently migrate `type` → `current_view`.
    if (legacyType == 'user') {
      await _storage.delete(key: "type");
      await _storage.write(key: "current_view", value: "user");
      currentView = 'user';
    }

    if (!mounted) return;

    // Resolve where the user should land after splash.
    String target;
    if (currentView == 'mgr' && mgrToken != null) {
      target = '/homeMgr';
    } else if (userToken != null) {
      target = '/home';
    } else if (mgrToken != null) {
      target = '/homeMgr';
    } else {
      target = '/login';
    }

    // If biometric app lock is on AND we're heading to an authenticated
    // route, gate it through /lock first (feature 1).
    final lockOn = await BiometricService.isLockEnabled;
    if (lockOn && target != '/login') {
      Navigator.pushReplacementNamed(context, '/lock', arguments: target);
    } else {
      Navigator.pushReplacementNamed(context, target);
    }
  }

  @override
  Widget build(BuildContext context) {
    // واجهة Splash البسيطة: شعار في الوسط + مؤشر تحميل + كلمة SHUBRA أسفل.
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // مربع أبيض يحوي شعار شُبرا.
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
              // مؤشر تحميل صغير بلون الـ primary.
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
              // نص "SHUBRA" أسفل الشاشة كهوية بصرية.
              Padding(
                padding: EdgeInsets.only(
                    bottom: 24 +
                        MediaQuery.of(context).padding.bottom),
                child: Text(
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
