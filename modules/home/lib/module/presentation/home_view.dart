import 'package:dependencies/flutter_modular.dart';
import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TCC - State Management'),
        centerTitle: true,
        elevation: 0,
        leading: Builder(
          builder: (context) =>
              IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Selecione um gerenciador de estado:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildManagerButton(
              context,
              title: 'BLoC',
              subtitle: 'Business Logic Component',
              color: Colors.blue,
              icon: Icons.code,
              route: '/task/bloc',
            ),
            const SizedBox(height: 16),
            _buildManagerButton(
              context,
              title: 'Provider',
              subtitle: 'Provider + ChangeNotifier',
              color: Colors.purple,
              icon: Icons.code,
              route: '/task/provider',
            ),
            const SizedBox(height: 16),
            _buildManagerButton(
              context,
              title: 'Riverpod',
              subtitle: 'ProviderScope + StateNotifier',
              color: Colors.green,
              icon: Icons.code,
              route: '/task/riverpod',
            ),
            const SizedBox(height: 16),
            _buildManagerButton(
              context,
              title: 'GetX',
              subtitle: 'GetxController + Obs',
              color: Colors.orange,
              icon: Icons.code,
              route: '/task/getx',
            ),
            const Spacer(),
            const Text(
              'To-Do List App - Análise Comparativa',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue, Colors.blueAccent])),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'TCC - Análise Comparativa',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('Gerenciadores de Estado em Flutter', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sobre o TCC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'Análise Comparativa de Abordagens de Gerenciamento de Estado em Flutter',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 12),
                Divider(),
                SizedBox(height: 8),
                Text('Autor: Lucas Broering dos Santos', style: TextStyle(fontSize: 13, color: Colors.grey)),
                SizedBox(height: 2),
                Text('Orientador: Raul Sidnei Wazlawick, Dr.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                SizedBox(height: 2),
                Text('UFSC - Sistemas de Informação', style: TextStyle(fontSize: 13, color: Colors.grey)),
                SizedBox(height: 2),
                Text('2026', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required String route,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Modular.to.pushNamed(route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
