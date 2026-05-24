import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/customization/application/customization_provider.dart';
import 'theme_palette.dart';

extension PaletteContext on BuildContext {
  AppPalette get palette {
    try {
      return ProviderScope.containerOf(this).read(customizationProvider).palette;
    } catch (_) {
      return AppPalette.classic;
    }
  }
}

extension PaletteRef on WidgetRef {
  AppPalette get palette => watch(customizationProvider).palette;
}
