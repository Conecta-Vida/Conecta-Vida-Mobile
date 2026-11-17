import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'supabase_service.dart';

/// Notificações locais do aparelho. Os alertas de saúde chegam em tempo real
/// pelo Supabase (Realtime) enquanto o app está aberto e viram notificação aqui.
class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _canal = AndroidNotificationChannel(
    'ifsp_channel',
    'IFSP Notificações',
    description: 'Canal de notificações locais do Conecta Vida',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'ifsp_channel',
      'IFSP Notificações',
      channelDescription: 'Canal de notificações locais do Conecta Vida',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ifsp_logo',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('0', 'Ok'),
        AndroidNotificationAction('1', 'Cancel'),
      ],
    ),
  );

  /// Inicializar nas plataformas nativas antes do runApp.
  static Future<void> inicializar() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ifsp_logo',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_canal);
  }

  static Future<bool> _notificacoesAtivas() async {
    try {
      if (!Hive.isBoxOpen('preferencias')) {
        await Hive.openBox('preferencias');
      }
      return Hive.box(
        'preferencias',
      ).get('notificacoes_ligadas', defaultValue: true);
    } catch (e) {
      developer.log('Erro ao ler preferências de push: $e', name: 'FCM');
      return true;
    }
  }

  static Future<void> showNotification(
    String notificationTitle,
    String notificationBody, {
    String? payload,
  }) async {
    if (!await _notificacoesAtivas()) return;

    final idNotification = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    await _localNotifications.show(
      idNotification,
      notificationTitle,
      notificationBody,
      _notificationDetails,
      payload: payload,
    );
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse details) {
    developer.log(
      'Selecionado: ${details.actionId} | ${details.payload}',
      name: 'FCM',
    );
  }
}
