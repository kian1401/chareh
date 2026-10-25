import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../../shared/ui.dart';
import '../auth/auth_state.dart';

/// 🧾 گردش کامل ثبت سفارش — از صفر تا صد
/// شهر (گیت فعال/غیرفعال) ← نقشه ← چند روز/چند بازه ← کیف پول ← تعهد ضد دور زدن
class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key, required this.draft});
  final BookingDraft draft;

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  BookingDraft get d => widget.draft;
  bool _busy = false;
  List<AddressItem> _addresses = [];
  AppSettings _settings = AppSettings();
  List<City> _cities = [];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    final uid = auth.user?.id ?? '';
    RepoHub.instance.misc
        .getAddresses(uid)
        .then(
          (x) => setState(() {
            _addresses = x;
            if (x.isNotEmpty && d.address == null) d.address = x.first;
          }),
        );
    RepoHub.instance.misc.watchSettings().first.then((s) {
      setState(() => _settings = s);
      if (s.defaultCityId.isNotEmpty) d.cityId = s.defaultCityId;
    });
    RepoHub.instance.catalog.watchCities().first.then(
      (c) => setState(() => _cities = c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.loggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('ثبت سفارش')),
        body: const NeedLogin(
          emoji: '🧾',
          title: 'برای ثبت سفارش ابتدا وارد حساب شوید',
        ),
      );
    }
    final user = auth.user!;
    final IsTabletPlus = deviceTypeOf(context) != DeviceType.phone;
    final activeCity =
        _cities.where((c) => c.id == d.cityId).firstOrNull?.active ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('ثبت سفارش')),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: IsTabletPlus ? 48 : 16,
          vertical: 16,
        ),
        children: [
          _serviceCard(),
          const SizedBox(height: 16),
          const SectionTitle('کجا؟', emoji: '🏙️'),
          _cityPicker(activeCity),
          const SizedBox(height: 16),
          const SectionTitle('آدرس دقیق', emoji: '📍'),
          _addressPicker(activeCity),
          const SizedBox(height: 16),
          const SectionTitle('کدام روزها؟ (چندتاش را می‌شود)', emoji: '🗓️'),
          _dayPicker(),
          const SizedBox(height: 16),
          const SectionTitle('کدام بازه‌های ساعتی؟ (چندتایش)', emoji: '⏰'),
          _slotPicker(),
          const SizedBox(height: 16),
          const SectionTitle('روش پرداخت', emoji: '💳'),
          _paymentPicker(user),
          const SizedBox(height: 16),
          _antiBypassCard(),
          const SizedBox(height: 20),
          _summaryBar(user, activeCity),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── کارت سرویس و گزینه ──
  Widget _serviceCard() {
    final s = d.service!;
    return PillowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SmartIcon(emoji: s.emoji, imageUrl: s.imageUrl, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${d.option!.title} — ${faPrice(d.total)}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12.5,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (d.addOnIds.isNotEmpty) ...[
            const Divider(height: 20),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in s.addOns)
                  if (d.addOnIds.contains(a.id))
                    Chip(
                      label: Text(
                        '${a.title} +${faGrouped(a.price)}',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── انتخاب شهر + گیت فعال بودن ──
  Widget _cityPicker(bool activeCity) {
    if (_cities.isEmpty)
      return const Center(child: CircularProgressIndicator());
    final active = _cities.where((c) => c.active).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in active)
              ChoiceChip(
                avatar: const Text('🏙️'),
                label: Text('${c.title}'),
                selected: d.cityId == c.id,
                onSelected: (_) => setState(() => d.cityId = c.id),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ExpansionTile(
          dense: true,
          tilePadding: EdgeInsets.zero,
          title: const Text(
            'شهر دیگر به‌زودی مشرف آن است ⌛',
            style: TextStyle(fontSize: 12.5),
          ),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _cities.where((c) => !c.active))
                  Tooltip(
                    message: 'درخواست افتتاح «${c.title}» ثبت شد',
                    child: ActionChip(
                      avatar: const Text('🔒'),
                      label: Text(
                        c.title,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'شروع فعال سازی در ${c.title} به‌زودی منتشر می‌شود 🔔',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (!activeCity)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Text(
                '⚠️ فعلاً چاره فقط در شهر فعال (ارومیه) سرویس می‌دهد.',
                style: TextStyle(fontSize: 12.5, height: 1.7),
              ),
            ),
          ),
      ],
    );
  }

  // ── آدرس + انتخاب از روی نقشه ──
  Widget _addressPicker(bool cityOk) {
    final auth = context.read<AuthState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_addresses.isEmpty)
          PillowCard(
            child: Column(
              children: const [
                Text(
                  '🏡 هیچ آدرس ثبت‌شده‌ای ندارید',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'از روی نقشه یا دستی یک آدرس اضافه کنید',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in _addresses)
                ChoiceChip(
                  avatar: const Text('📍'),
                  label: Text(
                    '${a.title} — ${a.fullText}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: d.address?.id == a.id,
                  onSelected: (_) => setState(() => d.address = a),
                ),
            ],
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: cityOk
                  ? () => _openAddressDialog(mapFirst: true)
                  : null,
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('انتخاب از روی نقشه 🗺️'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: cityOk
                  ? () => _openAddressDialog(mapFirst: false)
                  : null,
              icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
              label: const Text('آدرس دستی'),
            ),
          ],
        ),
        if (auth.user != null && d.address != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '📌 مختصات: ${toFaDigits(d.address!.lat.toStringAsFixed(4))} ، ${toFaDigits(d.address!.lng.toStringAsFixed(4))}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ),
      ],
    );
  }

  Future<void> _openAddressDialog({required bool mapFirst}) async {
    final title = TextEditingController();
    final desc = TextEditingController();
    final plaque = TextEditingController();
    final floor = TextEditingController();
    final unit = TextEditingController();
    LatLng pin = const LatLng(37.5486, 45.0679); // 📍 مرکز ارومیه
    bool useMap = mapFirst;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setInner) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'افزودن آدرس جدید',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ToggleButtons(
                isSelected: [useMap, !useMap],
                borderRadius: BorderRadius.circular(12),
                onPressed: (i) => setInner(() => useMap = i == 0),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('🗺️ روی نقشه'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('⌨️ دستی'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (useMap)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 260,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: pin,
                        initialZoom: 14.5,
                        onTap: (_, pos) => setInner(() => pin = pos),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'app.chareh',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: pin,
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.location_pin,
                                color: Color(0xFFDC2626),
                                size: 44,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: const [
                    Icon(
                      Icons.edit_location_alt_rounded,
                      size: 40,
                      color: Color(0xFF9CA3AF),
                    ),
                    Text(
                      'آدرس خیابان و کوچه را بنویسید',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'عنوان آدرس (خانه، دفتر...)',
                  prefixIcon: Icon(Icons.home_work_rounded),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: desc,
                decoration: const InputDecoration(
                  labelText: 'آدرس دقیق (خیابان، کوچه)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 8),
              // 🏠 پلاک / طبقه / واحد
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: plaque,
                      decoration: const InputDecoration(
                        labelText: 'پلاک',
                        prefixIcon: Icon(Icons.signpost_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: floor,
                      decoration: const InputDecoration(
                        labelText: 'طبقه',
                        prefixIcon: Icon(Icons.stairs_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: unit,
                      decoration: const InputDecoration(
                        labelText: 'واحد',
                        prefixIcon: Icon(Icons.door_front_door_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  if (title.text.trim().isEmpty || desc.text.trim().isEmpty)
                    return;
                  Navigator.pop(context, true);
                },
                child: const Text('ثبت آدرس'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
    if (ok == true && mounted) {
      final auth = context.read<AuthState>();
      await RepoHub.instance.misc.addAddress(
        auth.user!.id,
        title: title.text.trim(),
        text: desc.text.trim(),
        lat: pin.latitude,
        lng: pin.longitude,
        cityId: d.cityId,
        plaque: plaque.text.trim(),
        floor: floor.text.trim(),
        unit: unit.text.trim(),
      );
      final fresh = await RepoHub.instance.misc.getAddresses(auth.user!.id);
      setState(() {
        _addresses = fresh;
        d.address = fresh.last;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('✅ آدرس ثبت شد')));
    }
  }

  // ── چند روز (چک‌باکس چیپس) ──
  Widget _dayPicker() {
    final days = nextDays(10);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final day in days)
          Builder(
            builder: (_) {
              final label = faDayLabel(day);
              final sel = d.days.contains(label);
              return FilterChip(
                avatar: Text(sel ? '✅' : '🗓️'),
                label: Text(label),
                selected: sel,
                onSelected: (_) => setState(() {
                  sel ? d.days.remove(label) : d.days.add(label);
                }),
              );
            },
          ),
      ],
    );
  }

  // ── چند بازهٔ ساعتی ──
  Widget _slotPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final slot in charehTimeSlots)
          Builder(
            builder: (_) {
              final sel = d.slots.contains(slot);
              return FilterChip(
                avatar: Text(sel ? '✅' : '⏰'),
                label: Text(slot),
                selected: sel,
                onSelected: (_) => setState(() {
                  sel ? d.slots.remove(slot) : d.slots.add(slot);
                }),
              );
            },
          ),
      ],
    );
  }

  // ── پرداخت: کیف پول با لطایف بونس ──
  Widget _paymentPicker(AppUser user) {
    final bonuses = _settings.bonusTiers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final method in ['آنلاین', 'کیف پول'])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PillowCard(
              onTap: () => setState(() => d.paymentMethod = method),
              color: d.paymentMethod == method ? const Color(0xFFF3F0FF) : null,
              child: Row(
                children: [
                  Icon(
                    d.paymentMethod == method
                        ? Icons.radio_button_on
                        : Icons.radio_button_off,
                    color: d.paymentMethod == method
                        ? const Color(0xFF6D28D9)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(method)),
                  if (method == 'کیف پول')
                    Text(
                      faPrice(user.walletBalance),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                      ),
                    ),
                  if (method == 'آنلاین')
                    const Text('درگاه زیبال/زرین‌پال 🪙 (به‌زودی)'),
                ],
              ),
            ),
          ),
        if (d.paymentMethod == 'کیف پول' && user.walletBalance < d.total) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '💡 موجودی ناکافی است. اگر از صفحهٔ کیف پول ${faGrouped(bonuses.isNotEmpty ? bonuses.first.minAmount : 100000)} تومان یا بیشتر شارژ کنید تا ${bonuses.isNotEmpty ? bonuses.last.bonusPercent : 15}٪ هدیه می‌گیرید!',
              style: const TextStyle(fontSize: 12, height: 1.7),
            ),
          ),
        ],
        if (bonuses.isNotEmpty)
          TextButton.icon(
            onPressed: () => context.push('/c/wallet'),
            icon: const Icon(Icons.savings_rounded, size: 18),
            label: const Text('شارژ کیف پول + گرفتن بونس 🎁'),
          ),
      ],
    );
  }

  // ── ضد دور زدن: تعهد و توضیح پل ارتباطی امن ──
  Widget _antiBypassCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🛡️ امنیت سفارش و پشتیبانی',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'شمارهٔ شما و متخصص تا زمان پذیرش سفارش محفوظ می‌ماند و تمام ارتباط از چت امن چاره قابل پیگیری است. دور زدن سیستم، عدم تضمین کار و بلوک حساب می‌شود.',
            style: TextStyle(fontSize: 12, height: 1.8),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () =>
                setState(() => d.agreementAccepted = !d.agreementAccepted),
            child: Row(
              children: [
                Checkbox(
                  value: d.agreementAccepted,
                  onChanged: (v) => setState(() => d.agreementAccepted = v!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'قوانین چاره و گارانتی را می‌پذیرم',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── خلاصه + ثبت نهایی ──
  Widget _summaryBar(AppUser user, bool cityOk) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEAF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'جمع کل: ',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const Spacer(),
              Text(
                faPrice(d.total),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          if (d.days.isNotEmpty)
            Text(
              '🗓️ ${d.days.join('، ')}',
              style: const TextStyle(fontSize: 12, height: 1.8),
            ),
          if (d.slots.isNotEmpty)
            Text(
              '⏰ ${d.slots.join('، ')}',
              style: const TextStyle(fontSize: 12, height: 1.8),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: (_busy || !d.ready || !cityOk)
                ? null
                : () => _submit(user),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(
              _busy
                  ? 'در حال ثبت...'
                  : (d.ready
                        ? (d.paymentMethod == 'کیف پول'
                              ? 'پرداخت از کیف پول و ثبت'
                              : 'ثبت و شروع نوبت‌یابی')
                        : 'کامل کنید: شهر/آدرس/روز/بازه/تعهد'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(AppUser user) async {
    setState(() => _busy = true);
    try {
      final b = await RepoHub.instance.bookings.createBooking(
        draft: d,
        customer: user,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🎉 سفارش ثبت شد! متخصص شهر شما به‌زودی زمان مناسب را تأیید می‌کند.',
          ),
        ),
      );
      context.go('/order/${b.id}');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _busy = false);
    }
  }
}
