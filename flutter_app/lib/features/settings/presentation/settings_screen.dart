import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/settings_model.dart';
import '../../stats/data/stats_storage.dart';
import '../../stats/application/stats_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

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
          // ── ASSIST MODE ──────────────────────────────────────────
          const Text(
            'MODO DE ASISTENCIA',
            style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white54),
          ),
          const SizedBox(height: 12),
          _AssistModeSelector(
            value: settings.assistMode,
            onChanged: (m) => ref.read(settingsProvider.notifier).setAssistMode(m),
          ),
          const SizedBox(height: 8),
          _assistModeDescription(settings.assistMode),
          const SizedBox(height: 24),

          // ── GAMEPLAY ─────────────────────────────────────────────
          const Text(
            'GAMEPLAY',
            style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white54),
          ),
          const SizedBox(height: 12),
          _SettingsSwitch(
            icon: Icons.vibration,
            iconColor: Colors.blueAccent,
            title: 'Vibrar al error',
            subtitle: 'Vibración al colocar un número incorrecto',
            value: settings.vibrateOnError,
            onChanged: (v) => ref.read(settingsProvider.notifier).setVibrateOnError(v),
          ),
          const Divider(color: Colors.white12),
          _SettingsSwitch(
            icon: Icons.center_focus_strong,
            iconColor: Colors.purpleAccent,
            title: 'Resaltar región seleccionada',
            subtitle: 'Iluminar fila, columna y bloque de la celda activa',
            value: settings.highlightRegion,
            onChanged: (v) => ref.read(settingsProvider.notifier).setHighlightRegion(v),
          ),
          const Divider(color: Colors.white12),
          _SettingsSwitch(
            icon: Icons.numbers,
            iconColor: Colors.tealAccent,
            title: 'Resaltar iguales',
            subtitle: 'Iluminar todas las celdas con el mismo número',
            value: settings.highlightSameNumbers,
            onChanged: (v) => ref.read(settingsProvider.notifier).setHighlightSameNumbers(v),
          ),
          const Divider(color: Colors.white12),
          _SettingsSwitch(
            icon: Icons.animation,
            iconColor: Colors.orangeAccent,
            title: 'Animaciones tablero',
            subtitle: 'Efectos visuales al completar filas, columnas y bloques',
            value: settings.boardAnimations,
            onChanged: (v) => ref.read(settingsProvider.notifier).setBoardAnimations(v),
          ),
          const Divider(color: Colors.white12),
          _SettingsSwitch(
            icon: Icons.grid_on,
            iconColor: Colors.amberAccent,
            title: 'Subgrids intensos',
            subtitle: 'Mayor contraste en bordes de bloques para mejor legibilidad',
            value: settings.intenseSubgrids,
            onChanged: (v) => ref.read(settingsProvider.notifier).setIntenseSubgrids(v),
          ),
          const Divider(color: Colors.white12),
          _SettingsSwitch(
            icon: Icons.auto_fix_high,
            iconColor: Colors.greenAccent,
            title: 'Mostrar autocompletar',
            subtitle: 'Botón para completar automáticamente las celdas restantes',
            value: settings.showAutoComplete,
            onChanged: (v) => ref.read(settingsProvider.notifier).setShowAutoComplete(v),
          ),
          const Divider(color: Colors.white12),
          _SettingsSwitch(
            icon: Icons.auto_awesome,
            iconColor: Colors.cyanAccent,
            title: 'Auto candidatos',
            subtitle: 'Mostrar notas candidatas automáticamente',
            value: settings.autoCandidates,
            onChanged: (v) => ref.read(settingsProvider.notifier).setAutoCandidates(v),
          ),

          const SizedBox(height: 32),

          // ── DATOS ────────────────────────────────────────────────
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

  Widget _assistModeDescription(AssistMode mode) {
    final text = switch (mode) {
      AssistMode.classic => 'Errores ilimitados, sin corrección instantánea. La experiencia Sudoku tradicional.',
      AssistMode.casual => 'Errores visibles al instante, pistas y autocompletar activos, vibración por defecto.',
      AssistMode.expert => 'Sin pistas, sin autocompletar, sin vibración. Sin resaltado de errores. Solo vos y el tablero.',
      AssistMode.extreme => '1 vida, cronómetro forzado, sin pausa, sin pistas, sin autocompletar. Modo hardcore.',
    };
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white54, fontStyle: FontStyle.italic)),
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

// ── Assist Mode Selector ─────────────────────────────────────────────────────

class _AssistModeSelector extends StatelessWidget {
  final AssistMode value;
  final ValueChanged<AssistMode> onChanged;

  const _AssistModeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AssistMode>(
      segments: const [
        ButtonSegment(value: AssistMode.classic, label: Text('Clásico', style: TextStyle(fontSize: 10))),
        ButtonSegment(value: AssistMode.casual, label: Text('Casual', style: TextStyle(fontSize: 10))),
        ButtonSegment(value: AssistMode.expert, label: Text('Experto', style: TextStyle(fontSize: 10))),
        ButtonSegment(value: AssistMode.extreme, label: Text('Extremo', style: TextStyle(fontSize: 10))),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

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

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: iconColor, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
        activeThumbColor: Theme.of(context).primaryColor,
      ),
      onTap: () => onChanged(!value),
    );
  }
}
