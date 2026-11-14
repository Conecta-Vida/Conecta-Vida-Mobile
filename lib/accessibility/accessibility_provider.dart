import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Preferências globais de acessibilidade do aplicativo.
///
/// Os valores ficam no box já utilizado pelo app, evitando uma migração
/// separada de armazenamento.
class AccessibilityProvider extends ChangeNotifier {
  AccessibilityProvider(this._box)
      : _fontScale = _readScale(_box),
        _boldText = _box.get('accessibility_bold_text', defaultValue: false) as bool,
        _highContrast = _box.get('accessibility_high_contrast', defaultValue: false) as bool,
        _darkMode = _box.get('accessibility_dark_mode', defaultValue: false) as bool,
        _reduceMotion = _box.get('accessibility_reduce_motion', defaultValue: false) as bool,
        _speechEnabled = _box.get('accessibility_speech_enabled', defaultValue: true) as bool,
        _fontFamily = _box.get('accessibility_font_family', defaultValue: 'system') as String;

  final Box _box;

  double _fontScale;
  bool _boldText;
  bool _highContrast;
  bool _darkMode;
  bool _reduceMotion;
  bool _speechEnabled;
  String _fontFamily;

  static double _readScale(Box box) {
    final value = box.get('accessibility_font_scale', defaultValue: 1.0);
    final scale = value is num ? value.toDouble() : 1.0;
    return scale.clamp(0.9, 1.6).toDouble();
  }

  double get fontScale => _fontScale;
  bool get boldText => _boldText;
  bool get highContrast => _highContrast;
  bool get darkMode => _darkMode;
  bool get reduceMotion => _reduceMotion;
  bool get speechEnabled => _speechEnabled;
  String get fontFamily => _fontFamily;

  Future<void> setFontScale(double value) async {
    final normalized = value.clamp(0.9, 1.6).toDouble();
    if (_fontScale == normalized) return;
    _fontScale = normalized;
    notifyListeners();
    await _box.put('accessibility_font_scale', normalized);
  }

  Future<void> setBoldText(bool value) async {
    if (_boldText == value) return;
    _boldText = value;
    notifyListeners();
    await _box.put('accessibility_bold_text', value);
  }

  Future<void> setHighContrast(bool value) async {
    if (_highContrast == value) return;
    _highContrast = value;
    notifyListeners();
    await _box.put('accessibility_high_contrast', value);
  }

  Future<void> setDarkMode(bool value) async {
    if (_darkMode == value) return;
    _darkMode = value;
    notifyListeners();
    await _box.put('accessibility_dark_mode', value);
  }

  Future<void> setReduceMotion(bool value) async {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    notifyListeners();
    await _box.put('accessibility_reduce_motion', value);
  }

  Future<void> setSpeechEnabled(bool value) async {
    if (_speechEnabled == value) return;
    _speechEnabled = value;
    notifyListeners();
    await _box.put('accessibility_speech_enabled', value);
  }

  Future<void> setFontFamily(String value) async {
    final normalized = value == 'serif' ? 'serif' : 'system';
    if (_fontFamily == normalized) return;
    _fontFamily = normalized;
    notifyListeners();
    await _box.put('accessibility_font_family', normalized);
  }

  Future<void> reset() async {
    _fontScale = 1.0;
    _boldText = false;
    _highContrast = false;
    _darkMode = false;
    _reduceMotion = false;
    _speechEnabled = true;
    _fontFamily = 'system';
    notifyListeners();

    await Future.wait([
      _box.put('accessibility_font_scale', _fontScale),
      _box.put('accessibility_bold_text', _boldText),
      _box.put('accessibility_high_contrast', _highContrast),
      _box.put('accessibility_dark_mode', _darkMode),
      _box.put('accessibility_reduce_motion', _reduceMotion),
      _box.put('accessibility_speech_enabled', _speechEnabled),
      _box.put('accessibility_font_family', _fontFamily),
    ]);
  }

  /// Agenda gravações de sliders sem bloquear o gesto do usuário.
  void atualizarEscala(double value) {
    unawaited(setFontScale(value));
  }
}
