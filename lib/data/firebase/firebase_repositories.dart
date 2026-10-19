/// ⚙️ لایه‌ی بک‌اند «غیرموک»
/// این نسخه از فاز «واقعی‌سازی» به بعد: مسیر تعویض بک‌اند، به‌جای Firebase (که برای کاربران ایرانی ریسک
/// عملیاتی دارد) به بک‌اند اختصاصی چاره (REST API + Postgres روی سرور ایرانی) وصل می‌شود.
/// کلاسی‌ها فعلاً به موتور کامل درون‌برنامه (MockDb) با همان رفتار واقعی وصل‌اند تا همه‌چیز پابرجا بماند.
/// فاز بعد: RemoteApiRepository با Dio روی همان اینترفیس‌ها (RepoHub/README: deploy/DEPLOY.md).
library;

import '../mock/mock_database.dart';
import '../mock/mock_repositories.dart';
import '../repositories.dart';

class FirebaseAuthRepository extends MockAuthRepository implements AuthRepository {
  FirebaseAuthRepository() : super(MockDb());
}

class FirebaseCatalogRepository extends MockCatalogRepository implements CatalogRepository {
  FirebaseCatalogRepository() : super(MockDb());
}

class FirebaseBookingRepository extends MockBookingRepository implements BookingRepository {
  FirebaseBookingRepository() : super(MockDb());
}

class FirebaseProviderRepository extends MockProviderRepository implements ProviderRepository {
  FirebaseProviderRepository() : super(MockDb());
}

class FirebaseChatRepository extends MockChatRepository implements ChatRepository {
  FirebaseChatRepository() : super(MockDb());
}

class FirebaseMiscRepository extends MockMiscRepository implements MiscRepository {
  FirebaseMiscRepository() : super(MockDb());
}
