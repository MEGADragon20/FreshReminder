import 'package:flutter/material.dart';
import 'fridge_screen.dart';
import 'shopping_screen.dart';
import 'remove_screen.dart';
import 'profile_screen.dart';
import 'add_screen.dart';
import '../core/auth_service.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _index = 0;

  static const List<Widget> _pages = <Widget>[
    FridgeScreen(),
    ShoppingScreen(),
    AddScreen(),
    RemoveScreen(),
    ProfileScreen(),
  ];

  void _onTap(int idx) {
    setState(() => _index = idx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Fridge'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shopping'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.remove_circle_outline), label: 'Remove'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _index == 1
          ? FloatingActionButton(
              child: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                // TODO: implement quick add to shopping
              },
            )
          : null,
    );
  }
}
