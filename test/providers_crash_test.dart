import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chareh/features/admin/providers_screen.dart';
import 'package:chareh/features/auth/auth_state.dart';
import 'package:chareh/data/models.dart';

void main() {
  testWidgets('تعریف متخصص: پر کردن دیالوگ و ذخیره نباید کرش کند', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthState(initialPortal: UserRole.admin),
        child: const MaterialApp(home: AdminProvidersScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('تعریف متخصص'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'نام کامل'), 'حسین تعمیرکار');
    await tester.enterText(find.widgetWithText(TextField, 'شماره موبایل (کلید ورود به اپ متخصص)'), '09120000002');
    await tester.tap(find.textContaining('تعمیرات لوازم خانگی').first);
    await tester.pump();
    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('حسین تعمیرکار'), findsOneWidget);
  });
}
