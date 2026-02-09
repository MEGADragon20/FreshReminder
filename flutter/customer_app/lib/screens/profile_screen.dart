import 'package:flutter/material.dart';
import '../core/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    // Replace entire stack with the LoginScreen using named route
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('User info and settings will appear here.'),
          const Spacer(),
          Center(
            child: ElevatedButton(
              onPressed: () => _logout(context),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
