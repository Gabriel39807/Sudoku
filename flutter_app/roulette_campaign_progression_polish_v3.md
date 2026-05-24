# Roulette + Campaign + Progression Polish v3

## Resumen

Refactor completo de ruleta, heatmap, campaign UX, auto-select tab mode y botón campaña. Sin tocar datasets ni generación.

---

## FASE 1 — RouletteModal

### Cambios
- **Nuevo**: `lib/features/wheel/presentation/roulette_modal.dart`
  - Modal bottom sheet (78% altura), no full screen
  - Fondo con blur + partículas animadas (CustomPainter)
  - Rueda con RadialGradient segments, glow pulsante, bisel exterior
  - Pointer con pulso de brillo
  - Resultado overlay con zoom + scale + fade
  - Confetti (40 piezas animadas con rotación)
  - Extra spin chips: ANUNCIO, 3 TOKENS, PREMIUM (hooks, no implementados)
- **Modificado**: `wheel_reward.dart`
  - Nuevos segmentos: tokens x1/x5/x10, souls x1/x3/x5/x10, hints x1/x3, advanced notes, mini jackpot x20, empty slot
  - 12 segmentos total, distribución: common 67%, medium 21%, rare 10%, jackpot 2%
  - `isCurrency`, `isEmpty`, `isAdvancedNotes`, `isHint`, `currencyType` getters
- **Modificado**: `wheel_storage.dart`
  - Extra spins: `getExtraSpins()`, `addExtraSpins()`, `useExtraSpin()`, `premiumSpinPack()`, `tokenSpinPack()`
- **Modificado**: `wheel_provider.dart`
  - Manejo de extra spins en `spin()` y `claimReward()`
  - Soporte para advanced notes, hints, empty, currency por tipo
  - `claimDailyFree()` hook
- **Modificado**: `menu_screen.dart`
  - Botón ruleta llama `showRouletteModal(context)` en vez de `context.push('/lucky-wheel')`
- **Eliminado contenido visual**: el full-screen `LuckyWheelScreen` queda sin uso, reemplazado por `RouletteModal`

---

## FASE 2 — Campaign 4x4 + UX

### BoardDimensionAwareHeatmap
- **Nuevo**: Clase pública `BoardDimensionAwareHeatmap` en `victory_screen.dart`
- Usa `session.config.boardSize` para determinar grid count (4, 6, 8, 9)
- Itera solo sobre `boardSize * boardSize` celdas (16, 36, 64 o 81)
- Fallback: si no hay datos → `SizedBox.shrink()`, no error
- `_HeatmapSummary` delegado interno — compatible hacia atrás

### CampaignLevelCompleteCard
- **Nuevo**: `lib/features/campaign/presentation/campaign_level_complete_card.dart`
- Overlay full-screen animado (ScaleTransition + FadeTransition)
- ⭐⭐⭐ con animación secuencial (cada estrella con 150ms delay)
- 1: completar, 2: sin errores, 3: rápido (threshold por boardSize: 4→60s, 6→180s, 8→300s)
- Rewards: souls +1, tokens +1 con `CurrencyWidget`
- Botones: CONTINUAR (→siguiente nivel), REPETIR (reintentar), HOME (menú)
- Stats: tiempo y errores

### Flujo de campaña actualizado
- `campaign_game_screen.dart`: en vez de navegar a `/victory`, ahora muestra `CampaignLevelCompleteCard` como overlay
- Guarda `_elapsedAtWin` y `_mistakesAtWin` al momento de la victoria
- CONTINUAR: `abandonGame()` + push a `/campaign-game` con nivel siguiente
- REPETIR: `abandonGame()` + push al mismo nivel
- HOME: `popUntil` primer route

---

## FASE 3 — Botón Campaña

### Cambios
- **Modificado**: `_CampaignButton` en `menu_screen.dart`
- Mismo tamaño (280×56) que `_BigButton` y alineado en la columna
- Texto plano `'CAMPAÑA · X/Y'` en vez de columna con dos textos
- Usa `progress.totalCount` en vez de hardcode `50`

---

## FASE 4 — Tab Mode Smart

### Auto-select en _applyBoardChange
- Cuando un dígito lockeado se completa, busca el siguiente incompleto (`locked + 1` a `digits`)
- Si encuentra: `state.copyWith(lockedNumber: d)`
- Si todos completos: `state.copyWith(clearLockedNumber: true)`

### Auto-select en selectCell
- Al tocar celda con valor completo y estar lockeado a ese dígito → avanza al siguiente incompleto
- No lockea a dígitos completados

### Lock mode actualizado
- Si activo y el dígito lockeado se completa → cambia automáticamente

---

## Archivos tocados

| Archivo | Cambio |
|---------|--------|
| `lib/features/wheel/presentation/roulette_modal.dart` | NUEVO — RouletteModal con partículas, confetti, rueda 3D |
| `lib/features/wheel/domain/wheel_reward.dart` | 12 segmentos, nuevos getters de tipo |
| `lib/features/wheel/application/wheel_provider.dart` | Extra spins, manejo por tipo de reward |
| `lib/features/wheel/data/wheel_storage.dart` | Extra spins persistence |
| `lib/features/menu/menu_screen.dart` | RouletteModal, botón campaña corregido |
| `lib/features/game/presentation/victory_screen.dart` | BoardDimensionAwareHeatmap (4x4/6x6/8x8/9x9) |
| `lib/features/campaign/presentation/campaign_level_complete_card.dart` | NUEVO — overlay de nivel completado |
| `lib/features/campaign/presentation/campaign_game_screen.dart` | Usa overlay en vez de /victory |
| `lib/features/game/application/game_provider.dart` | Auto-select tab mode en _applyBoardChange y selectCell |

---

## Tests

- ✅ flutter analyze: 0 errores, 0 warnings propios
- ✅ Ruleta usa CurrencyWidget en resultado
- ✅ BoardDimensionAwareHeatmap soporta 4x4, 6x6, 8x8, 9x9
- ✅ Campaign no rompe en 4x4 (grid 16 celdas)
- ✅ CampaignLevelCompleteCard con estrellas
- ✅ Auto-select en tab mode (lockedNumber avanza al siguiente incompleto)
- ✅ Lock mode actualizado

## Pendientes / Hooks

- `spin_ad` → No implementado (hook listo)
- `spin_tokens` → No implementado (hook listo)
- `spin_premium` → No implementado (hook listo)
- `DOUBLE` button → Placeholder en el diseño conceptual
