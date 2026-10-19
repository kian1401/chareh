/// پایگاه‌داده‌ی درون‌حافظه‌ای دمو با استریم‌های واکنش‌گرا (شبیه‌سازی Firestore)
/// ⚙️ نسخهٔ «واقعی‌نما»: بدون کاربران/متخصصان جعلی — همه با OTP ثبت می‌شوند
library;

import 'dart:async';

import '../../core/utils/persian_utils.dart';
import '../models.dart';

class MockDb {
  static final MockDb _instance = MockDb._internal();
  factory MockDb() => _instance;
  MockDb._internal() {
    _seed();
  }

  // ─────────── موتور استریم ───────────
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<T> streamOf<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  void emit() => _changes.add(null);
  Future<void> latency([int ms = 250]) => Future<void>.delayed(Duration(milliseconds: ms));

  // ───────────────────────────── داده‌ها ─────────────────────────────
  AppUser? currentUser;
  String requestedRole = 'customer';

  /// 👥 رجیستری واقعی کاربران بر اساس شماره موبایل (بدون دموی جعلی)
  final Map<String, AppUser> usersByPhone = {};
  final List<ProviderProfile> providers = [];

  final List<Category> categories = [];
  final List<ServiceItem> services = [];
  final Map<String, List<Review>> _reviews = {};
  final List<City> cities = [];
  final AppSettings settings = AppSettings();
  final List<WalletTxn> walletTxns = [];
  final List<Booking> bookings = [];
  final Map<String, List<ChatMessage>> threads = {};
  final Map<String, List<EarningEntry>> _earnings = {};
  final Map<String, List<AddressItem>> addresses = {};
  final List<AppNotification> notifications = [];

  int _ctr = 0;
  String nextId([String p = 'id']) => '$p${(++_ctr).toString().padLeft(4, '0')}';

  List<Review> reviewsFor(String id) => _reviews[id] ?? [];
  List<EarningEntry> get earnings => _earnings['all'] ?? [];

  /// 🔐 ایجاد/یافتن کاربر با شماره (رفتار واقعی — هر شماره = یک حساب)
  AppUser userFromPhone(String phone, UserRole role, {String? referredBy}) {
    var u = usersByPhone[phone];
    if (u == null) {
      final code = 'CHR${(usersByPhone.length + 137) % 9999}';
      u = AppUser(
        id: nextId('u'),
        name: role == UserRole.provider ? 'متخصص چاره' : (role == UserRole.admin ? 'مدیر سیستم' : 'کاربر چاره'),
        phone: phone,
        role: role,
        referralCode: code,
        referredBy: referredBy,
        avatarEmoji: role == UserRole.provider ? '🧑‍🔧' : (role == UserRole.admin ? '🛡️' : '🌸'),
      );
      usersByPhone[phone] = u;
      // 📮 آدرس‌کتاب پیش‌فرض واقعی خالی
      addresses[u.id] = [];
      // 🎁 پاداش دعوت
      if (referredBy != null && referredBy.isNotEmpty) {
        final inviter = usersByPhone.values.where((x) => x.referralCode == referredBy).firstOrNull;
        if (inviter != null) {
          inviter.walletBalance += settings.referralReward;
          walletTxns.add(WalletTxn(
            id: nextId('w'), userId: inviter.id,
            title: 'پاداش دعوت از دوستان 🎁', amount: settings.referralReward,
            isBonus: true, at: DateTime.now(),
          ));
          walletTxns.add(WalletTxn(
            id: nextId('w'), userId: u.id,
            title: 'اعتبار هدیهٔ شروع (کد دعوت)', amount: settings.referralReward ~/ 2,
            isBonus: true, at: DateTime.now(),
          ));
          u.walletBalance += settings.referralReward ~/ 2;
        }
      }
    }
    return u;
  }

  // ───────────────────────────── سید ─────────────────────────────
  void _seed() {
    // 🏙️ شهرهای بزرگ — فقط ارومیه فعال (ادمین هر شهر را به‌طور زنده روشن می‌کند)
    final cityList = <(String, String)>[
      ('urmia', 'آذربایجان غربی'), ('tabriz', 'آذربایجان شرقی'), ('tehran', 'تهران'),
      ('mashhad', 'خراسان رضوی'), ('isfahan', 'اصفهان'), ('shiraz', 'فارس'),
      ('ahvaz', 'خوزستان'), ('qom', 'قم'), ('karaj', 'البرز'), ('kermanshah', 'کرمانشاه'),
      ('rasht', 'گیلان'), ('zahedan', 'سیستان و بلوچستان'), ('yazd', 'یزد'),
      ('hamedan', 'همدان'), ('kerman', 'کرمان'), ('ardabil', 'اردبیل'),
      ('bushehr', 'بوشهر'), ('birjand', 'خراسان جنوبی'), ('zanjan', 'زنجان'), ('sari', 'مازندران'),
    ];
    final cityNames = {
      'urmia': 'ارومیه', 'tabriz': 'تبریز', 'tehran': 'تهران', 'mashhad': 'مشهد',
      'isfahan': 'اصفهان', 'shiraz': 'شیراز', 'ahvaz': 'اهواز', 'qom': 'قم',
      'karaj': 'کرج', 'kermanshah': 'کرمانشاه', 'rasht': 'رشت', 'zahedan': 'زاهدان',
      'yazd': 'یزد', 'hamedan': 'همدان', 'kerman': 'کرمان', 'ardabil': 'اردبیل',
      'bushehr': 'بوشهر', 'birjand': 'بیرجند', 'zanjan': 'زنجان', 'sari': 'ساری',
    };
    for (final (id, prov) in cityList) {
      cities.add(City(id: id, title: cityNames[id]!, province: prov, active: id == 'urmia'));
    }

    // 🗂️ کاتالوگ تلفیقی — ذائقهٔ اصلی دسته‌بندی‌ها، زیرمجموعه‌شان ادغام شد
    ServiceItem svc(String id, String cat, String title, String desc, String emoji, int price,
            List<(String, String, int, String)> opts, [List<(String, int)>? adds, List<String>? tags]) =>
        ServiceItem(
          id: id, categoryId: cat, title: title, description: desc, emoji: emoji, basePrice: price,
          options: [for (var i = 0; i < opts.length; i++) ServiceOption(id: '${id}_o$i', title: opts[i].$1, subtitle: opts[i].$2, price: opts[i].$3, duration: opts[i].$4)],
          addOns: [for (var i = 0; i < (adds ?? []).length; i++) AddOn(id: '${id}_a$i', title: adds![i].$1, price: adds[i].$2)],
          tags: tags ?? [],
        );

    // 🛠️ ۱) تعمیرات لوازم خانگی (همهٔ لوازم: یخچال، لباسشویی، ظرفشویی...)
    categories.add(Category(id: 'c_appliance', title: 'تعمیرات لوازم خانگی', emoji: '🛠️', order: 1, featured: true));
    services.addAll([
      svc('s_fridge', 'c_appliance', 'تعمیر یخچال و فریزر ساید',
          'عیب‌یابی با گازسنجی، کمپرسور، ترموستات، برد کنترل. تعمیر در محل با ۹۰ روز گارانتی.', '🧊', 450000,
          [('تعمیر یخچال و فریزر', 'عیب‌یابی + تعمیر در محل', 450000, '۲ ساعت'),
           ('تعمیر سایدبای‌ساید', 'برد، کمپرسور، آی‌سی‌میکر', 650000, '۳ ساعت'),
           ('شارژ گاز یخچال', 'نشتی‌یابی + شارژ R134/R600', 700000, '۱٫۵ ساعت')],
          [('گارانتی ۹۰ روزه تعمیرات', 0), ('کابین داخلی شیشه' , 50000)], ['یخچال','سرد نشدن','کمپرسور','گاز']),
      svc('s_wash', 'c_appliance', 'تعمیر ماشین لباسشویی',
          'تعمیر تمام برندها: الکتروپمپی‌ها، برد کنترل، یاتاقان، سنسور قفل درب.', '👕', 400000,
          [('تعمیر لباسشویی در محل', 'عمودی و درب از جلو', 400000, '۲ ساعت'),
           ('تعویض یاتاقان و بلبرینگ', 'به‌همراه کاسه‌نمد', 750000, '۳ ساعت')],
          [('شست‌وشوی داخل دستگاه', 60000)], ['لباسشویی','تخلیه نمی‌شود','صدای داد']),
      svc('s_dish', 'c_appliance', 'تعمیر ماشین ظرفشویی',
          'پمپ تخلیه، هیتر، بازوی شست‌وشو، سنسورها. تست کامل پس از تعمیر.', '🍽️', 420000,
          [('تعمیر ظرفشویی در محل', 'همه برندها', 420000, '۲ ساعت')],
          [('تعمیر و تعویض شیر برقی', 0)], ['ظرفشویی','آب نمی‌کشد','نشتی']),
      svc('s_stove', 'c_appliance', 'تعمیر اجاق‌گاز و فر رومیزی',
          'فندک الکترونیکی، ترموکوپل، کلیدها، شیشهٔ باز. ایمنی‌یابی نشتی گاز.', '🔥', 350000,
          [('تعمیر اجاق‌گاز', 'صفحه‌ای یا مبله', 350000, '۱٫۵ ساعت')]),
      svc('s_tv', 'c_appliance', 'نصب و تعمیر تلویزیون LED/OLED',
          'نصب دیواری استاندارد، تنظیم آنتن، تعمیر برد و پنل.', '📺', 500000,
          [('نصب دیواری تلویزیون', 'تا ۶۵ اینچ + پایه‌فلز', 500000, '۱ ساعت'),
           ('تعمیر برد تلویزیون', 'در محل/کارگاه', 900000, '۱–۲ روز')]),
      svc('s_smallapp', 'c_appliance', 'تعمیرات لوازم کوچک (جارو، مایکرو...)',
          'جاروبرقی، مایکرو ویو، اتو، سرخ‌کن، قهوه‌ساز. قیمت پس از عیب‌یابی.', '🧹', 250000,
          [('عیب‌یابی + برآورد', 'آب‌عجمی کامل', 250000, '۱–۲ ساعت')]),
    ]);

    // ❄️ ۲) سرمایش و گرمایش (کولر، پکیج، شوفاژ)
    categories.add(Category(id: 'c_hvac', title: 'سرمایش و گرمایش', emoji: '❄️', order: 2));
    services.addAll([
      svc('s_cooler', 'c_hvac', 'سرویس اساسی کولر آبی',
          'شست‌واسی، تنظیم تسمه، تعویض پادی‌ها، سیم‌کشی سالم. قبل از فصل! 💦', '🌬️', 380000,
          [('سرویس کامل کولر آبی', 'شست‌وشو + پادها + روانکاری', 380000, '۱٫۵ ساعت'),
           ('تعمیر موتور کولر', 'کویل بلند بودن رابطه', 550000, '۲ ساعت')]),
      svc('s_package', 'c_hvac', 'سرویس و اسیدشویی پکیج',
          'اسیدشویی محلول استاندارد، تعمیر پمپ، سرویس مشعل، تنظیم فشار.', '🔧', 800000,
          [('اسیدشویی + سرویس دوره‌ای', 'همه برندها', 800000, '۲ ساعت')]),
      svc('s_radiator', 'c_hvac', 'نصب و هواگیری شوفاژ',
          'روشن نشدن؟ هواگیری، تعویض شیر، ترمیم نشتی لوله‌کشی.', '♨️', 300000,
          [('هواگیری + تست فشار', 'تمام خانه', 300000, '۱ ساعت')]),
    ]);

    // 🔌 ۳) برق‌کاری و تاسیسات برق
    categories.add(Category(id: 'c_elec', title: 'برق‌کاری و تاسیسات', emoji: '🔌', order: 3));
    services.addAll([
      svc('s_wiring', 'c_elec', 'سیم‌کشی و برق‌رسانی استاندارد',
          'توزیع مجدد، پریز و کلید اضافه، ترمیم نشتی برق، تورقی مهران و electrician.', '💡', 320000,
          [('عیب‌یابی مدار خانه', 'تست نشتی و جمع‌کننده', 320000, '۱–۲ ساعت')]),
      svc('s_board', 'c_elec', 'نصب فیوز، کلید و پریز ضد‌نشتی',
          'کلید محافظ جان (RCD)، کابل استاندارد، تابلو مینیاتوری.', '⚡', 280000,
          [('نصب کلید محافظ جان', 'با تست کامل', 280000, '۱ ساعت')]),
      svc('s_lamp', 'c_elec', 'نصب لوستر و روشنایی طراح',
          'لوستر سقفی/دیواری، نورپردازی پنهان، تست فاز.', '💡', 220000,
          [('نصب لوستر متوسط', 'تا ۸ شاخه', 220000, '۱ ساعت')]),
    ]);

    // 🔧 ۴) لوله‌کشی و تاسیسات آب
    categories.add(Category(id: 'c_plumb', title: 'لوله‌کشی و تخلیه آب', emoji: '🔧', order: 4));
    services.addAll([
      svc('s_leak', 'c_plumb', 'ترمیم نشتی لوله و شیرآلات',
          'تشخیص نشتی بدون تخریب، تعویض شیر سریع، ترمیم خط گرم/سرد.', '💧', 400000,
          [('ترمیم نشتی در محل', 'تشخیص + ترمیم', 400000, '۱–۲ ساعت')]),
      svc('s_drain', 'c_plumb', 'رفع انسداد و تخلیه فاضلاب',
          'بازکردن لولهٔ سریع، فاضلاب‌روی استاندارد، رفع بوی نامطبوع.', '🚿', 350000,
          [('رفع انسداد دستگاهی', 'آشپزخانه/حمام', 350000, '۱ ساعت')]),
    ]);

    // 🎨 ۵) نقاشی و بازسازی
    categories.add(Category(id: 'c_paint', title: 'نقاشی و بازسازی', emoji: '🎨', order: 5));
    services.addAll([
      svc('s_wall', 'c_paint', 'نقاشی ساختمان (آکریلیک/اولیه)',
          'بتونه‌کاری کامل دیوار در‌مدفن، آکریلیک درجه یک، متری یا روزمزد.', '🖌️', 900000,
          [('نقاشی واحد ۷۰ متری', 'شامل بتونه و پوشش دوج به هم', 900000, '۴ روز')]),
      svc('s_reno', 'c_paint', 'بازسازی حمام و آشپزخانه',
          'کاشی‌کاری، تخریب‌اجماع، کابینت و صفحه. برآورد کامل رایگان.', '🏠', 500000,
          [('برآورد رایگان در محل', 'کاشی و تخریب', 500000, '۱ ساعت')]),
    ]);

    // 🧹 ۶) نظافت و بهداشت
    categories.add(Category(id: 'c_clean', title: 'نظافت و سمپاشی', emoji: '🧹', order: 6));
    services.addAll([
      svc('s_deep', 'c_clean', 'نظافت به‌صورت عمیق (Deep Clean)',
          'تیم ۲ نفره با واکیوم صنعتی، آشپزخانه و سرویس‌ها، ۶ ساعت.', '✨', 1600000,
          [('دیتیل کلین واحد ۶۰ متری', 'کامل', 1600000, '۶ ساعت')]),
      svc('s_pest', 'c_clean', 'سمپاشی تخصصی (مشاوره پسیم)',
          'ژل‌کاری + داربست‌سازی، سم‌های کم‌بو، گارانتی ۶۰ روز.', '🐛', 700000,
          [('سمپاشی طبقه ویلا', 'تا ۱۵۰ متر', 700000, '۲ ساعت')]),
    ]);

    // ⭐ چند نمرهٔ دمو برای سرویس‌ها (بدون نقد جعلی کاربران)
    for (final s in services) {
      s.rating = 4.5 + (s.id.hashCode % 5) / 10;
      s.ratingCount = 0;
    }

    // 🛡️ حساب ادمین از پیش تعریف‌شده (فقط مدیر — کاربر جعلی نیست)
    usersByPhone['09000000000'] = AppUser(
      id: 'u_admin', name: 'مدیر سیستم چاره', phone: '09000000000',
      role: UserRole.admin, avatarEmoji: '🛡️', referralCode: 'CHRADMIN',
    );
  }

  // ─────────────────── کارشناس آفلاین (هوش کمکی سید) ───────────────────
  String assistantReply(String prompt) {
    final p = prompt;
    if (p.contains('کولر') || p.contains('سرما')) {
      return '💬 برای کولر آبی: چک کن تسمه سالم باشد، پادها را تعویض کرده باشی و آب اوقاف شود. اگر بوی بد می‌دهد تعویض آغشته به آلودگی لازم است. می‌خواهی یک متخصص سرمایش برایت بفرستم؟';
    }
    if (p.contains('لوله') || p.contains('نشتی')) {
      return 'شیر افقی را ببند و عکس از محل نشتی بگیر؛ عده‌ای دیرز یاسه‌ای را بعد از سندبض اینچی پوشش می‌دهند. برای ترمیم در محل رزرو بزن ✅';
    }
    return 'متشکرم! بر اساس شرح شما بهترین مسیر: رزرو عیب‌یابی در محل با سرویس‌دهندهٔ مربوطه است. می‌توانی سرویت را از دسته‌بندی‌ها انتخاب کنی یا سوال دقیق‌تری بپرسی 🙂';
  }

  /// 🤖 کارشناس آفلاین عیب‌یابی برای متخصص (تا وقتی Gemini وصل شود آفلاین است)
  String providerAiReply(String prompt) {
    final p = prompt;
    if (p.contains('سرد نمی')) {
      return '🔍 تشخیص «یخچال سرد نمی‌کند»:\n۱) برودت فریزر؟ → دمپر یا فن نیست\n۲) ترموستات را ۵ دقیقه تنظیم به مد می‌کنی → شنواری رله داری؟\n۳) بدترادف کمپرسور گرم؟ → کندانسور را با فوت بالا از پشت بشوی\n۴) اگر برفک داری → سیستم دیفراست (هیتر/سنسور/تایمر)\n🛠️ کالاهای حتمی: مولتی‌متر، گازسنج لیزر، منیفولد. ایمنی: برق را قطع کن قبل از فشار کمپرسور! ⚡';
    }
    if (p.contains('تخلیه') || p.contains('آب') && p.contains('لباس')) {
      return '🔍 تحلیل «لباسشویی تخلیه نمی‌کند»:\n۱) پمپ تخلیه را با ولتاژ مستقیم تست کن\n۲) فیلتر را باز — جسم خارجی؟\n۳) شلنگ تخلیه را با هوای فشرده پرید\n۴) اگر چراغ خطا می‌دهد → بردکی را در مد عیب‌یابی بخوان\n📏 نکته فنی: پمپ‌های پنتاک گریندال (Pentair) با ولتاژ اسیالاتور نیمه‌روش دارند — با چشم سریع تست نکن.';
    }
    if (p.contains('نقشه') || p.contains('نقشه')) {
      return '🗺️ برای خواندن نقشه‌های تاسیساتی:\n- لوله‌های آبی نرم: خط آبی ممتد\n- خط فاضلاب: خط‌چین حائز?\n- اتاق‌های گرم در آموزش‌بخش مخصوص است\n📸 اگر عکس نقشه را بارگزاری کنی، برداشت تقریبی‌ام را می‌دهم (پس از اتصال به Gemini Vision روشن می‌شود).';
    }
    return '🧠 من کارشناس عیب‌یابی چارهام. علائم دستگاه را دقیق بگو (برند، مدل، کم‌تایپ ریست) تا راهنمای قدم‌به‌قدم با تعمیر فوری بدهم. برای پاسخ‌های پیشرفته، کلید Gemini را ادمین در تنظیمات بچسباند.';
  }
}
