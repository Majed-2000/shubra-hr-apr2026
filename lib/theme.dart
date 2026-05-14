// ============================================================================
// ملف: theme.dart
// الغرض: نظام التصميم (Design System) للتطبيق:
//   - AppColors: لوحة الألوان (teal مستوحاة من Jisr).
//   - AppRadius: قيم انحناء الزوايا (xs/sm/md/lg/xl).
//   - AppShadows: مستويات الظلال (card/soft/pop).
//   - AppTheme.light: ThemeData كامل لـ MaterialApp (ألوان، خطوط، أزرار، إلخ).
//   - GlassCard / PrimaryButton / InfoTile / SectionHeader: widgets جاهزة موحّدة.
// لماذا مهم: نجمع الألوان والأبعاد في مكان واحد فلو أردنا تغيير الـ primary
//          نغيّره مرة واحدة فقط بدلاً من البحث في كل الملفات.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Light palette (current values, unchanged) ──────────────────────────
const Color _lightBg = Color(0xFFF5F9F8);
const Color _lightSurface = Colors.white;
const Color _lightSurfaceAlt = Color(0xFFEDF5F3);
const Color _lightOnSurface = Color(0xFF1A1A2E); // near-black
const Color _lightMuted = Color(0xFF77797A);
const Color _lightBorder = Color(0xFFE5E7EB);

// ─── Dark palette (new) — slate background, near-white text ─────────────
const Color _darkBg = Color(0xFF0F1419);
const Color _darkSurface = Color(0xFF1B232E);
const Color _darkSurfaceAlt = Color(0xFF252F3D);
const Color _darkOnSurface = Color(0xFFE5E7EB);
const Color _darkMuted = Color(0xFF9CA3AF);
const Color _darkBorder = Color(0xFF2D3748);

/// لوحة ألوان التطبيق.
///
/// الـ brand colors ثابتة في الوضعين (primary/secondary/success/warning/danger).
/// ألوان الـ surface (bg, surface, onSurface, ...) تتغيّر حسب الوضع الحالي
/// المُحدَّد عبر [setDark]. الـ ValueListenableBuilder في main.dart يستدعي
/// setDark قبل بناء MaterialApp، فيقرأ كل المستهلكين القيم المناسبة.
class AppColors {
  /// flag داخلي يحدد الوضع الحالي (false = light, true = dark).
  static bool _isDark = false;

  /// يُستدعى من ValueListenableBuilder<ThemeMode> في main.dart.
  /// بعدها كل قراءة لـ AppColors.bg / surface / ... تُرجع القيمة المناسبة.
  static void setDark(bool dark) => _isDark = dark;

  /// هل الوضع الحالي داكن؟ مفيد للشاشات التي تريد منطقاً مخصصاً للوضعين.
  static bool get isDark => _isDark;

  // Jisr-inspired teal palette — brand colors (mode-invariant).
  // لوحة turquoise — ثابتة في الوضعين.
  static const Color primary = Color(0xFF19D4B5); // teal
  static const Color primaryDark = Color(0xFF1A1A2E); // near-black
  static const Color secondary = Color(0xFF14CCAB);
  static const Color secondaryLight = Color(0xFF78E4D0);
  static const Color accent = Color(0xFF14CCAB);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // ─── Surface colors — getters that flip with the current mode ─────────
  static Color get bg => _isDark ? _darkBg : _lightBg;
  static Color get surface => _isDark ? _darkSurface : _lightSurface;
  static Color get surfaceAlt => _isDark ? _darkSurfaceAlt : _lightSurfaceAlt;
  static Color get onSurface => _isDark ? _darkOnSurface : _lightOnSurface;
  static Color get muted => _isDark ? _darkMuted : _lightMuted;
  static Color get border => _isDark ? _darkBorder : _lightBorder;

  // ─── Gradients — heroGradient is mode-invariant (always dark, used for
  // splash/login branding). softGradient flips for dark to keep cards
  // readable on dark bg.
  static LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A2E), Color(0xFF19D4B5)],
      );

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF19D4B5), Color(0xFF14CCAB)],
      );

  static LinearGradient get softGradient => _isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B232E), Color(0xFF0F1419)],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F9F8)],
        );
}

/// قيم انحناء الزوايا (border radius) — نستعملها بدلاً من أرقام عشوائية.
/// ترتيب من الأصغر إلى الأكبر: xs(8) → sm(12) → md(16) → lg(20) → xl(28).
class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
}

/// مستويات الظلال — card (افتراضي)، soft (أخف)، pop (أبرز للعناصر المهمة).
class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.015),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> pop = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.12),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}

/// الـ ThemeData الكامل للتطبيق.
///
/// يوفّر [light] و [dark] — تُمَرَّر إلى MaterialApp.theme و darkTheme
/// في main.dart. MaterialApp يختار الـ ThemeData المناسب حسب themeMode.
///
/// كلا الـ ThemeData يُبنيان عبر [_build] مع تمرير الألوان explicit
/// (وليس عبر AppColors.X) حتى يبقى كل ThemeData مستقراً ولا يعتمد
/// على القيمة الحالية لـ AppColors._isDark وقت البناء.
class AppTheme {
  /// theme الوضع الفاتح.
  static ThemeData get light => _build(
        scaffoldBg: _lightBg,
        surface: _lightSurface,
        surfaceAlt: _lightSurfaceAlt,
        onSurface: _lightOnSurface,
        muted: _lightMuted,
        border: _lightBorder,
        brightness: Brightness.light,
      );

  /// theme الوضع الداكن.
  static ThemeData get dark => _build(
        scaffoldBg: _darkBg,
        surface: _darkSurface,
        surfaceAlt: _darkSurfaceAlt,
        onSurface: _darkOnSurface,
        muted: _darkMuted,
        border: _darkBorder,
        brightness: Brightness.dark,
      );

  /// بناء ThemeData ببارامترات صريحة (لا يقرأ AppColors.X). هذا يضمن
  /// أن light/dark themes ثابتة بصرف النظر عن _isDark الحالي.
  static ThemeData _build({
    required Color scaffoldBg,
    required Color surface,
    required Color surfaceAlt,
    required Color onSurface,
    required Color muted,
    required Color border,
    required Brightness brightness,
  }) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: onSurface,
        error: AppColors.danger,
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: onSurface,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: brightness,
        ),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        prefixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: onSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        // في dark mode، نستعمل surface فاتح بدلاً من onSurface (الأبيض) كي
        // لا تختفي رسائل الـ snackbar على خلفية فاتحة.
        backgroundColor:
            brightness == Brightness.dark ? surfaceAlt : onSurface,
        contentTextStyle: TextStyle(
          color: brightness == Brightness.dark ? onSurface : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      // Pop-out menus from DropdownButton, PopupMenuButton, etc. default to
      // a flat gray Material look that clashes with the rest of the app.
      // Theme them to a clean white card with the brand border + radius so
      // every dropdown matches the surrounding UI.
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: border, width: 1),
        ),
        textStyle: TextStyle(
          color: onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          color: onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              side: BorderSide(color: border, width: 1),
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 4),
          ),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              side: BorderSide(color: border, width: 1),
            ),
          ),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
    );
  }
}

/// Modern card container — flat with subtle border
///
/// بطاقة عصرية بحدود خفيفة وزوايا مدوّرة — البديل الموحّد عن Container.
/// تدعم onTap اختياري للجعلها قابلة للضغط.
/// المعاملات:
/// - [child]:        المحتوى داخل البطاقة.
/// - [padding]:      الهوامش الداخلية (افتراضياً 16).
/// - [margin]:       الهوامش الخارجية.
/// - [onTap]:        دالة عند الضغط (إن كان null والـ onLongPress كذلك → بطاقة عرض فقط).
/// - [onLongPress]:  دالة عند الضغط المطوّل (اختياري).
/// - [color]:        لون الخلفية (افتراضياً AppColors.surface).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.onLongPress,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null && onLongPress == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        onLongPress: onLongPress,
        child: card,
      ),
    );
  }
}

/// Primary flat button — Jisr style (no gradient)
///
/// الزر الرئيسي للنماذج (إرسال، تأكيد، تسجيل دخول، ...).
/// يدعم حالة تحميل (loading) تعرض دائرة تقدّم بدلاً من النص.
/// المعاملات:
/// - [label]:     نص الزر.
/// - [onPressed]: دالة الضغط (null = معطّل).
/// - [icon]:      أيقونة اختيارية قبل النص.
/// - [loading]:   true = يعرض loader ويعطّل الضغط.
/// - [expand]:    true = يأخذ كامل العرض (افتراضي).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final child = Container(
      height: 48,
      decoration: BoxDecoration(
        color: enabled ? AppColors.primary : AppColors.muted.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: enabled ? onPressed : null,
        child: expand ? SizedBox(width: double.infinity, child: child) : child,
      ),
    );
  }
}

/// Row displaying an info label/value pair
///
/// صف يعرض معلومة بصيغة "label : value" (مثلاً "الاسم : محمد علي").
/// يُستخدم في صفحات العرض (profile, salary_details, ...).
/// المعاملات:
/// - [icon]:  أيقونة اختيارية (مربع ملوّن صغير على اليسار).
/// - [label]: التسمية (يمين، لون رمادي).
/// - [value]: القيمة (يسار، أسود غامق).
class InfoTile extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;

  const InfoTile({
    super.key,
    this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
                fontSize: 13.5,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Styled section header with optional action
///
/// عنوان قسم في الشاشة (مثل "البيانات الشخصية"، "آخر طلبات").
/// يدعم أيقونة + عنوان + عنوان فرعي اختياري.
/// المعاملات:
/// - [title]:    العنوان الرئيسي (خط ثقيل).
/// - [subtitle]: عنوان فرعي اختياري (خط رمادي صغير).
/// - [icon]:     أيقونة اختيارية على اليسار بلون الـ primary.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: 0.1,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
