import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global/appCor.dart';

/// Abre pesquisas no Google Maps usando a URL universal
/// (https://www.google.com/maps/search/?api=1&query=...).
///
/// No Android e no iOS o link abre o aplicativo Google Maps quando ele está
/// instalado; caso contrário (e no Flutter Web) abre o navegador.
class MapsLauncher {
  static const String consultaInstituicoesProximas =
      'instituições de saúde perto de mim';

  static Uri urlDePesquisa(String consulta) => Uri.https(
    'www.google.com',
    '/maps/search/',
    {'api': '1', 'query': consulta},
  );

  /// Pesquisa hospitais, clínicas e unidades de saúde próximos ao usuário.
  /// Sem um local na consulta, o Google Maps usa a localização atual.
  static Future<void> abrirInstituicoesProximas(BuildContext context) =>
      abrirPesquisa(context, consultaInstituicoesProximas);

  static Future<void> abrirPesquisa(
    BuildContext context,
    String consulta,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final aberto = await _abrir(urlDePesquisa(consulta));
    if (aberto) return;

    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          'Não foi possível abrir o Google Maps. Verifique se há um '
          'navegador ou o aplicativo de mapas instalado.',
        ),
        backgroundColor: AppCor.error,
      ),
    );
  }

  static Future<bool> _abrir(Uri url) async {
    // 1ª tentativa: aplicativo externo (Google Maps ou navegador padrão).
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {
      // Segue para a alternativa abaixo.
    }

    // Alternativa: deixa a plataforma escolher (aba do navegador / webview).
    try {
      return await launchUrl(url);
    } catch (_) {
      return false;
    }
  }
}
