import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'Push recebido em background: ${message.notification?.title}',
    name: 'FCM',
  );
}

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
  static Future<void> inicializar({required String apiBaseUrl}) async {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    const androidSettings =
        AndroidInitializationSettings('@drawable/ifsp_logo');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_canal);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    final token = await messaging.getToken();
    if (token != null) {
      developer.log('Token FCM obtido.', name: 'FCM');
      await _enviarTokenParaBackend(token, apiBaseUrl);
    }

    messaging.onTokenRefresh.listen((novoToken) {
      _enviarTokenParaBackend(novoToken, apiBaseUrl);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _exibirNotificacaoLocal(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        'App aberto por push: ${message.notification?.title}',
        name: 'FCM',
      );
    });
  }

  static Future<bool> _notificacoesAtivas() async {
    try {
      if (!Hive.isBoxOpen('preferencias')) {
        await Hive.openBox('preferencias');
      }
      return Hive.box('preferencias').get(
        'notificacoes_ligadas',
        defaultValue: true,
      );
    } catch (e) {
      developer.log('Erro ao ler preferências de push: $e', name: 'FCM');
      return true;
    }
  }

  static Future<void> _exibirNotificacaoLocal(RemoteMessage message) async {
    if (!await _notificacoesAtivas()) return;

    final notification = message.notification;
    if (notification == null) return;

    await showNotification(
      notification.title ?? 'Notificação',
      notification.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> showNotification(
    String notificationTitle,
    String notificationBody, {
    String? payload,
  }) async {
    if (!await _notificacoesAtivas()) return;

    final idNotification =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _localNotifications.show(
      idNotification,
      notificationTitle,
      notificationBody,
      _notificationDetails,
      payload: payload,
    );
  }

  static void _onDidReceiveNotificationResponse(
    NotificationResponse details,
  ) {
    developer.log(
      'Selecionado: ${details.actionId} | ${details.payload}',
      name: 'FCM',
    );
  }

  static Future<void> _enviarTokenParaBackend(
    String token,
    String apiBaseUrl,
  ) async {
    try {
      await http.post(
        Uri.parse('$apiBaseUrl/mobile/notificacoes/registrar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );
    } catch (e) {
      developer.log('Erro ao registrar token FCM: $e', name: 'FCM');
    }
  }
}
