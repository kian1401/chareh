# 🧩 چاره — پلتفرم خدمات خانگی (معادل عملکردی Urban Company)

یک اکوسیستم کامل Flutter به زبان فارسی (RTL):

| قسمت | توضیح |
|---|---|
| 📱 اپ مشتری | `flutter build apk --flavor customer -t lib/main_customer.dart` |
| 🧑‍🔧 اپ متخصص | `flutter build apk --flavor provider -t lib/main_provider.dart` |
| 🛡️ داشبورد ادمین | داخل همان اپ، مسیر `/admin` |
| 🌐 وب | `flutter build web` |

- **نام‌ها**: چاره (app.chareh) • چاره متخصص (app.chareh.provider)
- **بک‌اند دوحالته**: دادهٔ دموی درون‌حافظه ↔ Firebase/REST واقعی (کلید یک‌خطی در `RepoHub`)
- **استقرار**: راهنمای کامل در [`deploy/DEPLOY.md`](deploy/DEPLOY.md) — گیت‌هاب + رندر + سبد خرید ایرانی ([IRAN_STACK](deploy/IRAN_STACK.md))
- **طراحی**: Material 3 فارسی، فونت وزیرمتن، اعداد فارسی
- **سورس و معماری**: docs/ARCHITECTURE.md

> ساخته‌شده با کمک «تیم مجازی» — آرکتکت: Gemini، بک‌اند: Firebase Studio، UI: FlutterFlow، اجرا: OpenHands
