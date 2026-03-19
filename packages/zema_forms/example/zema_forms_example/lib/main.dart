import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/register_page.dart';

void main() {
  runApp(const ZemaFormsExampleApp());
}

class ZemaFormsExampleApp extends StatelessWidget {
  const ZemaFormsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'zema_forms example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
        useMaterial3: true,
      ),
      home: const _RootPage(),
    );
  }
}

class _RootPage extends StatefulWidget {
  const _RootPage();

  @override
  State<_RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<_RootPage> {
  int _index = 0;

  static const _pages = <Widget>[
    LoginPage(),
    RegisterPage(),
    ProfilePage(),
  ];

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.login_outlined),
      selectedIcon: Icon(Icons.login),
      label: 'Login',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_add_outlined),
      selectedIcon: Icon(Icons.person_add),
      label: 'Register',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_circle_outlined),
      selectedIcon: Icon(Icons.account_circle),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: _destinations,
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
