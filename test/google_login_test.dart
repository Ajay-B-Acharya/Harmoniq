import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmoniq/core/supabase/supabase_config.dart';
import 'package:harmoniq/screens/login_screen.dart';
import 'package:harmoniq/services/auth_service.dart';
import 'package:harmoniq/widgets/google_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Google Login Configuration & Widgets', () {
    test('SupabaseConfig defaults authCallbackUrl to com.example.rachan scheme', () {
      expect(SupabaseConfig.authCallbackUrl, 'com.example.rachan://login-callback');
    });

    testWidgets('GoogleLogo renders smoothly at specified size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GoogleLogo(size: 24),
            ),
          ),
        ),
      );

      expect(find.byType(GoogleLogo), findsOneWidget);
      final size = tester.getSize(find.byType(GoogleLogo));
      expect(size.width, 24);
      expect(size.height, 24);
    });

    testWidgets('LoginScreen displays "Continue with Google" button and email/password fields', (tester) async {
      tester.view.physicalSize = const Size(420 * 2.0, 900 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authService = AuthService();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            authService: authService,
            onLoginSuccess: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Email & Password inputs exist
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Google OAuth button exists
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(GoogleLogo), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
    });
  });
}
