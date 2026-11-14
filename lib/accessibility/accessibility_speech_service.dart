import 'package:flutter_tts/flutter_tts.dart';

/// Leitor de texto em voz alta usado pelas telas de conteúdo.
class AccessibilitySpeechService {
  AccessibilitySpeechService._() {
    _tts.setLanguage('pt-BR');
    _tts.setSpeechRate(0.48);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => onFinished?.call());
    _tts.setCancelHandler(() => onFinished?.call());
    _tts.setErrorHandler((_) => onFinished?.call());
  }

  static final AccessibilitySpeechService instance =
      AccessibilitySpeechService._();

  final FlutterTts _tts = FlutterTts();

  void Function()? onFinished;

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _tts.stop();
    await _tts.setLanguage('pt-BR');
    await _tts.speak(trimmed);
  }

  Future<void> stop() async {
    await _tts.stop();
    onFinished?.call();
  }
}
