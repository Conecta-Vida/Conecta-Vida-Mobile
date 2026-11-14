import 'package:flutter/material.dart';

/// Cores neutras que acompanham automaticamente o tema claro/escuro.
///
/// As cores de marca e das categorias continuam sendo definidas em AppCor,
/// portanto azul, vacinação, doações, alertas e eventos não são invertidos.
class AccessibilityPalette {
  static Color background(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerLow;

  static Color elevatedSurface(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;

  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color secondaryText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  static Color shadow(BuildContext context) =>
      Theme.of(context).colorScheme.shadow.withValues(alpha: 0.10);
}
