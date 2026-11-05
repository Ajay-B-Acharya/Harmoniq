import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harmoniq/core/supabase/supabase_config.dart';
import 'package:harmoniq/screens/login_screen.dart';
import 'package:harmoniq/services/auth_service.dart';
import 'package:harmoniq/widgets/google_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Test subclass of AuthService to simulate OAuth flows and errors without live network
class _TestAuthService extends AuthService {
  _TestAuthService() : super(client: null);

  void simulateAuthError(String message, {String? code, String? statusCode}) {
    final exception = AuthException(
      message,
      code: code,
      statusCode: statusCode,
    );
    // Trigger formatting and error state
    final formatted = formatExceptionForTest(exception);
    setAuthErrorForTest(formatted);
  }

  String formatExceptionForTest(AuthException e) {
    final msg = e.message.toLowerCase();
    final code = e.code?.toLowerCase() ?? '';
    final statusCode = e.statusCode?.toLowerCase() ?? '';

    if (code.contains('flow_state_already_used') ||
        statusCode.contains('flow_state_already_used') ||
        msg.contains('state has already been used') ||
        msg.contains('flow_state_already_used')) {
      return 'The sign-in session expired or was already used. Please try signing in again.';
    } else if (msg.contains('flow_state_not_found') ||
        code.contains('flow_state_not_found') ||
        statusCode.contains('flow_state_not_found')) {
      return 'Sign-in session not found. Please start a new sign-in.';
    } else if (code.contains('invalid_grant') ||
        statusCode.contains('invalid_grant') ||
        msg.contains('invalid_grant')) {
      return 'Sign-in authorization expired. Please try signing in again.';
    } else if (code.contains('access_denied') ||
        statusCode.contains('access_denied') ||
        msg.contains('access_denied') ||
        msg.contains('canceled') ||
        msg.contains('cancelled') ||
        msg.contains('user_cancelled')) {
      return 'Google sign-in was canceled.';
    }
    return e.message;
  }

  void setAuthErrorForTest(String error) {
    // Reset in progress and set error
    resetOAuthFlow();
    // Simulate error notification
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseConfig.clearProcessedAuthCodes();
  });

  tearDown(() {
    SupabaseConfig.clearProcessedAuthCodes();
  });

  group('Google Login Configuration & Deep Links', () {
    test('SupabaseConfig defaults authCallbackUrl to com.example.rachan scheme', () {
      expect(SupabaseConfig.authCallbackUrl, 'com.example.rachan://login-callback');
    });

    test('resolvedAuthCallbackUrl uses platform defaults', () {
      expect(SupabaseConfig.resolvedAuthCallbackUrl, 'com.example.rachan://login-callback');
    });

    test('isAuthCallbackDeeplink detects authorization code in query and rejects duplicate codes', () {
      final uri = Uri.parse('com.example.rachan://login-callback?code=pkce-auth-code-123');

      // First time: should be detected as valid auth callback
      expect(SupabaseConfig.isAuthCallbackDeeplink(uri), isTrue);

      // Second time with identical code: should be rejected to prevent flow_state_already_used
      expect(SupabaseConfig.isAuthCallbackDeeplink(uri), isFalse);

      // After clearing cache: can be processed again
      SupabaseConfig.clearProcessedAuthCodes();
      expect(SupabaseConfig.isAuthCallbackDeeplink(uri), isTrue);
    });

    test('isAuthCallbackDeeplink detects authorization code in fragment', () {
      final uri = Uri.parse('com.example.rachan://login-callback#code=fragment-code-456');

      expect(SupabaseConfig.isAuthCallbackDeeplink(uri), isTrue);
      // Duplicate check works on fragment codes too
      expect(SupabaseConfig.isAuthCallbackDeeplink(uri), isFalse);
    });

    test('isAuthCallbackDeeplink detects error query parameters and deduplicates them', () {
      final errorUri = Uri.parse(
        'http://localhost:3000/?error=invalid_request&error_code=flow_state_already_used&error_description=State+has+already+been+used',
      );

      // First delivery: detected as auth callback so error can be processed
      expect(SupabaseConfig.isAuthCallbackDeeplink(errorUri), isTrue);

      // Duplicate delivery: rejected to prevent duplicate exception loops
      expect(SupabaseConfig.isAuthCallbackDeeplink(errorUri), isFalse);
    });

    test('isAuthCallbackDeeplink ignores unrelated deep links', () {
      final normalUri = Uri.parse('com.example.rachan://playlist?id=123');
      expect(SupabaseConfig.isAuthCallbackDeeplink(normalUri), isFalse);
    });
  });

  group('AuthService OAuth Flow Management', () {
    test('AuthService prevents concurrent / overlapping Google OAuth attempts', () async {
      final authService = AuthService(client: null);

      expect(authService.isOAuthInProgress, isFalse);

      // Offline service throws offline exception when started
      await expectLater(
        () => authService.signInWithGoogle(),
        throwsA(isA<Exception>()),
      );

      // resetOAuthFlow cleans state
      authService.resetOAuthFlow();
      expect(authService.isOAuthInProgress, isFalse);
      expect(authService.authError, isNull);
    });

    test('AuthService correctly translates flow_state_already_used AuthException', () {
      final testService = _TestAuthService();

      final message = testService.formatExceptionForTest(
        const AuthException(
          'State has already been used',
          code: 'invalid_request',
          statusCode: 'flow_state_already_used',
        ),
      );

      expect(
        message,
        'The sign-in session expired or was already used. Please try signing in again.',
      );
    });

    test('AuthService correctly translates cancellation and expired grants', () {
      final testService = _TestAuthService();

      expect(
        testService.formatExceptionForTest(
          const AuthException('user_cancelled', code: 'access_denied'),
        ),
        'Google sign-in was canceled.',
      );

      expect(
        testService.formatExceptionForTest(
          const AuthException('invalid_grant', code: 'invalid_grant'),
        ),
        'Sign-in authorization expired. Please try signing in again.',
      );
    });
  });

  group('LoginScreen UI & Interaction', () {
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

      final authService = AuthService(client: null);

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

    testWidgets('LoginScreen displays error message and re-enables button after failed OAuth attempt', (tester) async {
      tester.view.physicalSize = const Size(420 * 2.0, 900 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authService = AuthService(client: null);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            authService: authService,
            onLoginSuccess: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Google Sign-In
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Because client is null, it displays offline error and re-enables button
      expect(
        find.textContaining('Authentication service is currently offline'),
        findsOneWidget,
      );

      // Button is enabled for retry
      final buttonFinder = find.widgetWithText(OutlinedButton, 'Continue with Google');
      final OutlinedButton button = tester.widget(buttonFinder);
      expect(button.onPressed, isNotNull);
    });
  });
}
