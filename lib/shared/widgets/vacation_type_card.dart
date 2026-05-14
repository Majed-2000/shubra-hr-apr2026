// ============================================================================
// ملف: shared/widgets/vacation_type_card.dart
// الغرض: بطاقة قابلة للاختيار تمثل نوع إجازة في شبكة الأنواع.
// متى تُستخدم: في request_leave.dart — شبكة 6 أنواع إجازات (خارجية، داخلية،
//             وفاة، زواج، أمومة، حج). البطاقة المختارة لها حدّ ولون أبرز.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme.dart';

/// Selectable card used in the leave-type grid on the request screen.
///
/// Renders an icon + localized label with a colored accent. Animates a
/// border / shadow change when [selected] flips so the user can tell at a
/// glance which type they've picked.
///
/// شرح المعاملات:
/// - [icon]:    أيقونة نوع الإجازة (مثلاً flight_takeoff للخارجية).
/// - [color]:   لون النغمة (يأتي من LeaveType.presentation).
/// - [label]:   اسم النوع المترجم.
/// - [selected]: هل هذه البطاقة هي المختارة حالياً.
/// - [onTap]:   دالة تُستدعى عند الضغط لاختيار النوع.
class VacationTypeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const VacationTypeCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        // AnimatedContainer يحرّك تغيير الحدود واللون عند الاختيار.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // خلفية أغمق عند الاختيار.
            color: selected ? color.withOpacity(0.10) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            // حد عريض ملوّن عند الاختيار، رفيع رمادي افتراضياً.
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.8 : 1,
            ),
            // ظل ملوّن للبطاقة المختارة لإبرازها.
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppShadows.soft,
          ),
          child: Row(
            children: [
              // مربع الأيقونة (يسار البطاقة).
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(selected ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              // الاسم النصي.
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              // علامة الصح تظهر فقط عند الاختيار.
              if (selected)
                Icon(Icons.check_circle_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
