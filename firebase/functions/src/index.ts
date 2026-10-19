/**
 * شهرکار — Cloud Functions
 * ─────────────────────────────────────────────────────────
 * ۱) sendOtp / verifyOtp : احراز هویت موبایلی با Custom Token
 * ۲) onBookingStatus     : اعلان وضعیت سفارش برای مشتری
 * ۳) onReviewUpdate      : تجمیع امتیاز سرویس
 * ۴) onBookingCompleted  : ثبت درآمد متخصص پس از کسر کمیسیون
 * ۵) aiAssistant         : دستیار هوشمند Gemini (Google AI Studio)
 */
import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';

admin.initializeApp();
const db = admin.firestore();

// کلید را از Google AI Studio بگیرید و با دستور زیر ست کنید:
// firebase functions:secrets:set GEMINI_API_KEY
const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

// ───────────────────── OTP ─────────────────────

export const sendOtp = onCall(async (req) => {
  const { phone, role } = req.data as { phone?: string; role?: string };
  if (!phone || !/^09\d{9}$/.test(phone)) {
    throw new HttpsError('invalid-argument', 'شماره موبایل معتبر نیست');
  }
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  await db.collection('otps').doc(phone).set({
    code,
    role: role ?? 'customer',
    expiresAt: Date.now() + 5 * 60 * 1000,
  });
  // TODO: اتصال به درگاه پیامک (کاوه‌نگار / टوانا / SMS.ir) — فعلاً فقط لاگ می‌شود
  console.log(`OTP for ${phone}: ${code}`);
  // devCode فقط برای توسعه است؛ قبل از پروداکشن این خط را حذف کنید
  return { sent: true, devCode: code };
});

export const verifyOtp = onCall(async (req) => {
  const { phone, code } = req.data as { phone?: string; code?: string };
  const snap = await db.collection('otps').doc(phone ?? '').get();
  if (!snap.exists) {
    throw new HttpsError('not-found', 'کدی برای این شماره ارسال نشده است');
  }
  const data = snap.data()!;
  if (data.expiresAt < Date.now() || data.code !== code) {
    throw new HttpsError('permission-denied', 'کد نامعتبر یا منقضی شده است');
  }
  await db.collection('otps').doc(phone!).delete();

  // شناسه‌ی یکتا بر اساس شماره (بدون ذخیره‌ی PII اضافی)
  const uid = `ph_${Buffer.from(phone!).toString('hex')}`;
  try {
    await admin.auth().getUser(uid);
  } catch {
    await admin.auth().createUser({ uid });
  }

  const uref = db.collection('users').doc(uid);
  if (!(await uref.get()).exists) {
    await uref.set({
      name: 'کاربر شهرکار',
      phone,
      role: data.role ?? 'customer',
      avatarEmoji: '🙂',
      walletBalance: 0,
      favorites: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  const token = await admin.auth().createCustomToken(uid);
  return { token };
});

// ───────────────────── اعلان وضعیت سفارش ─────────────────────

const statusFa: Record<string, string> = {
  pending: 'در انتظار پذیرش ⏳',
  accepted: 'پذیرفته شد ✅',
  onTheWay: 'متخصص در راه است 🛵',
  inProgress: 'در حال انجام 🛠️',
  completed: 'تکمیل شد 🎉',
  rejected: 'رد شد ❌',
  cancelled: 'لغو شد 🚫',
};

export const onBookingStatus = onDocumentUpdated('bookings/{bid}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) return;

  await db.collection('notifications').add({
    userId: after.customerId,
    title: `وضعیت سفارش: ${statusFa[after.status] ?? after.status}`,
    body: `${after.serviceTitle} • ${after.dayLabel} ${after.timeSlot}`,
    emoji: '🔔',
    unread: true,
    at: new Date().toISOString(),
  });
  // TODO: ارسال پوش‌نوتیفیکیشن با FCM روی توکن ذخیره‌شده در users/{uid}/fcmTokens
});

// ───────────────────── تجمیع امتیاز ─────────────────────

export const onReviewUpdate = onDocumentUpdated('bookings/{bid}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.rating || !after.rating) return;

  const sref = db.collection('services').doc(after.serviceId);
  await db.runTransaction(async (tx) => {
    const s = await tx.get(sref);
    if (!s.exists) return;
    const d = s.data()!;
    const count = (d.ratingCount ?? 0) + 1;
    const rating = ((d.rating ?? 0) * (d.ratingCount ?? 0) + after.rating) / count;
    tx.update(sref, { rating: Math.round(rating * 10) / 10, ratingCount: count });
  });
});

// ───────────────────── درآمد متخصص (بعد از تکمیل) ─────────────────────

export const onBookingCompleted = onDocumentUpdated('bookings/{bid}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (before.status === 'completed' || after.status !== 'completed' || !after.providerId) return;

  const settings = (await db.collection('settings').doc('app').get()).data();
  const commission = settings?.commissionRate ?? 0.15;
  const net = Math.round(after.totalPrice * (1 - commission));

  await db.collection('earnings').add({
    providerId: after.providerId,
    bookingId: event.params.bid,
    title: `${after.serviceTitle} — ${after.optionTitle}`,
    dateLabel: 'امروز',
    amount: net,
    settled: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});

// ───────────────────── دستیار هوشمند (Gemini) ─────────────────────

export const aiAssistant = onCall({ secrets: [GEMINI_API_KEY] }, async (req) => {
  const prompt = (req.data?.prompt ?? '').toString().slice(0, 1000);
  if (!prompt) throw new HttpsError('invalid-argument', 'متن خالی است');

  const system =
    'تو «شهرکاری» هستی؛ دستیار فارسی‌زبان اپلیکیشن خدمات خانگی شهرکار (مشابه Urban Company). ' +
    'پاسخ‌ها کوتاه، دوستانه و کاربردی باشد. قیمت‌ها را به تومان و با اعداد فارسی بنویس. ' +
    'حوزه‌ها: نظافت، تعمیرات و سرویس لوازم خانگی، برق و تأسیسات، لوله‌کشی، نقاشی، زیبایی در منزل، تعمیر موبایل، اسباب‌کشی. ' +
    'اگر سوال نامرتبط بود مؤدبانه به موضوع خدمات برگرد. سیاست لغو: تا ۲ ساعت قبل رایگان. در انتها کاربر را به رزرو تشویق کن.';

  const url =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=' +
    GEMINI_API_KEY.value();

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: `${system}\n\nسوال کاربر: ${prompt}` }] }],
      generationConfig: { temperature: 0.4, maxOutputTokens: 500 },
    }),
  });
  const json = (await res.json()) as {
    candidates?: { content?: { parts?: { text?: string }[] } }[];
  };
  const reply =
    json?.candidates?.[0]?.content?.parts?.[0]?.text ??
    'الان متوجه نشدم؛ لطفاً دوباره بپرسید 🙏';
  return { reply };
});
