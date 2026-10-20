import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/persian_utils.dart';
import '../data/models.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionText, this.onAction});

  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        if (actionText != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                actionText!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class EmojiBadge extends StatelessWidget {
  const EmojiBadge(
    this.emoji, {
    super.key,
    this.seed = '',
    this.size = 56,
    this.radius = 14,
  });

  final String emoji;
  final String seed;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final g = AppColors.gradientFor(seed.isEmpty ? emoji : seed);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: g,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.46)),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars(
    this.rating, {
    super.key,
    this.size = 15,
    this.showValue = false,
  });

  final double rating;
  final double size;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i - 0.25
                ? Icons.star_rounded
                : (rating >= i - 0.75
                      ? Icons.star_half_rounded
                      : Icons.star_border_rounded),
            size: size,
            color: AppColors.accent,
          ),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(
            toFaDigits(rating.toStringAsFixed(1)),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.fa,
        style: TextStyle(
          color: status.color,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class PriceLabel extends StatelessWidget {
  const PriceLabel(
    this.amount, {
    super.key,
    this.fromPrefix = false,
    this.big = false,
  });
  final int amount;
  final bool fromPrefix;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${fromPrefix ? 'از ' : ''}${faPrice(amount)}',
      style: TextStyle(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w800,
        fontSize: big ? 17 : 13.5,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.body,
    this.actionText,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String? body;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.subtext,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
            ],
            if (actionText != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.value,
    this.color = AppColors.primary,
  });

  final String emoji;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11.5, color: AppColors.subtext),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, this.onTap, this.width});

  final ServiceItem service;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 86,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.gradientFor(service.id),
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      service.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  if (service.tags.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          service.tags.first,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      RatingStars(service.rating, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${toFaDigits(service.rating.toStringAsFixed(1))} (${toFaDigits(service.ratingCount)} نظر)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.subtext,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  PriceLabel(service.basePrice, fromPrefix: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return width != null ? SizedBox(width: width, child: card) : card;
  }
}

class ProviderCard extends StatelessWidget {
  const ProviderCard({super.key, required this.provider});
  final ProviderProfile provider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              EmojiBadge(provider.emoji, seed: provider.id, size: 48),
              const SizedBox(height: 8),
              Text(
                provider.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              RatingStars(provider.rating, size: 12),
              const SizedBox(height: 4),
              Text(
                '${toFaDigits(provider.jobsDone)} سرویس انجام‌شده',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.subtext,
                ),
              ),
              if (provider.verified) ...[
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: AppColors.info, size: 12),
                    SizedBox(width: 3),
                    Text(
                      'تاییدشده',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.footer,
  });

  final Booking booking;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  EmojiBadge(b.serviceEmoji, seed: b.serviceId, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.serviceTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${b.optionTitle} • ${b.confirmedDay ?? b.dayLabel}، ${b.confirmedSlot ?? b.timeSlot}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.subtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(b.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    b.providerName != null
                        ? '${b.providerEmoji ?? ''} ${b.providerName!}'
                        : 'منتظر پذیرش متخصص…',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subtext,
                    ),
                  ),
                  PriceLabel(b.totalPrice),
                ],
              ),
              if (footer != null) ...[const Divider(height: 20), footer!],
            ],
          ),
        ),
      ),
    );
  }
}
