import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../main.dart' show HomeScreen;

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        }

        return _showLogin
            ? LoginScreen(
                onSwitchToRegister: () {
                  setState(() {
                    _showLogin = false;
                  });
                },
              )
            : RegisterScreen(
                onSwitchToLogin: () {
                  setState(() {
                    _showLogin = true;
                  });
                },
              );
      },
    );
  }
}
