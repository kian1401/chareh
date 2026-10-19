import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/widgets.dart';
import '../auth/auth_state.dart';

/// فلو رزرو در ۳ مرحله: زمان ← آدرس ← بازبینی و پرداخت
class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key, required this.draft});
  final BookingDraft draft;

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  int _step = 0;
  bool _busy = false;
  Booking? _created;
  List<AddressItem> _addresses = [];
  bool _addressesLoaded = false;

  BookingDraft get d => widget.draft;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final auth = context.read<AuthState>();
    final list = await RepoHub.instance.misc.getAddresses(auth.user?.id ?? 'u_c1');
    if (!mounted) return;
    setState(() {
      _addresses = list;
      _addressesLoaded = true;
      d.address ??= list.where((a) => a.isDefault).firstOrNull ?? list.firstOrNull;
    });
  }

  bool get _canNext => switch (_step) {
        0 => d.day != null && d.timeSlot != null,
        1 => d.address != null,
        _ => true,
      };

  Future<void> _create() async {
    final auth = context.read<AuthState>();
    final messenger = ScaffoldMessenger.of(context);
    if (!auth.loggedIn) {
      final ok = await _showLoginSheet();
      if (ok != true || !mounted) return;
    }
    final user = context.read<AuthState>().user!;
    setState(() => _busy = true);
    try {
      final b = await RepoHub.instance.bookings.createBooking(draft: d, customer: user);
      setState(() {
        _created = b;
        _step = 3; // صفحه‌ی موفقیت
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('خطا در ثبت سفارش: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _showLoginSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('برای ثبت سفارش وارد شوید 🔐',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await ctx.read<AuthState>().demoLogin(UserRole.customer);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text('ورود سریع دمو (یک کلیک)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx, false);
                  await context.push('/auth');
                  if (mounted && context.read<AuthState>().loggedIn) _create();
                },
                icon: const Icon(Icons.phone_iphone_rounded),
                label: const Text('ورود با شماره موبایل'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addAddressDialog() {
    final titleCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('آدرس جدید 📍'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'عنوان', hintText: 'خانه، محل کار، منزل مادر…'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'آدرس کامل', hintText: 'شهر، محله، خیابان، کوچه، پلاک، واحد'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(
            onPressed: () async {
              if (textCtrl.text.trim().length < 10 || titleCtrl.text.trim().isEmpty) return;
              final auth = context.read<AuthState>();
              await RepoHub.instance.misc.addAddress(auth.user?.id ?? 'u_c1',
                  title: titleCtrl.text.trim(), text: textCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              _loadAddresses();
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = d.service!;

    if (_step == 3 && _created != null) {
      return _SuccessView(booking: _created!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('رزرو سرویس'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LinearProgressIndicator(
              value: (_step + 1) / 3,
              borderRadius: BorderRadius.circular(4),
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: .12),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // خلاصه‌ی سرویس بالای فلو
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  EmojiBadge(s.emoji, seed: s.id, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13.5)),
                        Text(
                          '${d.option!.title}${d.addOnIds.isNotEmpty ? ' + ${toFaDigits(d.addOnIds.length)} افزودنی' : ''}',
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.subtext),
                        ),
                      ],
                    ),
                  ),
                  PriceLabel(d.total),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_step == 0) ...[
            const SectionHeader('۱. چه روزی؟'),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final day = nextDays(7)[i];
                  final selected = d.day == day;
                  return ChoiceChip(
                    label: Text(i < 3 ? faDayLabel(day) : '${faWeekday(day)} ${toFaDigits(day.day)}'),
                    selected: selected,
                    onSelected: (_) => setState(() => d.day = day),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader('۲. چه ساعتی؟'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in kTimeSlots)
                  ChoiceChip(
                    label: Text(slot),
                    selected: d.timeSlot == slot,
                    onSelected: (_) => setState(() => d.timeSlot = slot),
                  ),
              ],
            ),
          ],

          if (_step == 1) ...[
            const SectionHeader('آدرس محل انجام سرویس'),
            const SizedBox(height: 12),
            if (!_addressesLoaded)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else ...[
              for (final a in _addresses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AddressCard(
                    address: a,
                    selected: d.address?.id == a.id,
                    onTap: () => setState(() => d.address = a),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _addAddressDialog,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('افزودن آدرس جدید'),
              ),
            ],
          ],

          if (_step == 2) ...[
            const SectionHeader('بازبینی نهایی'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _SummaryRow('سرویس', '${s.emoji} ${s.title}'),
                    _SummaryRow('پکیج', d.option!.title),
                    if (d.addOnIds.isNotEmpty)
                      _SummaryRow('افزودنی‌ها', [
                        for (final a in s.addOns)
                          if (d.addOnIds.contains(a.id)) a.title
                      ].join('، ')),
                    _SummaryRow('زمان', '${d.dayLabel} • ${d.timeSlot}'),
                    _SummaryRow('آدرس', d.address!.text),
                    const Divider(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('مبلغ نهایی',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        PriceLabel(d.total, big: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader('روش پرداخت'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final (icon, title, sub) in [
                    (Icons.credit_card_rounded, 'آنلاین', 'پرداخت امن با درگاه'),
                    (Icons.account_balance_wallet_outlined, 'کیف پول', 'موجودی: ${faPrice(context.watch<AuthState>().user?.walletBalance ?? 0)}'),
                    (Icons.payments_outlined, 'نقدی', 'پرداخت بعد از انجام کار'),
                  ])
                    RadioListTile<String>(
                      value: title,
                      groupValue: d.paymentMethod,
                      onChanged: (v) => setState(() => d.paymentMethod = v!),
                      secondary: Icon(icon, color: AppColors.primary),
                      title: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5)),
                      subtitle: Text(sub, style: const TextStyle(fontSize: 11.5)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('قبلی'),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _busy
                      ? null
                      : (_step < 2
                          ? (_canNext ? () => setState(() => _step++) : null)
                          : _create),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(_step < 2 ? 'ادامه' : 'ثبت نهایی سفارش 🎉'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.selected, required this.onTap});
  final AddressItem address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: .06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.subtext, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13)),
                      if (address.isDefault) ...[
                        const SizedBox(width: 6),
                        const Text('(پیش‌فرض)',
                            style:
                                TextStyle(fontSize: 10.5, color: AppColors.success)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address.text,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.subtext, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.subtext)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.7)),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 72),
                ),
              ),
              const SizedBox(height: 20),
              const Text('سفارش ثبت شد 🎉',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(
                'کد سفارش: ${toFaDigits(booking.id)}\n'
                '${booking.serviceTitle} • ${booking.dayLabel} • ${booking.timeSlot}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 13.5, height: 1.9),
              ),
              const SizedBox(height: 6),
              Text('به‌محض پذیرش متخصص، با اعلان خبرتان می‌کنیم 🔔',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.subtext)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => context.go('/c/orders'),
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('مشاهده‌ی سفارش‌های من'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.go('/c/home'),
                child: const Text('بازگشت به خانه'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
