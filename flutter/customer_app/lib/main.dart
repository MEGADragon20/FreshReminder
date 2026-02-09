import 'package:flutter/material.dart';
import 'core/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FreshReminderApp());
}

class FreshReminderApp extends StatelessWidget {
  const FreshReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshReminder - Customer',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const _LaunchGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/app': (context) => const MainApp(),
      },
    );
  }
}

class _LaunchGate extends StatefulWidget {
  const _LaunchGate({super.key});

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  late Future<bool> _loggedIn;

  @override
  void initState() {
    super.initState();
    _loggedIn = AuthService.instance.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _loggedIn,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final loggedIn = snapshot.data ?? false;
        if (!loggedIn) {
          return const LoginScreen();
        }

        return const MainApp();
      },
    );
  }
}
