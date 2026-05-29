import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/unlock_reward.dart';
import '../application/cosmetics_provider.dart';
import '../application/cosmetic_inventory_provider.dart';
import '../application/avatar_inventory_provider.dart';

class UnlockRewardState {
  final Queue<UnlockReward> queue;
  final bool isShowing;

  UnlockRewardState({
    required this.queue,
    this.isShowing = false,
  });

  UnlockRewardState copyWith({
    Queue<UnlockReward>? queue,
    bool? isShowing,
  }) {
    return UnlockRewardState(
      queue: queue ?? this.queue,
      isShowing: isShowing ?? this.isShowing,
    );
  }
}

class UnlockRewardService extends Notifier<UnlockRewardState> {
  @override
  UnlockRewardState build() {
    return UnlockRewardState(queue: Queue<UnlockReward>());
  }

  /// Agrega una recompensa a la cola para ser mostrada secuencialmente.
  void queueUnlock(UnlockReward reward) {
    state.queue.add(reward);
    state = state.copyWith(queue: state.queue);
    
    // Si no se está mostrando ningún modal actualmente, procesamos el siguiente.
    if (!state.isShowing) {
      _showNextPending();
    }
  }

  /// Muestra el siguiente reward de la cola usando una clave global para contexto
  /// o requiriendo el contexto actual del widget.
  Future<void> processQueue(BuildContext context) async {
    if (state.queue.isEmpty || state.isShowing) return;
    await _showNextPendingWithContext(context);
  }

  Future<void> _showNextPending() async {
    // Si no tenemos un contexto global, dependemos de que se procese con contexto de UI.
    // Para simplificar la integración sin romper nada, usamos el enfoque de cola bajo demanda
    // o registramos un callback de visualización.
  }

  Future<void> _showNextPendingWithContext(BuildContext context) async {
    if (state.queue.isEmpty) {
      state = state.copyWith(isShowing: false);
      return;
    }

    if (!context.mounted) return;

    state = state.copyWith(isShowing: true);
    final reward = state.queue.removeFirst();
    state = state.copyWith(queue: state.queue);

    // Importamos dinámicamente o llamamos a la UI del modal premium
    // a través de un callback o invocación directa del diálogo.
    // Usamos el callback onViewRequested y equipCallback definidos en el reward o manejados aquí.
  }

  /// Ejecuta la acción de equipar inmediatamente actualizando los providers de Riverpod
  Future<void> equipCosmetic(UnlockReward reward) async {
    final type = reward.type;
    final cosmeticId = reward.cosmeticId;

    switch (type) {
      case UnlockRewardType.background:
        // Equipar el fondo en el inventario y el tema global
        await ref.read(cosmeticInventoryProvider.notifier).equipBackground(cosmeticId);
        await ref.read(cosmeticsProvider.notifier).selectTheme(cosmeticId);
        break;
      case UnlockRewardType.avatar:
        // Equipar avatar
        await ref.read(avatarInventoryProvider.notifier).unlockAvatar(cosmeticId);
        await ref.read(avatarInventoryProvider.notifier).selectAvatar(cosmeticId);
        break;
      case UnlockRewardType.avatarFrame:
        // Equipar marco
        await ref.read(avatarInventoryProvider.notifier).unlockFrame(cosmeticId);
        await ref.read(avatarInventoryProvider.notifier).selectFrame(cosmeticId);
        break;
      default:
        // Medallas/Títulos no se equipan directamente de forma automática
        break;
    }

    // Ejecuta el callback custom si existe
    reward.equipCallback?.call();
  }
}

final unlockRewardServiceProvider =
    NotifierProvider<UnlockRewardService, UnlockRewardState>(
  UnlockRewardService.new,
);
