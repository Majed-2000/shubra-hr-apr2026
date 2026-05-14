// ============================================================================
// ملف: shared/widgets/date_picker_tile.dart
// الغرض: مربع قابل للضغط يعرض تاريخاً (أو نص placeholder إن لم يُحدَّد بعد).
// متى يُستخدم: في نموذج طلب الإجازة (request_leave.dart) لاختيار تاريخ
//             بداية/نهاية الإجازة. يفتح date picker عند الضغط (عبر onTap).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme.dart';

/// Tappable date display used inside the leave-request form.
///
/// Shows a placeholder until [value] is set, then renders the date in
/// `dd MMM yyyy` format with the tile tinted in [color].
///
/// شرح المعاملات:
/// - [label]:        تسمية فوق التاريخ (مثل "من" أو "إلى").
/// - [icon]:         أيقونة بجانب الـ label.
/// - [value]:        التاريخ المحدد (أو null إن لم يُحدد بعد).
/// - [color]:        لون النغمة (يتغير حسب نوع الإجازة).
/// - [placeholder]:  نص يظهر مكان التاريخ إن كان value == null.
/// - [onTap]:        دالة تُستدعى عند الضغط (تفتح date picker).
class DatePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? value;
  final Color color;
  final String placeholder;
  final VoidCallback onTap;

  const DatePickerTile({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.color,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // hasValue يحدد المظهر: مُعبّأ (لون قوي) أو فارغ (لون باهت).
    final hasValue = value != null;
    return Material(
      color: Colors.transparent,
      // InkWell يعطي effect ضغط (ripple) عند اللمس.
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // خلفية ملونة خفيفة عند وجود قيمة، خلفية محايدة في غيره.
            color:
                hasValue ? color.withOpacity(0.08) : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: hasValue ? color.withOpacity(0.40) : AppColors.border,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: أيقونة + label.
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // النص السفلي: التاريخ بصيغة مقروءة "12 May 2026"، أو placeholder.
              Text(
                hasValue
                    ? DateFormat('dd MMM yyyy').format(value!)
                    : placeholder,
                style: TextStyle(
                  color: hasValue ? AppColors.onSurface : AppColors.muted,
                  fontSize: 14,
                  // التاريخ المحدد يظهر بخط ثقيل ليُبرَز.
                  fontWeight: hasValue ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
