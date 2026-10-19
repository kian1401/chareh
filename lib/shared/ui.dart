/// 🧱 کامپوننت‌های مدرن مردارد-آاستایل چاره — تطبیقی بر اساس نمایشگر
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// پاسخ‌گرا: گوشی ≤۶۰۰، تبلت ≤۱۱۰۰، بزرگ‌تر=computador دسکتاپ
enum DeviceType { phone, tablet, desktop }

DeviceType deviceTypeOf(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 600) return DeviceType.phone;
  if (w < 1100) return DeviceType.tablet;
  return DeviceType.desktop;
}

/// کارت نرم بدون سایهٔ جنگ‌زده + شنیان ملایم
class PillowCard extends StatelessWidget {
  const PillowCard({super.key, required this.child, this.padding, this.onTap, this.color});
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEDEAF6)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// نمایشگر هوشمند تصویر یا اموجی — تطبیق سایز با صفحه
class SmartIcon extends StatelessWidget {
  const SmartIcon({super.key, required this.emoji, this.imageUrl = '', this.size = 48, this.radius = 14});
  final String emoji;
  final String imageUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;
    final isAsset = imageUrl.startsWith('assets/');
    Widget? img;
    if (hasImage) {
      img = isAsset
          ? Image.asset(imageUrl, fit: BoxFit.cover, width: size, height: size,
              errorBuilder: (_, __, ___) => _emoji())
          : Image.network(imageUrl, fit: BoxFit.cover, width: size, height: size,
              errorBuilder: (_, __, ___) => _emoji(), loadingBuilder: (c, w, p) => p == null ? w : _emoji());
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: img ?? _emoji()),
    );
  }

  Widget _emoji() => Container(
        width: size, height: size, alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            colors: [Color(0xFFF3F0FF), Color(0xFFE9E3FF)],
            begin: Alignment.topRight, end: Alignment.bottomLeft,
          ),
        ),
        child: Text(emoji, style: TextStyle(fontSize: size * 0.48)),
      );
}

/// گرید واکنش‌گرا — تعداد ستون بر اساس عرض نمایشگر
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({super.key, required this.count, required this.item, this.ratio = 1.0});
  final int count;
  final Widget Function(int i) item;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final t = deviceTypeOf(context);
    final cols = t == DeviceType.phone ? 2 : (t == DeviceType.tablet ? 4 : 6);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12,
        childAspectRatio: ratio,
      ),
      itemCount: count,
      itemBuilder: (_, i) => item(i),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.emoji, this.action});
  final String text;
  final String? emoji;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (emoji != null) Text(emoji!, style: const TextStyle(fontSize: 18)),
          if (emoji != null) const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// وقتی ورود لازم است — به‌جای دکمهٔ ورود دمو، به صفحه‌ی OTP واقعی می‌فرستد
class NeedLogin extends StatelessWidget {
  const NeedLogin({super.key, required this.emoji, required this.title, this.hint = ''});
  final String emoji, title, hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            if (hint.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(hint, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/auth'),
              icon: const Icon(Icons.login_rounded),
              label: const Text('ورود / ثبت‌نام با موبایل'),
            ),
          ],
        ),
      ),
    );
  }
}
