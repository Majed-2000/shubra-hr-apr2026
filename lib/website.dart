import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shared/utils/snackbar.dart';
import 'theme.dart';
import 'widgets.dart';

/// Website info — in-app card showing the company portal URL.
class WebsiteScreen extends StatelessWidget {
  const WebsiteScreen({super.key});

  static const _url = "cloud.shubra.net";

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      title: bi(context, ar: "الموقع الإلكتروني", en: "Website"),
      subtitle: bi(context,
          ar: "بوابة شبرا الرسمية", en: "Shubra official portal"),
      leadingIcon: Icons.public_rounded,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Image.asset("assets/shubra.png", height: 56),
                ),
                const SizedBox(height: 16),
                Text(
                  bi(context, ar: "شبرا", en: "Shubra"),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bi(context,
                      ar:
                          "الموقع الرسمي للشركة، حيث تُدار خدمات الموارد البشرية المتكاملة.",
                      en:
                          "The official company portal where our integrated HR services are managed."),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 18),
                _UrlPill(
                  url: _url,
                  onCopy: () {
                    Clipboard.setData(const ClipboardData(text: _url));
                    SnackbarHelpers.show(
                      context,
                      bi(context,
                          ar: "تم نسخ الرابط",
                          en: "Link copied"),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bi(context, ar: "للتواصل", en: "Contact"),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bi(context,
                      ar:
                          "لأي استفسار يخص الموارد البشرية، تواصل مع قسم الموارد البشرية داخل المنشأة.",
                      en:
                          "For any HR-related inquiry, please contact the HR department on-site."),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UrlPill extends StatelessWidget {
  final String url;
  final VoidCallback onCopy;
  const _UrlPill({required this.url, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onCopy,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                url,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.copy_rounded,
                  size: 14, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
