import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giyotin Optimizasyon Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Hoşgeldiniz! Kesim hesaplama modülü buraya gelecek.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}