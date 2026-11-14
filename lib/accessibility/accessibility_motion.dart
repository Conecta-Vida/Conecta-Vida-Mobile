import 'package:flutter/material.dart';

/// Retorna duração zero quando a preferência de movimento reduzido está ativa.
class AccessibilityMotion {
  static Duration duration(BuildContext context, Duration normal) {
    return MediaQuery.of(context).disableAnimations ? Duration.zero : normal;
  }
}
