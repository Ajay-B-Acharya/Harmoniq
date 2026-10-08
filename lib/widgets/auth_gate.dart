import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/login_screen.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';

/// Gatekeeper widget that routes user to MainContainer if authenticated/guest,
/// or LoginScreen if unauthenticated.
class AuthGate extends StatefulWidget {
  final AuthService authService;
  final AudioService? audioService;

  const AuthGate({
    super.key,
    required this.authService,
    this.audioService,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isGuest = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.authService,
      builder: (context, _) {
        final user = widget.authService.currentUser;

        // If authenticated or user selected guest access
        if (user != null || _isGuest) {
          return MainContainer(
            audioService: widget.audioService,
            authService: widget.authService,
          );
        }

        // Show login screen
        return LoginScreen(
          authService: widget.authService,
          onLoginSuccess: () {
            setState(() {
              _isGuest = false;
            });
          },
          onContinueAsGuest: () {
            setState(() {
              _isGuest = true;
            });
          },
        );
      },
    );
  }
}
