// ============================================================================
// ملف: shared/widgets/rating_widgets.dart
// الغرض: مكوّنات بصرية مشتركة لشاشتَي تقييم الأداء (موظف + مدير).
// المحتوى:
//   - QuarterChip: بطاقة فترة قابلة للضغط (chip أفقي).
//   - ScoreBar: صف لعرض مكوّن واحد من التقييم مع شريط تقدّم متحرّك.
//   - ScoreTier: تصنيف النتيجة الإجمالية (ممتاز/جيد جداً/متوسط/يحتاج تحسين)
//                مع لون وأيقونة وعنوان مترجم.
// المستهلكون: emp_rate.dart, emp_rate_mgr.dart.
// لماذا في ملف مشترك: نفس الـ widgets تظهر في الشاشتين — التكرار يصعّب
//                    التطوّر المستقبلي ويؤدي إلى انحراف بصري بين الشاشتين.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme.dart';

/// بطاقة فترة تقييم قابلة للضغط — تعرض اسم الرُبع وتاريخه.
/// المختار يُبرَز بحدّ ولون مميّز + علامة صح.
class QuarterChip extends StatelessWidget {
  /// اسم الرُبع المترجم (مثلاً "الأول" أو "Q1").
  final String label;

  /// تاريخ بداية الرُبع كنص (يأتي من الـ backend كما هو).
  final String fromDate;

  /// تاريخ نهاية الرُبع كنص.
  final String toDate;

  /// هل هذه البطاقة هي المختارة حالياً؟
  final bool selected;

  /// يُستدعى عند الضغط لاختيار الرُبع.
  final VoidCallback onTap;

  const QuarterChip({
    super.key,
    required this.label,
    required this.fromDate,
    required this.toDate,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            // خلفية ملوّنة خفيفة عند الاختيار، رمادية محايدة افتراضياً.
            color: selected
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // علامة صح صغيرة تظهر فقط عند الاختيار.
                  if (selected)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 14),
                    ),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "$fromDate — $toDate",
                style: TextStyle(
                  color: selected
                      ? AppColors.primary.withOpacity(0.75)
                      : AppColors.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صف لعرض مكوّن واحد من مكوّنات التقييم — أيقونة + label + value/max
/// مع شريط تقدّم متحرّك يُملأ من 0 إلى النسبة الفعلية.
class ScoreBar extends StatelessWidget {
  /// أيقونة المكوّن (trending_up, star, schedule, ...).
  final IconData icon;

  /// تسمية المكوّن المترجمة.
  final String label;

  /// القيمة الحالية.
  final num value;

  /// الحد الأقصى المتوقّع لهذا المكوّن (يُستخدم لحساب نسبة الشريط).
  final num maxValue;

  /// اللون الأساسي للمكوّن (يُلوّن الأيقونة + الشريط + الرقم).
  final Color color;

  const ScoreBar({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // نسبة الـ progress (محدودة بين 0 و 1 لتجنّب overflow).
    final ratio = maxValue == 0
        ? 0.0
        : (value / maxValue).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // مربع الأيقونة (يسار).
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // "value / max" — القيمة بلون المكوّن، والـ max بالرمادي.
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: " / ${maxValue.toString()}",
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // شريط تقدّم متحرّك يُملأ من 0 إلى ratio عند ظهوره.
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.10),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

/// تصنيف النتيجة الإجمالية (0–100) إلى فئة بصرية: اسم + لون + أيقونة.
///
/// عتبات التصنيف:
/// - ≥ 85: ممتاز / Excellent (أخضر).
/// - ≥ 70: جيد جداً / Very good (turquoise).
/// - ≥ 50: متوسط / Average (برتقالي).
/// - < 50: يحتاج تحسين / Needs improvement (أحمر).
class ScoreTier {
  /// اسم الفئة بلغة الواجهة الحالية.
  final String label;

  /// لون الفئة (يُطبَّق على الحلقة + الرقم + الشارة).
  final Color color;

  /// أيقونة الفئة (شارة احترافية للممتاز، أعجبني للجيد، ...).
  final IconData icon;

  const ScoreTier(this.label, this.color, this.icon);

  /// مصنع يُعيد الفئة المناسبة بناءً على النتيجة ولغة الواجهة.
  /// [isArabic] = true → النص بالعربية، وإلا بالإنجليزية.
  factory ScoreTier.forTotal(num total, bool isArabic) {
    if (total >= 85) {
      return ScoreTier(
        isArabic ? "ممتاز" : "Excellent",
        AppColors.success,
        Icons.workspace_premium_rounded,
      );
    }
    if (total >= 70) {
      return ScoreTier(
        isArabic ? "جيد جداً" : "Very good",
        AppColors.primary,
        Icons.thumb_up_rounded,
      );
    }
    if (total >= 50) {
      return ScoreTier(
        isArabic ? "متوسط" : "Average",
        AppColors.warning,
        Icons.balance_rounded,
      );
    }
    return ScoreTier(
      isArabic ? "يحتاج تحسين" : "Needs improvement",
      AppColors.danger,
      Icons.priority_high_rounded,
    );
  }
}
