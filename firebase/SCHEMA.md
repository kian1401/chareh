# 🗄️ اسکیمای Firestore — چاره

تمام کالکشن‌ها و فیلدها (همان مدل‌های `lib/data/models.dart`):

```
users/{uid}
  name, phone, role(customer|provider|admin), avatarEmoji,
  walletBalance: int, favorites: [serviceId], createdAt: Timestamp
  └── addresses/{addrId}  →  title, text, isDefault

categories/{id}            →  title, emoji, active
services/{id}              →  categoryId, title, description, emoji, basePrice,
                              rating, ratingCount, jobsDone, active,
                              options: [{title, subtitle, price, duration}],
                              addOns: [{title, price}], tags: [string]
reviews/{id}               →  serviceId, author, rating, text, dateLabel|at
providers/{id}             →  userId, name, emoji, skills: [string], rating,
                              jobsDone, verified, online, level

bookings/{id}              →  serviceId, serviceTitle, serviceEmoji, optionTitle,
                              addOnTitles: [], customerId, customerName,
                              providerId?, providerName?, providerEmoji?,
                              dayLabel, timeSlot, addressText,
                              status(pending|accepted|onTheWay|inProgress|completed|rejected|cancelled),
                              totalPrice, paymentMethod, createdAt: serverTimestamp,
                              timeline: [{status, at, note?}], rating?, review?

threads/{threadId}/messages/{mid}  →  threadId, isMine, text, at
notifications/{id}         →  userId, title, body, emoji, unread, at
earnings/{id}              →  providerId, bookingId, title, dateLabel, amount, settled
settings/app               →  commissionRate (0.05..0.30)
otps/{phone}               →  code, role, expiresAt   (موقت؛ سمت سرور)
```

## قوانین جریان داده (نقش Functions)

| رویداد | فانکشن | نتیجه |
|---|---|---|
| ایجاد booking | (اپ) | وضعیت `pending`، بدون providerId → در «بازار درخواست‌ها» ظاهر می‌شود |
| accept توسط متخصص | (اپ) | `providerId` ست می‌شود + وضعیت `accepted` |
| تغییر status | `onBookingStatus` | نوتیفیکیشن برای مشتری (+FCM در آینده) |
| ثبت rating | `onReviewUpdate` | میانگین امتیاز service به‌روزرسانی می‌شود |
| status=completed | `onBookingCompleted` | رکورد `earnings` با درآمد خالص (پس از کمیسیون) |

## دیپلوی

```bash
cd firebase
firebase login
firebase use <PROJECT_ID>
firebase deploy --only firestore:rules,firestore:indexes,functions
firebase functions:secrets:set GEMINI_API_KEY   # از Google AI Studio
```
