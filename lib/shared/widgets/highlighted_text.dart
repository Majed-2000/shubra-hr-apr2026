// ============================================================================
// File: shared/widgets/highlighted_text.dart
// Purpose: RichText that highlights all (case-insensitive) substrings matching
//          a query. Used by notifications search (feature 12).
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? baseStyle;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.baseStyle,
    this.highlightStyle,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final base = baseStyle ??
        TextStyle(color: AppColors.onSurface, fontSize: 14, fontWeight: FontWeight.w500);
    final hl = highlightStyle ??
        base.copyWith(
          backgroundColor: AppColors.primary.withOpacity(0.18),
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        );

    if (query.isEmpty) {
      return Text(text, style: base, maxLines: maxLines, overflow: overflow);
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQ = query.toLowerCase();
    int i = 0;
    while (i < text.length) {
      final hit = lowerText.indexOf(lowerQ, i);
      if (hit < 0) {
        spans.add(TextSpan(text: text.substring(i), style: base));
        break;
      }
      if (hit > i) {
        spans.add(TextSpan(text: text.substring(i, hit), style: base));
      }
      spans.add(TextSpan(text: text.substring(hit, hit + query.length), style: hl));
      i = hit + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
