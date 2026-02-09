import 'package:flutter/material.dart';
import '../core/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;

  void _signup() async {
    setState(() => _loading = true);
    final email = _email.text.trim();
    final password = _password.text;
    final ok = await AuthService.instance.register(email, password);
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/app');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signup failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _signup, child: const Text('Sign Up')),
          ],
        ),
      ),
    );
  }
}
