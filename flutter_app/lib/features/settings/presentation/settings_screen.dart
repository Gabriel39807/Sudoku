import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../stats/data/stats_storage.dart';
import '../../stats/application/stats_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('CONFIGURACIÓN',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'DATOS',
            style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white54),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.history,
            iconColor: Colors.orangeAccent,
            title: 'Reset tableros jugados',
            subtitle: 'Permite volver a jugar tableros ya completados',
            onTap: () => _confirmAction(
              context,
              title: 'Resetear historial de tableros',
              content: 'Se borrará el registro de tableros jugados. Las estadísticas no se modificarán.',
              onConfirm: () async {
                await StatsStorage.resetPlayedBoards();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Historial de tableros reseteado')),
                  );
                }
              },
            ),
          ),
          const Divider(color: Colors.white12),
          _SettingsTile(
            icon: Icons.delete_outline,
            iconColor: Colors.redAccent,
            title: 'Reset completo de datos',
            subtitle: 'Borra tableros jugados, estadísticas y caché de partidas',
            onTap: () => _confirmAction(
              context,
              title: 'Reset completo',
              content: 'Se borrarán TODOS los datos de juego. Esta acción no se puede deshacer.',
              onConfirm: () async {
                await StatsStorage.resetAllGameData();
                ref.invalidate(statsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Datos reseteados')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String content,
    required Future<void> Function() onConfirm,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) await onConfirm();
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Icon(icon, color: iconColor, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }
}
