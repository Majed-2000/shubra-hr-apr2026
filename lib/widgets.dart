// ============================================================================
// ملف: widgets.dart
// الغرض: مكتبة widgets مشتركة تُستخدم في جميع شاشات التطبيق.
// المحتوى الرئيسي:
//   - bi() / isArabic(): مساعدات اللغة العربية/الإنجليزية.
//   - ModernScaffold: هيكل الشاشة الموحد (header + back + actions + body).
//   - StatusBadge: شارة حالة ملوّنة (مقبول/مرفوض/معلّق).
//   - EmptyState: واجهة "لا توجد بيانات" مع أيقونة وعنوان.
//   - DetailRow, LabeledField, ListSectionTitle: عناصر نموذج/عرض موحّدة.
//   - Loader / Skeleton / SkeletonList: مؤشرات تحميل.
// لماذا مهم: يُلزم كل الشاشات بنفس المظهر — لا تكرار، لا تباين بصري.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

/// Bilingual string helper — picks Arabic or English based on current locale.
///
/// مساعد ثنائي اللغة: يختار النص العربي أو الإنجليزي حسب لغة الواجهة الحالية.
/// مثال: Text(bi(context, ar: "مرحباً", en: "Welcome"))
String bi(BuildContext context, {required String ar, required String en}) {
  final code = Localizations.localeOf(context).languageCode;
  return code == 'ar' ? ar : en;
}

/// يُرجع true إذا الواجهة الحالية عربية — مفيد لاختبار شروط (مثل اتجاه RTL).
bool isArabic(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

/// Clean white scaffold — Jisr style
///
/// الهيكل الموحد لمعظم الشاشات. يحوي:
///   - رأس أبيض ثابت (header) مع زر رجوع + actions على اليمين.
///   - عنوان + عنوان فرعي + أيقونة جانبية اختيارية.
///   - body قابل للتمرير في المساحة المتبقية.
///   - floating action button اختياري.
/// المعاملات:
/// - [title]:                النص الرئيسي في الـ header.
/// - [subtitle]:             عنوان فرعي اختياري.
/// - [leadingIcon]:          أيقونة بجانب العنوان (مربع ملوّن).
/// - [body]:                 محتوى الشاشة الرئيسي.
/// - [actions]:              widgets على يسار الـ header (مثل زر تحديث).
/// - [floatingActionButton]: زر عائم (FAB).
/// - [showBack]:             إظهار زر الرجوع (افتراضياً true).
class ModernScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBack;

  const ModernScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.leadingIcon,
    this.actions,
    this.floatingActionButton,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        floatingActionButton: floatingActionButton,
        body: Column(
          children: [
            // Clean white header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, top + 8, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (showBack)
                        _HeaderIcon(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.maybePop(context),
                        ),
                      const Spacer(),
                      if (actions != null) ...actions!,
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (leadingIcon != null) ...[
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.10),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child:
                              Icon(leadingIcon, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
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
                  ),
                ],
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                bottom: true,
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر دائري صغير في الـ header (مثل زر الرجوع أو التحديث).
/// _underscore يعني أنه خاص داخلي بهذا الملف فقط.
class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: AppColors.onSurface, size: 18),
        ),
      ),
    );
  }
}

/// Rounded colored pill — for statuses like accepted/refused/pending
///
/// شارة ملوّنة لعرض حالة (مقبول/مرفوض/معلّق) في قوائم الطلبات.
/// تأتي بـ 3 factory constructors جاهزة:
///   - StatusBadge.accepted("مقبول") → أخضر.
///   - StatusBadge.refused("مرفوض") → أحمر.
///   - StatusBadge.pending("معلّق") → برتقالي.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.accepted(String label) => StatusBadge(
        label: label,
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
  factory StatusBadge.refused(String label) => StatusBadge(
        label: label,
        color: AppColors.danger,
        icon: Icons.cancel_rounded,
      );
  factory StatusBadge.pending(String label) => StatusBadge(
        label: label,
        color: AppColors.warning,
        icon: Icons.schedule_rounded,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty-state card
///
/// واجهة "لا توجد بيانات" — أيقونة دائرية كبيرة + عنوان + شرح.
/// تُستخدم في القوائم الفارغة (لا إجازات، لا قروض، لا إشعارات).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? accent;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;
    // SingleChildScrollView يمنع الـ overflow عندما يكون الـ parent ضيقاً
    // (مثلاً عند فتح keyboard في شاشة بحث ذات Expanded — الـ EmptyState
    // بحجمه الطبيعي ~200-250px قد يتجاوز المساحة المتاحة فيظهر banner).
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Icon + label + value row
///
/// صف لعرض تفصيلة (أيقونة مربعة + label + value).
/// مثل InfoTile لكن أصغر — مناسب لعرض حقول في بطاقة طلب.
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(icon, size: 17, color: c),
          ),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern labeled form field
///
/// حقل نموذج موحّد: label أعلى + TextFormField + أيقونة prefix.
/// يدعم validator ومدخلات متعددة الأسطر.
/// المعاملات:
/// - [label]:        تسمية فوق الحقل.
/// - [controller]:   متحكم النص (إلزامي).
/// - [icon]:         أيقونة قبل النص.
/// - [hint]:         نص توجيهي بداخل الحقل.
/// - [maxLines]:     عدد الأسطر (1 افتراضياً).
/// - [keyboardType]: نوع لوحة المفاتيح (text/number/email/...).
/// - [validator]:    دالة تحقق ترجع نص خطأ أو null.
/// - [enabled]:      هل الحقل قابل للتعديل (افتراضياً true).
class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.primary, size: 20)
                : null,
          ),
        ),
      ],
    );
  }
}

/// Simple section/list header
///
/// عنوان قسم بسيط في قائمة (مثلاً "آخر الإجازات" / "5 طلبات").
/// trailing اختياري للعدّ أو رابط "عرض الكل".
class ListSectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  const ListSectionTitle({super.key, required this.title, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// Loading indicator styled with brand color
///
/// مؤشر تحميل بسيط في وسط الشاشة بلون التطبيق الأساسي.
class Loader extends StatelessWidget {
  const Loader({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ),
    );
  }
}

/// Animated shimmer placeholder used while real content is fetching.
///
/// Pulses between two surface tones — no external package, no shader,
/// just a [ColorTween] driven by an [AnimationController] so the cost
/// is one rebuild per frame regardless of how many [Skeleton]s are on
/// screen.
///
/// "هيكل وهمي" (skeleton) ينبض بين لونين — يعرض شكل المحتوى أثناء التحميل.
/// خفيف الأداء جداً (لا shader، لا مكتبة خارجية).
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry margin;

  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.margin = EdgeInsets.zero,
  });

  /// Convenience for square/circle avatar placeholders.
  const Skeleton.box({
    super.key,
    required double size,
    this.radius = 12,
    this.margin = EdgeInsets.zero,
  })  : width = size,
        height = size;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final color = Color.lerp(
          AppColors.surfaceAlt,
          AppColors.border,
          _ctrl.value,
        );
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Single placeholder row used inside a [SkeletonList] — an avatar block,
/// a primary line, and a shorter secondary line. Wrapped in the same
/// glass card as real list items so the layout doesn't shift when data
/// arrives.
///
/// صف عنصر وهمي في قائمة skeleton: مربع صورة + سطرين نصيّين وهميّين.
/// يحاكي حجم البطاقة الحقيقية كي لا تقفز الواجهة عند وصول البيانات.
class SkeletonListTile extends StatelessWidget {
  final bool hasAvatar;
  final EdgeInsetsGeometry margin;
  const SkeletonListTile({
    super.key,
    this.hasAvatar = true,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasAvatar) ...const [
            Skeleton.box(size: 44),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: 160, height: 14),
                SizedBox(height: 8),
                Skeleton(width: 100, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Drop-in replacement for [Loader] on list-shaped screens. Renders
/// [count] [SkeletonListTile]s inside a scrollable list so the user
/// gets a sense of the upcoming layout instead of a centred spinner.
///
/// بديل لـ Loader في الشاشات التي بها قائمة — يعرض عدة عناصر وهمية
/// لإعطاء فكرة عن الشكل القادم بدلاً من spinner واحد في الوسط.
class SkeletonList extends StatelessWidget {
  final int count;
  final bool hasAvatar;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.count = 6,
    this.hasAvatar = true,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 24),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => SkeletonListTile(hasAvatar: hasAvatar),
    );
  }
}
