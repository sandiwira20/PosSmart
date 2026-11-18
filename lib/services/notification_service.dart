import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'firebase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background message: ${message.messageId}');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static bool _isInitialized = false;

  static StreamSubscription? _transactionSub;
  static StreamSubscription? _menuUpdateSub;
  static StreamSubscription? _menuAddedSub;
  static bool _initialMenuLoadComplete = false;

  static final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  /// Inisialisasi FCM & Local Notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Minta izin notifikasi (Wajib untuk Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM User permission status: ${settings.authorizationStatus}');

      // 2. Ambil FCM Device Token
      if (!kIsWeb) {
        try {
          final token = await _fcm.getToken();
          debugPrint('====================================');
          debugPrint('FCM Device Token: $token');
          debugPrint('====================================');
        } catch (e) {
          debugPrint('FCM getToken error: $e');
        }
      }

      // 3. Konfigurasi Local Notification
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Buat Notification Channel untuk Android (High Importance)
      const androidChannel = AndroidNotificationChannel(
        'possmart_high_channel',
        'Notifikasi PosSmart',
        description: 'Notifikasi Pembayaran dan Pembaruan Menu PosSmart',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // 4. Listen pesan FCM saat aplikasi di Foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.notification?.title}');
        if (message.notification != null) {
          showNotification(
            title: message.notification!.title ?? 'PosSmart',
            body: message.notification!.body ?? '',
          );
        }
      });

      // 5. Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 6. Jalankan Realtime Listener Database untuk Notifikasi Otomatis
      _startRealtimeTriggers();

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Memunculkan notifikasi pop-up (banner) dengan suara & getar
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'possmart_high_channel',
      'Notifikasi PosSmart',
      channelDescription: 'Notifikasi Pembayaran dan Pembaruan Menu PosSmart',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotifications.show(id, title, body, notificationDetails);
  }

  /// Realtime Listener Otomatis sesuai permintaan penugasan:
  /// 1. Pembayaran Lunas MiomiPay -> Notifikasi ke Kasir
  /// 2. Admin Tambah/Update Menu -> Notifikasi ke Kasir
  static void _startRealtimeTriggers() {
    // -------------------------------------------------------------------------
    // FITUR 1: Notifikasi Pembayaran Lunas ke Kasir
    // Ketika transaksi berubah menjadi PAID, notifikasi langsung muncul otomatis!
    // -------------------------------------------------------------------------
    _transactionSub = FirebaseService.transactionsRef.onChildChanged.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.value != null && snapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final status = (data['status'] ?? '').toString().toUpperCase();

        if (status == 'PAID') {
          final invoice = data['invoiceNumber'] ?? 'INV';
          final amountNum = (data['totalAmount'] is num)
              ? (data['totalAmount'] as num).toDouble()
              : 0.0;
          final amountText = _currencyFormat.format(amountNum);

          showNotification(
            title: 'Pembayaran Berhasil! 💰',
            body: 'Tagihan #$invoice sebesar $amountText telah Lunas via MiomiPay.',
          );
        }
      }
    });

    // -------------------------------------------------------------------------
    // FITUR 2: Notifikasi Update Menu dari Admin ke Kasir
    // Ketika Admin mengupdate harga atau nama menu
    // -------------------------------------------------------------------------
    _menuUpdateSub = FirebaseService.menusRef.onChildChanged.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.value != null && snapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final name = data['name'] ?? 'Menu';
        final priceNum = (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;
        final priceText = _currencyFormat.format(priceNum);

        showNotification(
          title: 'Menu Diperbarui oleh Admin 🍽️',
          body: '$name kini seharga $priceText.',
        );
      }
    });

    // Tandai load awal selesai setelah 3 detik agar tidak memicu notifikasi untuk menu lama
    Future.delayed(const Duration(seconds: 4), () {
      _initialMenuLoadComplete = true;

      // Listen untuk menu baru yang baru saja di-create Admin
      _menuAddedSub = FirebaseService.menusRef.onChildAdded.listen((event) {
        if (!_initialMenuLoadComplete) return;

        final snapshot = event.snapshot;
        if (snapshot.value != null && snapshot.value is Map) {
          final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
          final name = data['name'] ?? 'Menu Baru';

          showNotification(
            title: 'Menu Baru Ditambahkan! ✨',
            body: '$name telah tersedia di daftar kasir.',
          );
        }
      });
    });
  }

  static void dispose() {
    _transactionSub?.cancel();
    _menuUpdateSub?.cancel();
    _menuAddedSub?.cancel();
  }
}
