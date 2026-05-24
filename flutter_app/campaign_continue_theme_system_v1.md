# Campaign Continue + Theme System v1

## Resumen

Fix ruleta roja, tutorial paginación, botón CONTINUE campaña, cimientos de UI color themes y fondos globales.

---

## FASE 1 — Roulette Error Rojo (FIX)

### Causas identificadas
- **Listeners duplicados**: cada `_spin()` agregaba nuevos `addStatusListener`/`addListener` sin remover los viejos → `setState` post-dispose
- **Missing `_spin()` method**: eliminado accidentalmente en rewrite anterior
- **`AnimatedBuilder` con listeners no limpios**: `_ParticleBackground` sin `mounted` checks
- **Layout overflow**: modal sin `clamp()` en altura

### Soluciones
- Listeners registrados UNA vez en `initState`, removidos en `dispose`
- `mounted` checks en TODOS los callbacks de animación
- `_spinStart`/`_spinTarget` fields para interpolación correcta del ángulo
- `modalH.clamp(400.0, screenH - 60)` previene overflow
- `try/catch` envolviendo `build()` → fallback UI seguro en vez de pantalla roja
- `_ResultContent` envuelto en `SafeArea`
- `Navigator.maybeOf()` en vez de `Navigator.of()`
- `ScaffoldMessenger.maybeOf()` en vez de `ScaffoldMessenger.of()`
- `showRouletteModal` envuelto en `try/catch` con snackbar de error

---

## FASE 2 — Campaign Tutorial Paginación (FIX)

### Causa
- Botón SIGUIENTE usaba `setState(() => _currentPage++)` pero el `PageView.builder` tiene su propio estado interno
- `PageView` no recibe notificación del cambio de página → contenido nunca cambia
- Sólo el gradiente de fondo se actualizaba (porque se leía `_pages[_currentPage]` en el build)

### Solución
- `PageController` con `_pageCtrl.nextPage()` en el botón
- `AnimatedContainer` para transición suave de gradiente de fondo
- `AnimatedSwitcher` con `SlideTransition` + `FadeTransition` para contenido
- Dispose correcto del `PageController`

---

## FASE 3 — CONTINUE Campaign Button

### Active Run Tracking
- `CampaignProgress.activeRunLevel`: 0 = sin run activo, >0 = nivel en progreso
- `CampaignNotifier.startRun(level)` / `clearRun()` — persistido en SharedPreferences
- `campaign_game_screen.dart` llama `startRun()` en `initState` y `clearRun()` al salir
- `CampaignLevelCompleteCard` ya limpia `activeRunLevel` vía `completeLevel()`

### Menu Button
- `_CampaignContinueButton`: hero button ambar con shimmer animation
- Muestra "CONTINUAR · NIVEL X" con info del stage
- Reemplaza al botón CAMPAÑA cuando hay run activo
- Navega directamente a `/campaign-game` con level y variant

### Casos
| Estado | Botón |
|--------|-------|
| Sin run activo | CAMPAÑA (estándar) |
| Run activo | CONTINUAR (hero, ambar, shimmer) |
| Nivel completado | Vuelve a CAMPAÑA |

---

## FASE 4 — UI Color Palettes (Foundation)

### Creado
- `lib/features/customization/domain/ui_color_palette.dart`
  - Enum `UIColorPalette` con 8 paletas: Classic Blue, Emerald, Crimson, Golden, Crystal, Purple Neon, Dark Mythic, Forest
  - Cada una con: `primary`, `secondary`, `accent`, `buttonGradientStart/End`, `glow`
  - `defaultPalette = UIColorPalette.classicBlue`

### Pendiente (próxima sesión)
- Aplicar paleta a botones, cards, home, campaign, daily, ruleta, resultados, modales
- Pantalla de preview en vivo con tap para equipar

---

## FASE 5 — Global Game Backgrounds (Foundation)

### Creado
- `lib/features/customization/domain/game_background_theme.dart`
  - Enum `GameBackgroundTheme` con 8 fondos: Deep Space, Midnight Blue, Emerald Mist, Royal Crimson, Warm Amber, Cosmic Purple, Arctic Dawn, Sunset Blaze
  - Cada uno con: `gradientColors`, `lockedByDefault`, `unlockCost`
  - 3 bloqueados por defecto (Cosmic, Arctic, Sunset) con costos

### Pendiente (próxima sesión)
- Aplicar background a home, shop, campaign, daily, perfil, logros, settings
- NO gameplay (sólo UI backgrounds)
- Pantalla de preview con bloqueados/desbloqueados
- Carga dinámica desde `assets/cosmetics/game_backgrounds/`

---

## Persistencia Compartida

- `CustomizationStorage` en `shared_preferences`
- Keys: `selected_ui_palette`, `selected_game_background`
- Provider Riverpod: `customizationProvider`

---

## Archivos tocados

| Archivo | Cambio |
|---------|--------|
| `lib/features/wheel/presentation/roulette_modal.dart` | REWRITE: listeners fijos, try/catch, SafeArea, fallback |
| `lib/features/campaign/presentation/tutorial_screen.dart` | REWRITE: PageController, AnimatedSwitcher, slide+fade |
| `lib/features/campaign/domain/campaign_progress.dart` | +activeRunLevel, hasActiveRun |
| `lib/features/campaign/application/campaign_provider.dart` | +startRun(), clearRun() |
| `lib/features/campaign/presentation/campaign_game_screen.dart` | +startRun/clearRun, import provider |
| `lib/features/menu/menu_screen.dart` | +_CampaignContinueButton hero, Consumer conditional |
| `lib/features/customization/domain/ui_color_palette.dart` | NUEVO — 8 paletas |
| `lib/features/customization/domain/game_background_theme.dart` | NUEVO — 8 fondos |
| `lib/features/customization/application/customization_provider.dart` | NUEVO — Riverpod state |
| `lib/features/customization/data/customization_storage.dart` | NUEVO — SharedPreferences |

---

## Tests

- ✅ flutter analyze: 0 errores, 0 warnings propios
- ✅ RouletteModal con try/catch + fallback UI + SafeArea
- ✅ Tutorial cambia página con slide+fade (PageController)
- ✅ CONTINUE campaign button aparece solo con run activo
- ✅ activeRunLevel persiste y se limpia correctamente
- ✅ UIColorPalette enum con 8 paletas completas
- ✅ GameBackgroundTheme enum con 8 fondos + locked/unlocked
- ✅ CustomizationStorage guarda/recupera ambas selecciones
