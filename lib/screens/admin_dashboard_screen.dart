import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_post_reports_screen.dart';
import 'admin_user_reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          AdminPostReportsScreen(),
          AdminUserReportsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Post Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'User Reports',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: theme.primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
} 