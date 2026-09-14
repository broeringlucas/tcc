import 'package:flutter/material.dart';

class ThesisInfoSection extends StatelessWidget {
  const ThesisInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final infoColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Análise comparativa de abordagens de gerenciamento de estado em Flutter: '
            'um estudo de caso com BLoC, Riverpod, Provider e GetX',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.35),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _InfoRow(label: 'Autor', value: 'Lucas Broering dos Santos', color: infoColor),
          const SizedBox(height: 12),
          _InfoRow(label: 'Orientador', value: 'Raul Sidnei Wazlawick, Dr.', color: infoColor),
          const SizedBox(height: 12),
          _InfoRow(label: 'Instituição', value: 'UFSC - Sistemas de Informação', color: infoColor),
          const SizedBox(height: 12),
          _InfoRow(label: 'Ano', value: '2026', color: infoColor),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: color),
        ),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }
}
