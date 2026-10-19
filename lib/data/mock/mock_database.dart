/// پایگاه‌داده‌ی درون‌حافظه‌ای دمو با استریم‌های واکنش‌گرا (شبیه‌سازی Firestore)
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

  // ─────────── موتور استریم (هر تغییر، همه‌ی کوئری‌ها را تازه می‌کند) ───────────
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<T> streamOf<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  void emit() => _changes.add(null);

  Future<void> latency([int ms = 250]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  // ───────────────────────────── داده‌ها ─────────────────────────────
  AppUser? currentUser;

  final Map<String, AppUser> demoUsers = {
    'u_c1': AppUser(
      id: 'u_c1',
      name: 'نگار امیری',
      phone: '09121234567',
      role: UserRole.customer,
      avatarEmoji: '👩',
      walletBalance: 250000,
      favorites: ['s1', 's14'],
    ),
    'u_p1': AppUser(
      id: 'u_p1',
      name: 'حسین اکبری',
      phone: '09351112233',
      role: UserRole.provider,
      avatarEmoji: '👨‍🔧',
    ),
    'u_a1': AppUser(
      id: 'u_a1',
      name: 'مدیر سیستم',
      phone: '09000000000',
      role: UserRole.admin,
      avatarEmoji: '🛡️',
    ),
  };

  String requestedRole = 'customer';

  late final List<Category> categories;
  late final List<ServiceItem> services;
  late final List<ProviderProfile> providers;
  late final List<Booking> bookings;
  late final List<EarningEntry> earnings;
  late final List<AppNotification> notifications;
  final Map<String, List<ChatMessage>> threads = {};
  final Map<String, List<AddressItem>> addresses = {
    'u_c1': const [
      AddressItem(
        id: 'ad1',
        title: 'خانه',
        text: 'تهران، سعادت‌آباد، بلوار دریا، برج سپهر، واحد ۱۲',
        isDefault: true,
      ),
      AddressItem(
        id: 'ad2',
        title: 'محل کار',
        text: 'تهران، ونک، خیابان ملاصدرا، کوچه ۲۰، پلاک ۴، طبقه ۲',
      ),
    ],
  };

  double commissionRate = 0.15;
  int _seq = 500;
  String nextId(String prefix) => '$prefix${_seq++}';

  // ───────────────────────────── سید ─────────────────────────────
  void _seed() {
    categories = [
      Category(id: 'c1', title: 'نظافت و پاکسازی', emoji: '🧹'),
      Category(id: 'c2', title: 'لوازم خانگی و سرمایش', emoji: '❄️'),
      Category(id: 'c3', title: 'برق‌کاری و تأسیسات', emoji: '💡'),
      Category(id: 'c4', title: 'لوله‌کشی', emoji: '🚿'),
      Category(id: 'c5', title: 'نقاشی و دکور', emoji: '🎨'),
      Category(id: 'c6', title: 'آرایش و زیبایی در منزل', emoji: '💇‍♀️'),
      Category(id: 'c7', title: 'موبایل و کامپیوتر', emoji: '💻'),
      Category(id: 'c8', title: 'اسباب‌کشی و حمل‌ونقل', emoji: '🚚'),
      Category(id: 'c9', title: 'باغبانی و فضای سبز', emoji: '🌿'),
      Category(id: 'c10', title: 'سمپاشی', emoji: '🐜'),
    ];

    services = [
      ServiceItem(
        id: 's1', categoryId: 'c1', title: 'نظافت منزل ساعتی', emoji: '🧽',
        description: 'نظافت کامل اتاق‌ها، آشپزخانه و سرویس‌های بهداشتی توسط نیروی آموزش‌دیده و مورد اعتماد چاره. مواد و تجهیزات با متخصص است.',
        basePrice: 170000, rating: 4.8, ratingCount: 2310, jobsDone: 5400,
        options: const [
          ServiceOption(id: 'o1', title: '۴ ساعت', price: 680000, duration: '۴ ساعت'),
          ServiceOption(id: 'o2', title: '۶ ساعت', price: 960000, duration: '۶ ساعت'),
          ServiceOption(id: 'o3', title: '۸ ساعت (روز کامل)', price: 1250000, duration: '۸ ساعت'),
        ],
        addOns: const [
          AddOn(id: 'a1', title: 'شستشوی داخل یخچال', price: 150000),
          AddOn(id: 'a2', title: 'نظافت داخل کابینت‌ها', price: 120000),
          AddOn(id: 'a3', title: 'شیشه‌روبی بالکن', price: 100000),
        ],
        tags: ['پرتقاضا', 'اقتصادی'],
      ),
      ServiceItem(
        id: 's2', categoryId: 'c1', title: 'نظافت کامل + بخارشوی', emoji: '🫧',
        description: 'نظافت عمیق کل واحد شامل بخارشوی سطوح، سرویس‌ها، موتورخانه و مشاعات داخلی. مناسب اسباب‌کشی و تحویل واحد.',
        basePrice: 2400000, rating: 4.9, ratingCount: 860, jobsDone: 1450,
        options: const [
          ServiceOption(id: 'o1', title: 'واحد تا ۸۰ متر', price: 2400000, duration: '≈ ۶ ساعت'),
          ServiceOption(id: 'o2', title: 'واحد ۸۰ تا ۱۲۰ متر', price: 3200000, duration: '≈ ۸ ساعت'),
          ServiceOption(id: 'o3', title: 'دوبلکس / ویلایی', price: 4500000, duration: '۱ روز کامل'),
        ],
        addOns: const [
          AddOn(id: 'a1', title: 'شستشوی فرش به ازای هر ۶ متری', price: 420000),
          AddOn(id: 'a2', title: 'نماشویی پنجره‌ها', price: 250000),
        ],
        tags: ['عمیق', 'تحویل واحد'],
      ),
      ServiceItem(
        id: 's3', categoryId: 'c1', title: 'نظافت راه‌پله و مشاعات', emoji: '🏢',
        description: 'نظافت هفتگی راه‌پله، آسانسور، پارکینگ و ورودی ساختمان با قرارداد ماهانه.',
        basePrice: 900000, rating: 4.6, ratingCount: 320, jobsDone: 640,
        options: const [
          ServiceOption(id: 'o1', title: 'ساختمان تا ۸ واحد (ماهانه)', price: 900000),
          ServiceOption(id: 'o2', title: 'ساختمان ۹ تا ۱۶ واحد (ماهانه)', price: 1500000),
        ],
      ),
      ServiceItem(
        id: 's23', categoryId: 'c1', title: 'مبل‌شویی و خوشبوکننده', emoji: '🛋️',
        description: 'شستشوی مبلمان با دستگاه مبل‌شوی و مواد نانو، خشک‌کن سریع، خوشبوکننده رایگان.',
        basePrice: 520000, rating: 4.7, ratingCount: 540, jobsDone: 980,
        options: const [
          ServiceOption(id: 'o1', title: 'هر دست مبل (۷ نفره)', price: 520000, duration: '≈ ۲ ساعت'),
          ServiceOption(id: 'o2', title: 'مبل + شستشوی فرش ۶ متری', price: 890000, duration: '≈ ۳ ساعت'),
        ],
      ),
      ServiceItem(
        id: 's4', categoryId: 'c2', title: 'سرویس کولر آبی', emoji: '💨',
        description: 'سرویس دوره‌ای کولر آبی: شستشوی پوشال، روغن‌کاری، تنظیم تسمه و تست موتور. تمدید فصل را با خیال راحت شروع کنید.',
        basePrice: 450000, rating: 4.8, ratingCount: 1890, jobsDone: 4100,
        options: const [
          ServiceOption(id: 'o1', title: 'سرویس استاندارد', price: 450000, duration: '≈ ۱ ساعت'),
          ServiceOption(id: 'o2', title: 'سرویس کامل + روغن‌کاری', price: 650000, duration: '≈ ۹۰ دقیقه'),
          ServiceOption(id: 'o3', title: 'تعویض پوشال + تسمه', price: 950000, duration: '≈ ۲ ساعت'),
        ],
        addOns: const [
          AddOn(id: 'a1', title: 'تعمیر الکتروپمپ', price: 380000),
          AddOn(id: 'a2', title: 'عایق‌کاری داکت', price: 220000),
        ],
        tags: ['فصلی', 'پرتقاضا'],
      ),
      ServiceItem(
        id: 's5', categoryId: 'c2', title: 'تعمیر یخچال و فریزر', emoji: '🧊',
        description: 'عیب‌یابی و تعمیر تخصصی یخچال، فریزر و ساید توسط تکنسین مجرب با ضمانت ۹۰ روزه قطعات تعویضی.',
        basePrice: 350000, rating: 4.7, ratingCount: 1120, jobsDone: 2300,
        options: const [
          ServiceOption(id: 'o1', title: 'ویزیت و عیب‌یابی', price: 350000, duration: '≈ ۴۵ دقیقه'),
          ServiceOption(id: 'o2', title: 'عیب‌یابی + تعمیر (قطعات جدا)', price: 900000, duration: '≈ ۲ ساعت'),
        ],
      ),
      ServiceItem(
        id: 's6', categoryId: 'c2', title: 'نصب و سرویس اسپلیت', emoji: '❄️',
        description: 'نصب استاندارد کولر گازی با تخلیه‌ی صحیح، سرویس سالانه و شارژ گاز با دستگاه دیجیتال.',
        basePrice: 1200000, rating: 4.8, ratingCount: 970, jobsDone: 1600,
        options: const [
          ServiceOption(id: 'o1', title: 'سرویس سالانه', price: 1200000, duration: '≈ ۹۰ دقیقه'),
          ServiceOption(id: 'o2', title: 'شارژ گاز', price: 1600000, duration: '≈ ۱ ساعت'),
          ServiceOption(id: 'o3', title: 'نصب کامل', price: 2800000, duration: '≈ ۴ ساعت'),
        ],
      ),
      ServiceItem(
        id: 's7', categoryId: 'c2', title: 'تعمیر ماشین لباسشویی', emoji: '👕',
        description: 'تعمیر انواع ماشین لباسشویی در محل؛ عیب‌یابی دقیق و صورتحساب شفاف قبل از شروع کار.',
        basePrice: 380000, rating: 4.6, ratingCount: 745, jobsDone: 1500,
        options: const [
          ServiceOption(id: 'o1', title: 'ویزیت و عیب‌یابی', price: 380000),
          ServiceOption(id: 'o2', title: 'عیب‌یابی + تعمیر رایج (تسمه/پمپ)', price: 850000),
        ],
      ),
      ServiceItem(
        id: 's24', categoryId: 'c2', title: 'سرویس و تعمیر پکیج', emoji: '🔥',
        description: 'سرویس سالانه پکیج دیواری شامل رسوب‌زدایی، تست ایمنی و تنظیم شعله.',
        basePrice: 780000, rating: 4.9, ratingCount: 640, jobsDone: 1100,
        options: const [
          ServiceOption(id: 'o1', title: 'سرویس سالانه', price: 780000, duration: '≈ ۱ ساعت'),
          ServiceOption(id: 'o2', title: 'رسوب‌زدایی کامل مبدل', price: 1250000, duration: '≈ ۲ ساعت'),
        ],
      ),
      ServiceItem(
        id: 's8', categoryId: 'c3', title: 'برق‌کاری ساختمان', emoji: '🔌',
        description: 'کلیه خدمات برق ساختمان: نصب و تعویض کلید و پریز، رفع اتصالی، ارتباط برق‌رسانی و ایمن‌سازی.',
        basePrice: 180000, rating: 4.7, ratingCount: 830, jobsDone: 1900,
        options: const [
          ServiceOption(id: 'o1', title: 'نصب/تعویض کلید و پریز', price: 180000, duration: '≈ ۳۰ دقیقه'),
          ServiceOption(id: 'o2', title: 'تعویض کلید محافظ جان', price: 450000, duration: '≈ ۱ ساعت'),
          ServiceOption(id: 'o3', title: 'سیم‌کشی مجدد (برآورد پایه)', price: 2500000),
        ],
      ),
      ServiceItem(
        id: 's9', categoryId: 'c3', title: 'نصب لوستر و روشنایی', emoji: '💡',
        description: 'نصب انواع لوستر، چرخ سقفی و هالوژن با تراز دقیق و تست ایمنی.',
        basePrice: 350000, rating: 4.8, ratingCount: 420, jobsDone: 780,
        options: const [
          ServiceOption(id: 'o1', title: 'لوستر ساده', price: 350000, duration: '≈ ۴۵ دقیقه'),
          ServiceOption(id: 'o2', title: 'لوستر سنگین + مهار', price: 850000, duration: '≈ ۲ ساعت'),
        ],
      ),
      ServiceItem(
        id: 's10', categoryId: 'c4', title: 'رفع گرفتگی و خدمات لوله‌کشی', emoji: '🚿',
        description: 'رفع گرفتگی چاه و سینک با فنر برقی، تعویض شیرآلات، نصب سرویس بهداشتی. بدون خراب‌کاری و کثیف‌کاری.',
        basePrice: 380000, rating: 4.7, ratingCount: 1540, jobsDone: 3200,
        options: const [
          ServiceOption(id: 'o1', title: 'تعویض شیرآلات', price: 380000, duration: '≈ ۴۵ دقیقه'),
          ServiceOption(id: 'o2', title: 'رفع گرفتگی سینک/چاه', price: 650000, duration: '≈ ۱ ساعت'),
          ServiceOption(id: 'o3', title: 'نصب توالت فرنگی', price: 950000, duration: '≈ ۲ ساعت'),
        ],
      ),
      ServiceItem(
        id: 's11', categoryId: 'c4', title: 'تشخیص ترکیدگی لوله', emoji: '🕵️',
        description: 'تشخیص محل دقیق نشتی با دستگاه صوتی و حرارتی؛ فقط همان نقطه بازسازی می‌شود.',
        basePrice: 1400000, rating: 4.9, ratingCount: 380, jobsDone: 560,
        options: const [
          ServiceOption(id: 'o1', title: 'تشخیص با دستگاه', price: 1400000, duration: '≈ ۲ ساعت'),
        ],
      ),
      ServiceItem(
        id: 's12', categoryId: 'c5', title: 'نقاشی ساختمان', emoji: '🖌️',
        description: 'نقاشی کامل واحد با نقاشان باتجربه؛ تحویل تمیز بدون لکه با قرارداد زمان‌بندی مشخص.',
        basePrice: 1200000, rating: 4.6, ratingCount: 290, jobsDone: 410,
        options: const [
          ServiceOption(id: 'o1', title: 'نقاشی سقف و دیوار (هر ۱۰ مترمربع)', price: 1200000),
          ServiceOption(id: 'o2', title: 'بتونه + نقاشی (هر ۱۰ مترمربع)', price: 1950000),
        ],
      ),
      ServiceItem(
        id: 's13', categoryId: 'c5', title: 'نصب کاغذ دیواری', emoji: '🖼️',
        description: 'نصب حرفه‌ای کاغذدیواری بدون حباب؛ ابزار و چسب درجه‌یک با متخصص است.',
        basePrice: 450000, rating: 4.8, ratingCount: 210, jobsDone: 300,
        options: const [
          ServiceOption(id: 'o1', title: 'نصب هر رول', price: 450000, duration: '≈ ۴۰ دقیقه'),
        ],
      ),
      ServiceItem(
        id: 's14', categoryId: 'c6', title: 'پاکسازی پوست در منزل', emoji: '🧖‍♀️',
        description: 'پاکسازی تخصصی پوست با محصولات اورجینال در منزل شما؛ بدون نیاز به مراجعه حضوری.',
        basePrice: 980000, rating: 4.9, ratingCount: 690, jobsDone: 1250,
        options: const [
          ServiceOption(id: 'o1', title: 'پاکسازی کلاسیک (۶ مرحله)', price: 980000, duration: '≈ ۷۵ دقیقه'),
          ServiceOption(id: 'o2', title: 'پاکسازی VIP + ماسک کلاژن', price: 1850000, duration: '≈ ۲ ساعت'),
        ],
        addOns: const [
          AddOn(id: 'a1', title: 'ابرو (بند + فرم)', price: 250000),
          AddOn(id: 'a2', title: 'اپیلاسیون صورت', price: 200000),
        ],
        tags: ['بانوان', 'محبوب'],
      ),
      ServiceItem(
        id: 's15', categoryId: 'c6', title: 'خدمات آرایشگری بانوان در منزل', emoji: '💅',
        description: 'کوتاهی مو، رنگ و لایت، بافت و شینیون توسط آرایشگران حرفه‌ای در منزل.',
        basePrice: 420000, rating: 4.7, ratingCount: 510, jobsDone: 890,
        options: const [
          ServiceOption(id: 'o1', title: 'اصلاح با بند (صورت)', price: 420000, duration: '≈ ۳۰ دقیقه'),
          ServiceOption(id: 'o2', title: 'کوتاهی موی بانوان', price: 650000, duration: '≈ ۱ ساعت'),
        ],
      ),
      ServiceItem(
        id: 's16', categoryId: 'c7', title: 'تعمیر موبایل', emoji: '📱',
        description: 'تعمیر تخصصی موبایل در محل یا دریافت از درب منزل؛ ال‌سی‌دی و باتری با گارانتی.',
        basePrice: 850000, rating: 4.6, ratingCount: 930, jobsDone: 1700,
        options: const [
          ServiceOption(id: 'o1', title: 'تعویض باتری', price: 850000, duration: '≈ ۴۵ دقیقه'),
          ServiceOption(id: 'o2', title: 'تعویض ال‌سی‌دی (شروع از)', price: 1500000, duration: '≈ ۹۰ دقیقه'),
        ],
      ),
      ServiceItem(
        id: 's17', categoryId: 'c7', title: 'نصب ویندوز و راه‌اندازی شبکه', emoji: '🖥️',
        description: 'نصب ویندوز اورجینال، درایور و نرم‌افزارهای کاربردی + راه‌اندازی شبکه‌ی خانگی/مودم.',
        basePrice: 450000, rating: 4.8, ratingCount: 380, jobsDone: 620,
        options: const [
          ServiceOption(id: 'o1', title: 'نصب ویندوز + درایور', price: 450000, duration: '≈ ۱ ساعت'),
          ServiceOption(id: 'o2', title: 'راه‌اندازی کامل + پرینتر و شبکه', price: 750000, duration: '≈ ۲ ساعت'),
        ],
      ),
      ServiceItem(
        id: 's18', categoryId: 'c8', title: 'اسباب‌کشی با وانت و کارگر', emoji: '🛻',
        description: 'حمل اثاثیه درون‌شهری با وانت/نیسان، کارگر حمل و راننده بابیمه.',
        basePrice: 2400000, rating: 4.5, ratingCount: 460, jobsDone: 700,
        options: const [
          ServiceOption(id: 'o1', title: 'وانت درون‌شهری (پایه)', price: 2400000, duration: '≈ ۳ ساعت'),
          ServiceOption(id: 'o2', title: 'نیسان + ۲ کارگر', price: 4200000, duration: '≈ ۵ ساعت'),
        ],
        addOns: const [AddOn(id: 'a1', title: 'کارگر اضافه (هر ساعت)', price: 380000)],
      ),
      ServiceItem(
        id: 's19', categoryId: 'c8', title: 'بسته‌بندی اثاثیه', emoji: '📦',
        description: 'بسته‌بندی اصولی لوازم با کارتون چندلایه، حباب‌دار و لیبل اتاق‌ها.',
        basePrice: 420000, rating: 4.7, ratingCount: 180, jobsDone: 260,
        options: const [
          ServiceOption(id: 'o1', title: 'بسته‌بندی ساعتی (۱ نفر)', price: 420000),
        ],
      ),
      ServiceItem(
        id: 's20', categoryId: 'c9', title: 'هرس و باغبانی', emoji: '✂️',
        description: 'هرس اصولی درختان، چیدمان فضای سبز، تعویض خاک گلدان‌ها و سم‌پاشی گیاهی.',
        basePrice: 480000, rating: 4.6, ratingCount: 150, jobsDone: 240,
        options: const [
          ServiceOption(id: 'o1', title: 'باغبان ساعتی', price: 480000),
          ServiceOption(id: 'o2', title: 'هرس تا ۱۰ درخت', price: 1500000),
        ],
      ),
      ServiceItem(
        id: 's21', categoryId: 'c10', title: 'سمپاشی ساختمان', emoji: '🦟',
        description: 'سم‌پاشی تضمینی در برابر سوسک، مورچه و پشه با سموم استاندارد و بی‌خطر برای کودک و حیوان خانگی.',
        basePrice: 890000, rating: 4.7, ratingCount: 330, jobsDone: 520,
        options: const [
          ServiceOption(id: 'o1', title: 'واحد تا ۸۰ متر', price: 890000, duration: '≈ ۴۰ دقیقه'),
          ServiceOption(id: 'o2', title: 'واحد ۸۰ تا ۱۵۰ متر', price: 1350000, duration: '≈ ۱ ساعت'),
        ],
      ),
    ];

    providers = [
      ProviderProfile(id: 'p1', name: 'مهدی رضایی', emoji: '👨‍🔧', skills: ['برق‌کاری ساختمان', 'نصب لوستر و روشنایی'], rating: 4.8, jobsDone: 436),
      ProviderProfile(id: 'p2', name: 'سارا محمدی', emoji: '👩', skills: ['نظافت منزل ساعتی', 'نظافت کامل + بخارشوی'], rating: 4.9, jobsDone: 812),
      ProviderProfile(id: 'p3', name: 'علی کریمی', emoji: '👨‍🔧', skills: ['رفع گرفتگی و خدمات لوله‌کشی', 'تشخیص ترکیدگی لوله'], rating: 4.7, jobsDone: 655),
      ProviderProfile(id: 'p4', name: 'نرگس احمدی', emoji: '👩', skills: ['نظافت منزل ساعتی', 'مبل‌شویی و خوشبوکننده'], rating: 4.8, jobsDone: 503),
      ProviderProfile(id: 'p5', name: 'رضا قاسمی', emoji: '👨‍💻', skills: ['تعمیر موبایل', 'نصب ویندوز و راه‌اندازی شبکه'], rating: 4.6, jobsDone: 388),
      ProviderProfile(id: 'p6', name: 'فاطمه حسینی', emoji: '💇‍♀️', skills: ['پاکسازی پوست در منزل', 'خدمات آرایشگری بانوان در منزل'], rating: 4.9, jobsDone: 721),
      ProviderProfile(id: 'p7', name: 'حسین اکبری', emoji: '👨‍🔧', skills: ['سرویس کولر آبی', 'تعمیر یخچال و فریزر', 'نصب و سرویس اسپلیت', 'سرویس و تعمیر پکیج'], rating: 4.8, jobsDone: 934, level: 'برتر'),
      ProviderProfile(id: 'p8', name: 'لیلا نادری', emoji: '🎨', skills: ['نقاشی ساختمان', 'نصب کاغذ دیواری'], rating: 4.7, jobsDone: 214, verified: false),
    ];

    final now = DateTime.now();
    bookings = [
      Booking(
        id: 'b100', serviceId: 's4', serviceTitle: 'سرویس کولر آبی', serviceEmoji: '💨',
        optionTitle: 'سرویس کامل + روغن‌کاری', customerId: 'u_c1', customerName: 'نگار امیری',
        providerId: 'p7', providerName: 'حسین اکبری', providerEmoji: '👨‍🔧',
        dayLabel: 'هفته‌ی گذشته', timeSlot: '۱۰ تا ۱۲ ظهر',
        addressText: 'تهران، سعادت‌آباد، بلوار دریا، برج سپهر، واحد ۱۲',
        status: BookingStatus.completed, totalPrice: 650000,
        createdAt: now.subtract(const Duration(days: 9)),
        rating: 5, review: 'خیلی حرفه‌ای و خوش‌قول؛ کولر مثل روز اول شد.',
        timeline: [
          StatusEvent(BookingStatus.pending, now.subtract(const Duration(days: 9, hours: 2))),
          StatusEvent(BookingStatus.accepted, now.subtract(const Duration(days: 9, hours: 1))),
          StatusEvent(BookingStatus.completed, now.subtract(const Duration(days: 9))),
        ],
      ),
      Booking(
        id: 'b101', serviceId: 's1', serviceTitle: 'نظافت منزل ساعتی', serviceEmoji: '🧽',
        optionTitle: '۶ ساعت', customerId: 'u_c1', customerName: 'نگار امیری',
        providerId: 'p2', providerName: 'سارا محمدی', providerEmoji: '👩',
        dayLabel: 'فردا', timeSlot: '۸ تا ۱۰ صبح',
        addressText: 'تهران، سعادت‌آباد، بلوار دریا، برج سپهر، واحد ۱۲',
        status: BookingStatus.accepted, totalPrice: 960000,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      // ── درخواست‌های باز بازار برای پرتال سرویس‌دهنده ──
      Booking(
        id: 'b200', serviceId: 's5', serviceTitle: 'تعمیر یخچال و فریزر', serviceEmoji: '🧊',
        optionTitle: 'عیب‌یابی + تعمیر (قطعات جدا)', customerId: 'u_c9', customerName: 'مریم صالحی',
        dayLabel: 'امروز', timeSlot: '۲ تا ۴ عصر',
        addressText: 'تهران، جهرمی، خیابان شهید مطهری، کوچه ۸، پلاک ۱۵',
        status: BookingStatus.pending, totalPrice: 900000,
        createdAt: now.subtract(const Duration(minutes: 40)),
      ),
      Booking(
        id: 'b201', serviceId: 's6', serviceTitle: 'نصب و سرویس اسپلیت', serviceEmoji: '❄️',
        optionTitle: 'نصب کامل', customerId: 'u_c8', customerName: 'بهرام رادمهر',
        dayLabel: 'فردا', timeSlot: '۱۰ تا ۱۲ ظهر',
        addressText: 'تهران، پاسداران، خیابان گلستان دوم، برج پارمیدا، واحد ۵',
        status: BookingStatus.pending, totalPrice: 2800000,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Booking(
        id: 'b202', serviceId: 's4', serviceTitle: 'سرویس کولر آبی', serviceEmoji: '💨',
        optionTitle: 'سرویس استاندارد', customerId: 'u_c7', customerName: 'کیان توکلی',
        providerId: 'p7', providerName: 'حسین اکبری', providerEmoji: '👨‍🔧',
        dayLabel: 'امروز', timeSlot: '۱۲ تا ۲ بعدازظهر',
        addressText: 'تهران، سعادت‌آباد، میدان بهرود، کوچه ۲۰، پلاک ۹',
        status: BookingStatus.inProgress, totalPrice: 450000,
        createdAt: now.subtract(const Duration(hours: 3)),
        timeline: [
          StatusEvent(BookingStatus.pending, now.subtract(const Duration(hours: 3))),
          StatusEvent(BookingStatus.accepted, now.subtract(const Duration(hours: 2, minutes: 40))),
          StatusEvent(BookingStatus.onTheWay, now.subtract(const Duration(hours: 1))),
          StatusEvent(BookingStatus.inProgress, now.subtract(const Duration(minutes: 25))),
        ],
      ),
    ];

    earnings = [
      EarningEntry(id: 'e1', title: 'سرویس کولر آبی — سرویس کامل', dateLabel: '۳ روز پیش', amount: 552500, settled: true),
      EarningEntry(id: 'e2', title: 'تعمیر یخچال — تعویض سنسور', dateLabel: '۵ روز پیش', amount: 765000, settled: true),
      EarningEntry(id: 'e3', title: 'سرویس اسپلیت — شارژ گاز', dateLabel: '۱ هفته پیش', amount: 1360000, settled: true),
      EarningEntry(id: 'e4', title: 'سرویس کولر آبی — استاندارد', dateLabel: '۱ هفته پیش', amount: 382500, settled: true),
      EarningEntry(id: 'e5', title: 'نصب اسپلیت کامل', dateLabel: '۲ هفته پیش', amount: 2380000, settled: true),
    ];

    notifications = [
      AppNotification(id: 'n1', title: 'سفارش شما تایید شد ✅', body: 'سارا محمدی فردا ساعت ۸ تا ۱۰ صبح برای نظافت منزل می‌آید.', emoji: '✅', at: now.subtract(const Duration(hours: 5))),
      AppNotification(id: 'n2', title: 'پیشنهاد ویژه 🎁', body: '۲۵٪ تخفیف سرویس کولر آبی تا پایان هفته — فقط با کد SUMMER25', emoji: '🎁', at: now.subtract(const Duration(days: 1)), unread: false),
      AppNotification(id: 'n3', title: 'کیف پول شارژ شد 💳', body: 'مبلغ ۲۵۰٬۰۰۰ تومان به کیف پول شما اضافه شد.', emoji: '💳', at: now.subtract(const Duration(days: 3)), unread: false),
    ];

    threads['t_b101'] = [
      ChatMessage(id: 'm1', threadId: 't_b101', isMine: false, text: 'سلام خانم امیری، وقت بخیر 🌷 من سارا هستم، متخصص نظافت. برای فردا صبح برنامه‌ریزی کردم.', at: now.subtract(const Duration(hours: 4))),
      ChatMessage(id: 'm2', threadId: 't_b101', isMine: true, text: 'سلام، ممنون 🙏 لطفاً مواد شوینده همراهتون باشه؟', at: now.subtract(const Duration(hours: 3, minutes: 50))),
      ChatMessage(id: 'm3', threadId: 't_b101', isMine: false, text: 'حتماً، همه‌ی مواد و تجهیزات با منه 👍', at: now.subtract(const Duration(hours: 3, minutes: 45))),
    ];
  }

  // ─────────────────────── نظرات (تولید از مخزن) ───────────────────────
  static const _reviewPool = [
    ('خیلی خوش‌قول و تمیز بود، حتماً دوباره رزرو می‌کنم 🌟', 'مریم ک.', 5.0),
    ('کارش عالی بود فقط کمی دیر رسید.', 'امیر ت.', 4.0),
    ('حرفه‌ای و محترم؛ قیمت هم منصفانه بود.', 'سارا ن.', 5.0),
    ('از رزرو تا پایان کار همه‌چیز شفاف بود.', 'رضا م.', 4.5),
    ('کیفیت خوب، ولی جزئیات می‌توانست بهتر شود.', 'حمید ع.', 3.5),
    ('عالی! واقعاً ممنون از تیم چاره 💜', 'ندا ف.', 5.0),
    ('دقیق و مرتب، کاملاً راضی بودم.', 'پارسا د.', 4.5),
    ('تجربه‌ی خوبی بود، پیشنهاد می‌کنم.', 'الهه ب.', 4.0),
  ];

  List<Review> reviewsFor(String serviceId) {
    final seed = serviceId.codeUnits.fold<int>(0, (a, b) => a + b);
    final count = 3 + seed % 4;
    return List.generate(count, (i) {
      final r = _reviewPool[(seed + i) % _reviewPool.length];
      return Review(
        id: 'rv_$serviceId$i',
        author: r.$2,
        rating: r.$3,
        text: r.$1,
        dateLabel: '${toFaDigits(2 + ((seed + i) % 6) * 9)} روز پیش',
      );
    });
  }

  // ─────────────────── دستیار هوشمند (پاسخ قاعده‌محور دمو) ───────────────────
  String assistantReply(String input) {
    final q = input.trim();
    bool has(String k) => q.contains(k);
    if (has('سلام') || q.length < 3) {
      return 'سلام! من دستیار چارهم 🤖 می‌توانم در انتخاب سرویس، قیمت، رزرو و پیگیری سفارش کمکتان کنم. مثلاً بپرسید: «قیمت نظافت منزل چقدره؟»';
    }
    if (has('نظافت') || has('تمیز')) {
      return 'برای نظافت منزل دو گزینه‌داریم 🧽\n\n• نظافت ساعتی: از ۱۷۰ هزار تومان/ساعت — مثل پکیج ۴ ساعته ۶۸۰ هزار تومان\n• نظافت کامل + بخارشوی: از ۲٫۴ میلیون تومان برای واحد تا ۸۰ متر\n\nهر دو با نیروی آموزش‌دیده و مواد رسمی انجام می‌شود. از صفحه سرویس می‌توانید زمان هم رزرو کنید.';
    }
    if (has('کولر') || has('اسپلیت') || has('سرما')) {
      return 'برای خنک‌کننده‌ها این پیشنهادها را داریم ❄️\n\n• سرویس کولر آبی: از ۴۵۰ هزار تومان\n• سرویس/نصب اسپلیت: سرویس سالانه ۱٫۲ میلیون، نصب کامل ۲٫۸ میلیون تومان\n\nمتخصص تاییدشده با ضمانت انجام کار می‌آید.';
    }
    if (has('قیمت') || has('هزینه') || has('چقدر')) {
      return 'قیمت‌ها کاملاً شفاف‌اند: روی کارت هر سرویس «شروع قیمت از» را می‌بینید؛ قبل از رزرو، پکیج و آپشن‌ها را انتخاب می‌کنید و مبلغ نهایی همان لحظه محاسبه می‌شود 💰 پرداخت آنلاین، با کیف پول یا نقدی بعد از انجام کار ممکن است.';
    }
    if (has('لغو') || has('کنسل')) {
      return 'لغو تا ۲ ساعت قبل از شروع سرویس کاملاً رایگان است و مبلغ خودکار به کیف پول‌تان برمی‌گردد. کافی است در صفحه سفارش روی «لغو سفارش» بزنید.';
    }
    if (has('سفارش') || has('پیگیری')) {
      return 'در تب «سفارش‌ها» می‌توانید وضعیت زنده را ببینید: از پذیرش توسط متخصص تا «در راه است»، «در حال انجام» و «تکمیل». برای هر مرحله اعلان هم می‌گیرید 🔔';
    }
    if (has('آرایش') || has('زیبایی') || has('پوست')) {
      return 'خدمات زیبایی در منزل 💇‍♀️: پاکسازی پوست کلاسیک ۹۸۰ هزار و پکیج VIP با ماسک کلاژن ۱٫۸۵ میلیون تومان. آرایشگران باتجربه با ابزار استریل‌شده می‌آیند.';
    }
    return 'متوجه شدم! برای راهنمایی دقیق‌تر می‌توانید درباره‌ی «قیمت‌ها»، «رزرو»، «لغو» یا یک سرویس مشخص (مثل نظافت، کولر، لوله‌کشی) بپرسید. 🌟\n\nاین نسخه‌ی دموست؛ در نسخه‌ی Firebase پاسخ‌ها با Gemini (Cloud Function: aiAssistant) تولید می‌شوند.';
  }
}
