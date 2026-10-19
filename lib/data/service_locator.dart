import '../core/config/backend_config.dart';
import 'firebase/firebase_repositories.dart';
import 'mock/mock_database.dart';
import 'mock/mock_repositories.dart';
import 'repositories.dart';

/// نقطه‌ی مرکزی ساخت ریپازیتوری‌ها — تعویض بک‌اند فقط با فلگ BackendConfig.useMock
class RepoHub {
  static final RepoHub instance = RepoHub._();

  late final AuthRepository auth;
  late final CatalogRepository catalog;
  late final BookingRepository bookings;
  late final ProviderRepository providers;
  late final ChatRepository chat;
  late final MiscRepository misc;

  bool get isMock => BackendConfig.useMock;

  RepoHub._() {
    if (BackendConfig.useMock) {
      final db = MockDb();
      auth = MockAuthRepository(db);
      catalog = MockCatalogRepository(db);
      bookings = MockBookingRepository(db);
      providers = MockProviderRepository(db);
      chat = MockChatRepository(db);
      misc = MockMiscRepository(db);
    } else {
      auth = FirebaseAuthRepository();
      catalog = FirebaseCatalogRepository();
      bookings = FirebaseBookingRepository();
      providers = FirebaseProviderRepository();
      chat = FirebaseChatRepository();
      misc = FirebaseMiscRepository();
    }
  }
}
