/// ابزارهای فارسی: اعداد فارسی، قیمت تومان، برچسب روز و بازه‌های زمانی
library;

String toFaDigits(Object? input) {
  if (input == null) return '';
  const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  var s = input.toString();
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(en[i], fa[i]);
  }
  return s;
}

/// جداکننده‌ی هزارگان فارسی: ۱٬۲۵۰٬۰۰۰
String faGrouped(num number) {
  final neg = number < 0;
  final digits = number.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    buf.write(digits[i]);
    final fromEnd = digits.length - i;
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write('٬');
  }
  final s = buf.toString();
  return toFaDigits(neg ? '-$s' : s);
}

String faPrice(num toman, {bool unit = true}) =>
    '${faGrouped(toman)}${unit ? ' تومان' : ''}';

const _weekdaysFa = <int, String>{
  DateTime.saturday: 'شنبه',
  DateTime.sunday: 'یکشنبه',
  DateTime.monday: 'دوشنبه',
  DateTime.tuesday: 'سه‌شنبه',
  DateTime.wednesday: 'چهارشنبه',
  DateTime.thursday: 'پنجشنبه',
  DateTime.friday: 'جمعه',
};

String faWeekday(DateTime d) => _weekdaysFa[d.weekday]!;

List<DateTime> nextDays([int count = 7]) {
  final n = DateTime.now();
  return List.generate(count, (i) => DateTime(n.year, n.month, n.day + i));
}

String faDayLabel(DateTime d) {
  final n = DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
  if (diff == 0) return 'امروز';
  if (diff == 1) return 'فردا';
  if (diff == 2) return 'پس‌فردا';
  return faWeekday(d);
}

/// بازه‌های زمانی رزرو
const kTimeSlots = <String>[
  '۸ تا ۱۰ صبح',
  '۱۰ تا ۱۲ ظهر',
  '۱۲ تا ۲ بعدازظهر',
  '۲ تا ۴ عصر',
  '۴ تا ۶ عصر',
  '۶ تا ۸ شب',
];

String timeAgoFa(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'همین حالا';
  if (diff.inMinutes < 60) return '${toFaDigits(diff.inMinutes)} دقیقه پیش';
  if (diff.inHours < 24) return '${toFaDigits(diff.inHours)} ساعت پیش';
  if (diff.inDays < 7) return '${toFaDigits(diff.inDays)} روز پیش';
  return '${toFaDigits(diff.inDays ~/ 7)} هفته پیش';
}

/// ⏰ بازه‌های زمانی پیشنهادی چاره (قابل توسعه در تنظیمات ادمین)
const charehTimeSlots = <String>[
  '۸ تا ۱۱ صبح',
  '۱۱ تا ۱۴',
  '۱۴ تا ۱۷',
  '۱۷ تا ۲۰',
  '۲۰ تا ۲۳',
];
