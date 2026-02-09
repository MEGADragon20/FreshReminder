import 'package:flutter/material.dart';
import '../core/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  void _login() async {
    final email = _email.text.trim();
    final password = _password.text;
    final ok = await AuthService.instance.login(email, password);
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/app');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text('Login')),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/signup');
              },
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
