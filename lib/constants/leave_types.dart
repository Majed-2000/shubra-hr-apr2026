import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';

/// All leave types the backend can return. Each entry binds together the
/// server `vccd` code, its localized label, the icon/color used in the type
/// grid, and policy flags consumed by the request form.
///
/// Keep this enum as the single source of truth for leave-code behavior:
/// switch statements on raw strings drift apart over time, this does not.
enum LeaveType {
  /// External vacation — counted against balance.
  outVac('01'),

  /// Internal vacation — counted against balance, default selection.
  inVac('02'),

  /// Bereavement leave.
  dieVac('04'),

  /// Marriage leave.
  marryVac('05'),

  /// Maternity / paternity leave.
  childVac('06'),

  /// Hajj leave.
  hajjVac('07');

  final String code;
  const LeaveType(this.code);

  static LeaveType? fromCode(String? code) {
    if (code == null) return null;
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }

  /// Regular vacation (out/in). These deduct from the user's balance and
  /// don't require an attachment.
  bool get isRegular => this == outVac || this == inVac;

  /// Special vacation types (bereavement, marriage, childbirth, hajj) are
  /// not deducted from the balance and require supporting documentation.
  bool get isSpecial => !isRegular;

  /// True for codes that the form must block until the user attaches a file.
  bool get requiresAttachment => switch (this) {
        dieVac || marryVac || childVac || hajjVac => true,
        _ => false,
      };

  /// Localized display name for the type grid and confirmation dialog.
  String localizedName(AppLocalizations t) => switch (this) {
        outVac => t.outvac,
        inVac => t.invac,
        dieVac => t.dievac,
        marryVac => t.marryvac,
        childVac => t.childvac,
        hajjVac => t.hajjvac,
      };

  /// Icon + accent color for the type grid card.
  (IconData, Color) get presentation => switch (this) {
        outVac => (Icons.flight_takeoff_rounded, AppColors.primary),
        inVac => (Icons.home_work_rounded, AppColors.secondary),
        dieVac => (Icons.heart_broken_rounded, AppColors.muted),
        marryVac => (Icons.favorite_rounded, Color(0xFFE11D48)),
        childVac => (Icons.child_care_rounded, AppColors.secondary),
        hajjVac => (Icons.mosque_rounded, AppColors.success),
      };
}
