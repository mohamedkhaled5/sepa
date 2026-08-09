// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:url_launcher/url_launcher.dart';

// class NotificationService {
//   static final FirebaseMessaging _firebaseMessaging =
//       FirebaseMessaging.instance;
//   static final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> init() async {
//     // 1. طلب إذن الإشعارات من المستخدم
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       print('تم منح إذن الإشعارات');
//     }

//     // 2. إعداد الإشعارات المحلية
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     const InitializationSettings initSettings = InitializationSettings(
//       android: androidSettings,
//     );

//     await _localNotifications.initialize(
//       settings: initSettings,
//       onDidReceiveNotificationResponse: (response) {
//         if (response.payload != null) {
//           _openLink(response.payload!);
//         }
//       },
//     );

//     // 3. الاستماع للإشعارات والتطبيق مفتوح (Foreground)
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       _showLocalNotification(message);
//     });

//     // 4. الاستماع عند الضغط على الإشعار والتطبيق في الخلفية (Background)
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       _handleNotificationClick(message);
//     });

//     // 5. الاستماع عند فتح التطبيق من إشعار وكان التطبيق مغلقاً تماماً (Terminated)
//     RemoteMessage? initialMessage = await _firebaseMessaging
//         .getInitialMessage();
//     if (initialMessage != null) {
//       _handleNotificationClick(initialMessage);
//     }
//   }

//   static void _handleNotificationClick(RemoteMessage message) {
//     if (message.data.containsKey('link')) {
//       String url = message.data['link'];
//       _openLink(url);
//     }
//   }

//   static Future<void> _openLink(String urlString) async {
//     final Uri url = Uri.parse(urlString);
//     if (await canLaunchUrl(url)) {
//       await launchUrl(url, mode: LaunchMode.externalApplication);
//     }
//   }

//   static void _showLocalNotification(RemoteMessage message) async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//           'updates_channel',
//           'تحديثات التطبيق',
//           importance: Importance.max,
//           priority: Priority.high,
//         );
//     const NotificationDetails details = NotificationDetails(
//       android: androidDetails,
//     );

//     await _localNotifications.show(
//       id: message.hashCode,
//       title: message.notification?.title,
//       body: message.notification?.body,
//       notificationDetails: details,
//       payload: message.data['link'],
//     );
//   }
// }
